extends Control
## Mockup of the Response phase: a card turn for the player, then a bullet-hell turn in which
## the threat attacks with one of its patterns. Each pattern is explained while it runs, so the
## player learns how that threat really behaves. Data: data/response_day1.json and data/cards.json.
## The deck and the upgrades are the ones the player built in Hardening (HardeningState).

const DATA_PATH := "res://AI generated/data/response_day1.json"
const CARDS_PATH := "res://data/cards.json"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const TYPE_SPEED := 45.0 # letters per second for typed text

var _cards: Dictionary = {}
var _boss: Dictionary = {}
var _patterns: Array = []
var _deck: Array[String] = []
var _draw_pile: Array[String] = []
var _discard: Array[String] = []
var _hand: Array[String] = []
var _player_hp := 0
var _player_max := 0
var _boss_hp := 0
var _boss_max := 0
var _block := 0
var _energy := 0
var _turn := 0 # counts the player's turns, picks the pattern of the enemy turn
var _over := false
var _hits := 0 # what happened during the last enemy turn
var _blocked := 0
var _through := 0
var _skip := false # a click shows the text at once and skips the pauses
var _typing := {} # label -> id of the text being typed into it, so a new text cancels the old one
var _equipped: Array[String] = [] # the upgrades equipped in Hardening
var _used := {} # upgrade id -> how many times it worked during the last enemy turn
var _won := false
var _upgrade_icons := {} # upgrade id -> its icon in the corner of the screen
var _worked: Array[String] = [] # ids of the upgrades that did their job at least once
var _fx: ResponseFx # the effects of the fight: bolts, sparks, the shield, the animations of the two fighters
var _busy := false # a played card's effect is still flying: no other card, no end of turn until it lands
## Ids of the attack patterns whose damage got through (not fully blocked or dodged). Recovery
## repairs one thing per pattern here (data/recovery/dayN_recovery.json "attacks").
var hit_patterns: Array[String] = []

@onready var _hand_fan: HandFan = $Hand
@onready var _arena: BulletArena = $Arena
@onready var _enemy: AnimatedSprite2D = $Enemy
@onready var _hero: AnimatedSprite2D = $Hero
@onready var _end_turn: Button = $EndTurn
@onready var _turn_label: Label = $TurnLabel
@onready var _teach_title: Label = $Teach/Title
@onready var _teach_body: Label = $Teach/Body
@onready var _teach_defense: Label = $Teach/Defense
@onready var _boss_name: Label = $BossName
@onready var _boss_bar: ProgressBar = $BossBar
@onready var _boss_text: Label = $BossHp
@onready var _intent_icon: Control = $Intent/Icon
@onready var _intent_name: Label = $Intent/Name
@onready var _player_bar: ProgressBar = $PlayerBar
@onready var _player_text: Label = $PlayerHp
@onready var _block_label: Label = $BlockLabel
@onready var _energy_label: Label = $EnergyLabel
@onready var _piles_label: Label = $PilesLabel
@onready var _speech: Panel = $Speech
@onready var _speech_text: Label = $Speech/Text
@onready var _finish_screen: FinishScreen = $FinishScreen


func _ready() -> void:
	_boss = _load_json(DATA_PATH)
	_cards = _load_json(CARDS_PATH).get("cards", {})
	_patterns = _boss["patterns"]
	var build := HardeningState.new()
	for id: String in build.deck_list():
		_deck.append(id)
	for id: String in build.equipped_list():
		_equipped.append(id)
	_player_max = int(_boss["player_hp"])
	_player_hp = _player_max
	_boss_max = int(_boss["boss_hp"])
	_boss_hp = _boss_max
	_enemy.sprite_frames = load(str(_boss["enemy_frames"]))
	_enemy.play(&"idle")
	_hero.play(&"idle")
	_fx = ResponseFx.new()
	_fx.z_index = 120 # above the fighters and the hand, below the floating numbers and the results
	_fx.reduced = ScreenEffects.reduce_effects
	add_child(_fx)
	_fx.prepare(_hero)
	_fx.prepare(_enemy)
	_boss_name.text = str(_boss["threat"]).to_upper()
	_intent_icon.draw.connect(_draw_intent_icon)
	_hand_fan.card_clicked.connect(_on_card_clicked)
	_end_turn.pressed.connect(_on_end_turn_pressed)
	_arena.hit.connect(_on_hit)
	_arena.pattern_finished.connect(_on_pattern_finished)
	_arena.note.connect(_on_arena_note)
	_arena.defense_used.connect(_on_defense_used)
	_finish_screen.extra_requested.connect(func() -> void: SceneManager.load_scene(scene_file_path))
	_finish_screen.continue_requested.connect(_on_leave_pressed)
	_arena.hide()
	_speech.hide()
	_draw_pile = _deck.duplicate()
	_draw_pile.shuffle()
	_build_upgrade_icons(build)
	_start_player_turn()
	await SceneManager.wait_for_transition()
	Tutorial.maybe_show(self, "response")


