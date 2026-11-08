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
@onready var _result: Panel = $Result
@onready var _result_title: Label = $Result/Title
@onready var _result_body: Label = $Result/Body


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
	_boss_name.text = str(_boss["threat"]).to_upper()
	_intent_icon.draw.connect(_draw_intent_icon)
	_hand_fan.card_clicked.connect(_on_card_clicked)
	_end_turn.pressed.connect(_on_end_turn_pressed)
	_arena.hit.connect(_on_hit)
	_arena.pattern_finished.connect(_on_pattern_finished)
	_arena.note.connect(_on_arena_note)
	_arena.defense_used.connect(_on_defense_used)
	$Result/Retry.pressed.connect(func() -> void: SceneManager.load_scene(scene_file_path))
	$Result/Leave.pressed.connect(_on_leave_pressed)
	_arena.hide()
	_speech.hide()
	_result.hide()
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


func _on_card_clicked(index: int) -> void:
	var id := _hand[index]
	var card: Dictionary = _cards[id]
	var cost := int(card["cost"])
	if _over or cost > _energy:
		return
	_energy -= cost
	var effects: Dictionary = card.get("effects", {})
	_discard.append(id)
	_hand.remove_at(index)
	_hand_fan.remove_card(index)
	_boss_hp = maxi(_boss_hp - int(effects.get("damage", 0)), 0)
	_block += int(effects.get("block", 0))
	if effects.has("damage"):
		_flash(_enemy)
		_float_text("-%d" % int(effects["damage"]), _enemy.position + Vector2(-6, -44), Color.WHITE)
		_shake(2.0)
	for i in int(effects.get("draw", 0)):
		var drawn := _draw_one()
		if not drawn.is_empty():
			_hand_fan.add_card(drawn, _cards[drawn])
	_hand_fan.energy = _energy
	_refresh()
	if _boss_hp <= 0:
		_finish(true)


func _on_end_turn_pressed() -> void:
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
	_turn_label.text = "ENEMY TURN - dodge with the arrow keys or WASD"
	_arena.defenses = _equipped
	_arena.start(pattern)
	_type(_teach_body, str(pattern["teach"])) # keeps typing while the pattern runs


## What the player should take from the enemy turn, from what actually happened in it.
func _lessons(pattern: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for defense: Dictionary in _boss["defenses"]:
		var id := str(defense["id"])
		if _used.has(id):
			lines.append(str(defense["works"]))
		elif id == str(pattern["counter"]) and not _equipped.has(id):
			lines.append(str(defense["missing"]))
	return lines


func _on_arena_note(text: String, good: bool) -> void:
	var color := Color(0.654902, 0.9411765, 0.4392157, 1) if good else Color(1, 0.6, 0.45, 1)
	_float_text(text, Vector2(320.0 - text.length() * 2.6, _arena.position.y + _arena.size.y + 22.0), color, 1.4) # under the box (it is narrower than the text)


func _on_defense_used(id: String) -> void:
	_used[id] = int(_used.get(id, 0)) + 1
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
	_flash(_hero)
	_shake(3.0 if absorbed == damage else 4.0 + damage * 0.25)
	if absorbed > 0:
		_float_text("BLOCKED %d" % absorbed, _hero.position + Vector2(-26, -50), Color(0.4509804, 0.9372549, 0.96862745, 1))
	if damage - absorbed > 0:
		_float_text("-%d" % (damage - absorbed), _hero.position + Vector2(-8, -38), Color.WHITE)
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
	_intent_name.text = "NEXT: %s" % str(pattern["name"])
	_teach_title.text = "THREAT: %s" % str(_boss["threat"]).to_upper()
	_teach_body.text = "Next attack: %s. It is shown here before it comes, so you can plan your cards." % str(pattern["name"])
	_teach_defense.text = ""
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


## A number or word that bounces up from a spot and fades.
func _float_text(text: String, at: Vector2, color: Color, life: float = 0.6) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.z_index = 150
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.101960786, 0.10980392, 0.17254902, 1))
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", at.y - 18.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(life)
	tween.chain().tween_callback(label.queue_free)


## A short shake of the whole screen.
func _shake(strength: float) -> void:
	var tween := create_tween()
	for i in 4:
		tween.tween_property(self, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength)).round(), 0.04)
	tween.tween_property(self, "position", Vector2.ZERO, 0.04)


# --- the end of the fight ---

func _finish(won: bool) -> void:
	_over = true
	_won = won
	_hand_fan.enabled = false
	_end_turn.disabled = true
	$Result/Leave.text = "LEAVE" if won else "CHANGE BUILD"
	_result_title.text = "THREAT CONTAINED" if won else "SYSTEM COMPROMISED"
	_result_body.text = "%s is stopped. Nice work." % str(_boss["threat"]) if won else "%s got through. Check your upgrades and your deck, then try again." % str(_boss["threat"])
	_result.show()


## After a win, back to the day select. After a loss, back to Hardening to change the build: its NEXT PHASE
## leads here again.
func _on_leave_pressed() -> void:
	if _won:
		SceneManager.load_stage_select()
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


# --- for the Debug panel (=) ---

func debug_actions() -> Array:
	return [
		["Win the fight >", func() -> void: _boss_hp = 0; _refresh(); _finish(true)],
		["Heal to full >", func() -> void: _player_hp = _player_max; _refresh()],
		["Give 3 energy >", func() -> void: _energy += 3; _hand_fan.energy = _energy; _refresh()],
	]