## The equipped upgrades as small icons in the corner, so the player sees what they brought. An icon
## lights up when its upgrade does its job. Hover one to read it.
func _build_upgrade_icons(build: HardeningState) -> void:
	var row := HBoxContainer.new()
	row.name = "UpgradeIcons"
	row.position = Vector2(6, 58)
	add_child(row)
	for id in _equipped:
		var info: Dictionary = build.upgrades.get(id, {})
		var icon := TextureRect.new()
		icon.texture = UpgradeTile.icon(id)
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = "%s\n%s" % [info.get("name", id), info.get("text", "")]
		row.add_child(icon)
		_upgrade_icons[id] = icon


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Response: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


# --- the player's turn ---

func _start_player_turn() -> void:
	_block = 0 # Block only lasts through the enemy's turn
	_energy = int(_boss["energy"])
	for i in int(_boss["hand_size"]):
		_draw_one()
	_hand_fan.set_hand(_hand, _cards)
	_hand_fan.energy = _energy
	_hand_fan.enabled = true
	_end_turn.disabled = false
	_turn_label.text = "YOUR TURN - play cards, then end the turn"
	_show_next_pattern()
	_refresh()


## Takes the top card of the draw pile (the discard pile is shuffled back in when it runs out).
## Returns "" when there is no card left anywhere.
func _draw_one() -> String:
	if _draw_pile.is_empty():
		_draw_pile = _discard.duplicate()
		_discard.clear()
		_draw_pile.shuffle()
	if _draw_pile.is_empty():
		return ""
	var id: String = _draw_pile.pop_back()
	_hand.append(id)
	return id


## A played card: its effect flies from the card to its target and does its job when it lands.
## Damage is a red bolt to the enemy, Block a cyan bolt to the player (the shield then stays around them),
## Draw gold sparks that rise from the card.
func _on_card_clicked(index: int) -> void:
	var id := _hand[index]
	var card: Dictionary = _cards[id]
	var cost := int(card["cost"])
	if _over or _busy or cost > _energy:
		return
	_busy = true
	_energy -= cost
	var effects: Dictionary = card.get("effects", {})
	var from := _hand_fan.card_center(index)
	_discard.append(id)
	_hand.remove_at(index)
	_hand_fan.remove_card(index)
	var damage := int(effects.get("damage", 0))
	var block := int(effects.get("block", 0))
	var draw := int(effects.get("draw", 0))
	var wait := 0.1
	if damage > 0:
		_fx.attack(_hero, _enemy.global_position, ResponseFx.RED, 10.0)
		wait = maxf(wait, _fx.bolt(from, _enemy.global_position + Vector2(0, -4), ResponseFx.RED, damage / 20.0, func() -> void: _apply_damage(damage)))
	if block > 0:
		if damage == 0:
			_fx.cast(_hero, ResponseFx.CYAN)
		wait = maxf(wait, _fx.bolt(from, _hero.global_position, ResponseFx.CYAN, block / 10.0, func() -> void: _apply_block(block), 4.0))
	for i in draw:
		var drawn := _draw_one()
		if not drawn.is_empty():
			_hand_fan.add_card(drawn, _cards[drawn])
	if draw > 0:
		if damage == 0 and block == 0:
			_fx.cast(_hero, ResponseFx.GOLD)
		_fx.rise(from, ResponseFx.GOLD, 8 + draw * 3)
		_fx.ring(from, ResponseFx.GOLD, 4.0, 22.0)
		_float_text("DRAW %d" % draw, from + Vector2(0, -20), ResponseFx.GOLD, 0.6, 6, true)
	_hand_fan.energy = _energy
	_refresh()
	await get_tree().create_timer(wait).timeout
	_busy = false


## The red bolt landed.
func _apply_damage(amount: int) -> void:
	_boss_hp = maxi(_boss_hp - amount, 0)
	_fx.slash(_enemy.global_position, ResponseFx.RED)
	_fx.hurt(_enemy, Vector2.RIGHT)
	_float_text("-%d" % amount, _enemy.position + Vector2(0, -44), Color.WHITE, 0.6, 12, true)
	_shake(2.0)
	_refresh()
	if _boss_hp <= 0:
		_finish(true)


## The cyan bolt landed: the shield goes up around the player (_refresh shows it).
func _apply_block(amount: int) -> void:
	_block += amount
	_fx.pulse_aura()
	_float_text("+%d BLOCK" % amount, _hero.position + Vector2(0, -44), ResponseFx.CYAN, 0.6, 6, true)
	_refresh()


func _on_end_turn_pressed() -> void:
	if _busy:
		return
	_discard.append_array(_hand)
	_hand.clear()
	_hand_fan.set_hand(_hand, _cards)
	_hand_fan.enabled = false
	_end_turn.disabled = true
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	_hits = 0
	_blocked = 0
	_through = 0
	_used.clear()
	_skip = false
	_turn_label.text = "ENEMY TURN"
	_teach_title.text = str(pattern["name"]).to_upper()
	_teach_body.text = ""
	_teach_defense.text = ""
	_refresh()
	await _say(str(pattern["say"]))
	if _over:
		return
	await _fx.attack(_enemy, _hero.global_position, ResponseFx.RED, 16.0).finished # the threat strikes, then the bullets come
	if _over:
		return
	if _harder(pattern):
		await _announce_harder(pattern)
		if _over:
			return
	_turn_label.text = "ENEMY TURN - dodge with the arrow keys or WASD"
	_arena.defenses = _equipped
	_arena.start(pattern)
	_type(_teach_body, str(pattern["teach"])) # keeps typing while the pattern runs


## True when the pattern is played in its harder version: the upgrade that counters it is not equipped.
func _harder(pattern: Dictionary) -> bool:
	return not _equipped.has(str(pattern["counter"]))


## The upgrade that counters a pattern: {id, name, works, harder} from the data.
func _counter_of(pattern: Dictionary) -> Dictionary:
	for defense: Dictionary in _boss["defenses"]:
		if str(defense["id"]) == str(pattern["counter"]):
			return defense
	return {}


## Before a harder version starts the player is told that it is harder and why, so the missing upgrade is
## not something to guess: the title says it, the line under it names what is different.
func _announce_harder(pattern: Dictionary) -> void:
	_teach_title.text = "%s - HARDER VERSION" % str(pattern["name"]).to_upper()
	_teach_defense.text = str(_counter_of(pattern).get("harder", ""))
	_fx.ring(_enemy.global_position, ResponseFx.RED, 10.0, 60.0, 0.5)
	_fx.burst(_enemy.global_position, ResponseFx.RED, 18, 110.0, 0.5)
	_float_text("HARDER", _enemy.position + Vector2(0, -52), ResponseFx.RED, 1.0, 6, true)
	_shake(3.0)
	await get_tree().create_timer(1.4).timeout # time to read why


## What the player should take from the enemy turn, from what actually happened in it.
func _lessons(pattern: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for defense: Dictionary in _boss["defenses"]:
		var id := str(defense["id"])
		if _used.has(id):
			lines.append(str(defense["works"]))
	return lines


func _on_arena_note(text: String, good: bool) -> void:
	var color := Color(0.654902, 0.9411765, 0.4392157, 1) if good else Color(1, 0.6, 0.45, 1)
	_float_text(text, Vector2(320.0, _arena.position.y + _arena.size.y + 22.0), color, 1.4, 6, true) # under the box (it is narrower than the text)


func _on_defense_used(id: String) -> void:
	_used[id] = int(_used.get(id, 0)) + 1
	if not _worked.has(id):
		_worked.append(id)
	if _upgrade_icons.has(id):
		_flash(_upgrade_icons[id])


# --- the enemy's turn ---

func _on_hit(damage: int) -> void:
	var absorbed := mini(_block, damage)
	_block -= absorbed
	_hits += 1
	_blocked += absorbed
	_through += damage - absorbed
	_player_hp = maxi(_player_hp - (damage - absorbed), 0)
	if damage - absorbed > 0:
		var pattern_id := str(_patterns[_turn % _patterns.size()].get("id", ""))
		if not pattern_id.is_empty() and not hit_patterns.has(pattern_id):
			hit_patterns.append(pattern_id)
	if damage - absorbed > 0:
		_fx.hurt(_hero, Vector2.LEFT)
	if absorbed > 0:
		_fx.pulse_aura()
	_shake(3.0 if absorbed == damage else 4.0 + damage * 0.25)
	if absorbed > 0:
		_float_text("BLOCKED %d" % absorbed, _hero.position + Vector2(0, -50), ResponseFx.CYAN, 0.6, 6, true)
	if damage - absorbed > 0:
		_float_text("-%d" % (damage - absorbed), _hero.position + Vector2(0, -38), Color.WHITE, 0.6, 12, true)
	_refresh()
	if _player_hp <= 0:
		_arena.stop()
		_finish(false)


func _on_pattern_finished() -> void:
	_arena.stop()
	if _over:
		return
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	_skip = false
	_turn_label.text = "ENEMY TURN OVER"
	_teach_title.text = "RESULT: %s" % str(pattern["name"]).to_upper()
	_teach_defense.text = ""
	var line := "No hits. Nice dodging!"
	if _hits > 0:
		line = "You were hit %d time%s. %d damage got through" % [_hits, "" if _hits == 1 else "s", _through]
		line += (", Block stopped %d." % _blocked) if _blocked > 0 else "."
	await _type(_teach_body, line)
	await _wait(0.8)
	for lesson in _lessons(pattern):
		await _type(_teach_defense, lesson)
		await _wait(2.6)
	if _over:
		return
	_turn += 1
	_start_player_turn()


func _show_next_pattern() -> void:
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	var harder := _harder(pattern)
	_intent_name.text = "NEXT: %s%s" % [str(pattern["name"]), " (HARDER)" if harder else ""]
	_intent_name.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45) if harder else Color(0.95686275, 0.95686275, 0.95686275))
	_teach_title.text = "THREAT: %s" % str(_boss["threat"]).to_upper()
	_teach_body.text = "Next attack: %s. It is shown here before it comes, so you can plan your cards." % str(pattern["name"])
	_teach_defense.text = str(_counter_of(pattern).get("harder", "")) if harder else ""
	_intent_icon.queue_redraw()


func _draw_intent_icon() -> void:
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	BulletArena.draw_bullet(_intent_icon, load(str(pattern["sprite"])), Vector2(8, 7), 0.0)


# --- text and feedback ---

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip = true


## The threat says a line before it attacks: a speech bubble with typed text.
func _say(text: String) -> void:
	_speech.show()
	await _type(_speech_text, text)
	await _wait(0.9)
	_speech.hide()


## Types a text into a label one letter at a time. A click shows the rest at once.
func _type(label: Label, text: String) -> void:
	var id := Time.get_ticks_usec()
	_typing[label] = id
	label.text = text
	label.visible_characters = 0
	var shown := 0.0
	while shown < text.length() and not _skip and _typing[label] == id and is_inside_tree():
		await get_tree().process_frame
		shown += TYPE_SPEED * get_process_delta_time()
		if _typing[label] == id:
			label.visible_characters = int(shown)
	if _typing[label] == id:
		label.visible_characters = -1


## Waits, or less when the player clicks.
func _wait(seconds: float) -> void:
	var left := seconds
	while left > 0.0 and not _skip and is_inside_tree():
		await get_tree().process_frame
		left -= get_process_delta_time()


## A number or word that bounces up from a spot and fades. size must be 6 or 12 (whole multiples of the
## font's 6px, or the text blurs). centered puts the middle of the text at `at`.
func _float_text(text: String, at: Vector2, color: Color, life: float = 0.6, size: int = 6, centered: bool = false) -> void:
	var label := Label.new()
	label.text = text
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label.position = (at - Vector2(width / 2.0 if centered else 0.0, 0.0)).round()
	label.z_index = 150
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.101960786, 0.10980392, 0.17254902, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 18.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(life)
	tween.chain().tween_callback(label.queue_free)


## A short shake of the whole screen (Settings > Screen Shake turns it off).
func _shake(strength: float) -> void:
	if not ScreenEffects.shake_allowed():
		return
	var tween := create_tween()
	for i in 4:
		tween.tween_property(self, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round(), 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.04)


# --- the end of the fight ---

func _finish(won: bool) -> void:
	if _over:
		return
	_over = true
	_won = won
	_hand_fan.enabled = false
	_end_turn.disabled = true
	await _play_ending()
	_finish_screen.show_results(_finish_summary())


## What happens before the results: the threat falls apart and the player celebrates, or the player goes down.
func _play_ending() -> void:
	if _won:
		_shake(6.0)
		await _fx.defeat(_enemy).finished
		_float_text("VICTORY!", _hero.position + Vector2(0, -52), ResponseFx.GOLD, 1.2, 12, true)
		await _fx.victory(_hero).finished
	else:
		_fx.set_aura(false, _hero.global_position)
		await _fx.knock_out(_hero).finished
	await get_tree().create_timer(0.5).timeout


## The figures of the FinishScreen. Winning pays one reward for defeating the threat; the other figures
## only show how the fight went. A lost fight shows the same figures and pays nothing: its screen offers
## TRY AGAIN and CHANGE BUILD.
func _finish_summary() -> Dictionary:
	var finish: Dictionary = _boss["finish"]
	var comments: Dictionary = finish["comments"]
	var rows: Array[Dictionary] = [
		{"count": _player_max - _player_hp}, # the damage taken
		{"count": _worked.size()},
		{"count": 1 if _won else 0},
	]
	if not _won:
		return {
			"rows": rows,
			"comment": str(comments["lost"]).replace("{threat}", str(_boss["threat"])),
			"title": str(finish["title_lost"]),
			"practice": true,
			"gained_text": str(finish["unpaid_text"]),
			"button": "CHANGE BUILD",
			"extra_button": "TRY AGAIN",
		}
	rows[2]["points"] = int(finish["reward"])
	var comment: String = str(comments["flawless"] if hit_patterns.is_empty() else comments["won"])
	return {
		"rows": rows,
		"comment": comment.replace("{threat}", str(_boss["threat"])).replace("{names}", ", ".join(_hit_names())),
	}


## The names of the attacks whose damage got through: it is what Recovery will have to repair.
func _hit_names() -> Array[String]:
	var names: Array[String] = []
	for pattern: Dictionary in _patterns:
		if hit_patterns.has(str(pattern.get("id", ""))):
			names.append(str(pattern["name"]))
	return names


## After a win (the FinishScreen already paid the points and saved Response as complete): the attacks
## that got through become the Recovery repairs (GameState.begin_recovery). After a loss, back to
## Hardening to change the build: its NEXT PHASE leads here again.
func _on_leave_pressed() -> void:
	if _won:
		var recovery: Dictionary = GameState.phase_info("recovery")
		if recovery.is_empty():
			SceneManager.load_stage_select()
			return
		var data := RecoveryData.load_data(str(recovery.get("data", RecoveryData.DEFAULT_PATH)))
		var outcome: Dictionary = data.get("response_outcome", data.get("sample_outcome", {})).duplicate(true)
		outcome["contained"] = true
		GameState.begin_recovery(RecoveryData.components_for_attacks(data, hit_patterns), outcome)
		GameState.set_phase("recovery")
		SceneManager.open_current_phase()
		return
	GameState.set_phase("hardening")
	SceneManager.load_scene(str(GameState.phase_info()["scene"]))


func _flash(sprite: CanvasItem) -> void:
	sprite.modulate = Color(2.0, 1.4, 1.4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.25)


func _refresh() -> void:
	_boss_bar.max_value = _boss_max
	_boss_bar.value = _boss_hp
	_boss_text.text = "%d / %d" % [_boss_hp, _boss_max]
	_player_bar.max_value = _player_max
	_player_bar.value = _player_hp
	_player_text.text = "%d / %d" % [_player_hp, _player_max]
	_block_label.text = "BLOCK %d" % _block
	_energy_label.text = "ENERGY %d / %d" % [_energy, int(_boss["energy"])]
	_piles_label.text = "DRAW %d  DISCARD %d" % [_draw_pile.size(), _discard.size()]
	if not _over:
		_fx.set_aura(_block > 0, _hero.global_position) # the shield is up while there is Block


# --- for the Debug panel (=) ---

func debug_actions() -> Array:
	return [
		["Win the fight >", func() -> void: _boss_hp = 0; _refresh(); _finish(true)],
		["Heal to full >", func() -> void: _player_hp = _player_max; _refresh()],
		["Give 3 energy >", func() -> void: _energy += 3; _hand_fan.energy = _energy; _refresh()],
	]
