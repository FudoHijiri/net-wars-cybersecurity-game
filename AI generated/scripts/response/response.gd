extends Control
## Mockup of the Response phase: a card turn for the player, then a bullet-hell turn in which
## the threat attacks with one of its patterns. Each pattern is explained while it runs, so the
## player learns how that threat really behaves. Data: data/response_day1.json and data/cards.json.
## The deck and the upgrades are the ones the player built in Hardening (HardeningState).
## What is on the screen: the two fighters with their health bar under each (HpBar: Block is temporary HP,
## buffs and debuffs sit under the bar), the next attack above the threat (point at it to read about it),
## the energy orbs and the two piles at the bottom-left. The Teach strip at the top only appears when there is
## something to read, and everything that has to be read comes BEFORE the bullets: while the player is
## dodging, it shows only the name of the attack.

## The data of the fight is named by the day in days.json ("data" of the response phase); Day 1's is the default.
const DEFAULT_DATA_PATH := "res://AI generated/data/response_day1.json"
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
var _dodge := 0 # hits of the enemy turn that do nothing; like Block, gone when the enemy turn is over
var _dodged := 0 # hits dodged during the last enemy turn
var _exposed := 0 # the threat takes this much more damage from every card played now, until the end of the turn
var _charge := 0 # Energy you get at the start of your next turn (cards that Charge)
var _reflect := 0 # damage the threat takes each time a hit lands on you during the enemy turn (cards that Reflect); gone when the turn starts, like Block
var _cap := 0 # the most damage one hit of the enemy turn does (cards that Cap); 0 when there is none. Gone when the turn starts, like Block
var _leak := 0 # HP you lose at the start of your next turn; Block does not stop it (hits of the leak pattern add to it)
var _incoming_leak := 0 # the Leak of the hit that is being resolved: the arena says it just before the hit
var _energy := 0
var _turn := 0 # counts the player's turns, picks the pattern of the enemy turn
var _over := false
var _hits := 0 # what happened during the last enemy turn
var _blocked := 0
var _through := 0
var _skip := false # a click shows the text at once and skips the pauses
var _typing := {} # label -> id of the text being typed into it, so a new text cancels the old one
var _equipped: Array[String] = [] # the upgrades equipped in Hardening
var _passive := {} # what the equipped upgrades always give: key -> total (max_hp, block_per_turn, heal_per_turn, dodge_per_turn, attack_bonus, first_draw, first_energy)
var _used := {} # upgrade id -> how many times it worked during the last enemy turn
var _won := false
var _doom: Dictionary = {} # the day's "doom" while its upgrade is not equipped: its attacks cannot be stopped (see _doom_version)
var _doomed := false # the fight was lost to it
var _doom_label: Label
var _upgrade_icons := {} # upgrade id -> its icon in the corner of the screen
var _worked: Array[String] = [] # ids of the upgrades that did their job at least once
var _fx: ResponseFx # the effects of the fight: bolts, sparks, the shield, the animations of the two fighters
var _taught: Array[String] = [] # ids of the attacks whose teaching text was already shown: it is only shown the first time
var _busy := false # a played card's effect is still flying: no other card, no end of turn until it lands
## Ids of the attack patterns whose damage got through (not fully blocked or dodged). Recovery
## repairs one thing per pattern here (data/recovery/dayN_recovery.json "attacks").
var hit_patterns: Array[String] = []

@onready var _hand_fan: HandFan = $Hand
@onready var _arena: BulletArena = $Arena
@onready var _enemy: AnimatedSprite2D = $Enemy
@onready var _hero: AnimatedSprite2D = $Hero
@onready var _end_turn: Button = $EndTurn
@onready var _teach: Panel = $Teach
@onready var _teach_title: Label = $Teach/Title
@onready var _teach_body: Label = $Teach/Body
@onready var _teach_defense: Label = $Teach/Defense
@onready var _boss_name: Label = $BossName
@onready var _boss_bar: HpBar = $BossBar
@onready var _intent: Control = $Intent
@onready var _intent_icon: Control = $Intent/Icon
@onready var _intent_name: Label = $Intent/Name
@onready var _player_bar: HpBar = $PlayerBar
@onready var _energy_orbs: Control = $Energy
@onready var _draw_icon: Control = $DrawPile
@onready var _discard_icon: Control = $DiscardPile
@onready var _speech: Panel = $Speech
@onready var _speech_text: Label = $Speech/Text
@onready var _finish_screen: FinishScreen = $FinishScreen


func _ready() -> void:
	_boss_bar.fill_role = &"bad"
	GameColors.changed.connect(_refresh)
	_boss = _load_json(str(GameState.phase_info("response").get("data", DEFAULT_DATA_PATH)))
	_cards = _load_json(CARDS_PATH).get("cards", {})
	_patterns = _boss["patterns"]
	var build := HardeningState.new()
	for id: String in build.deck_list():
		_deck.append(id)
	for id: String in build.equipped_list():
		_equipped.append(id)
	for id: String in _equipped:
		var gives: Dictionary = build.upgrades.get(id, {}).get("passive", {})
		for key: String in gives:
			_passive[key] = int(_passive.get(key, 0)) + int(gives[key])
	var doom: Dictionary = _boss.get("doom", {})
	if not doom.is_empty() and not _equipped.has(str(doom.get("counter", ""))):
		_doom = doom # the upgrade this threat cannot be beaten without is missing
		Music.play(&"response_doom") # a different, harsher tune: something is wrong
	_player_max = int(_boss["player_hp"]) + int(_passive.get("max_hp", 0))
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
	_fx.conceal(_hero) # they form out of pixels when the fight starts
	_fx.conceal(_enemy)
	_boss_name.text = str(_boss["threat"]).to_upper()
	if not _doom.is_empty():
		_doom_label = _boss_name.duplicate() as Label
		_doom_label.name = "DoomLabel"
		_doom_label.add_theme_color_override("font_color", GameColors.bad)
		_doom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_doom_label.position = Vector2(0, 22)
		_doom_label.size = Vector2(640, 10)
		add_child(_doom_label)
	_intent_icon.draw.connect(_draw_intent_icon)
	_intent.mouse_entered.connect(_on_intent_hover.bind(true))
	_intent.mouse_exited.connect(_on_intent_hover.bind(false))
	_energy_orbs.draw.connect(_draw_energy_orbs)
	_draw_icon.draw.connect(_paint_pile.bind(_draw_icon, false))
	_discard_icon.draw.connect(_paint_pile.bind(_discard_icon, true))
	_energy_orbs.mouse_filter = Control.MOUSE_FILTER_STOP
	_draw_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_discard_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	_draw_icon.tooltip_text = "Draw pile: your next cards come from here. When it is empty, the discard pile is shuffled back in."
	_discard_icon.tooltip_text = "Discard pile: played cards and the cards left in your hand at the end of a turn."
	_hand_fan.card_clicked.connect(_on_card_clicked)
	_end_turn.pressed.connect(_on_end_turn_pressed)
	_arena.hit.connect(_on_hit)
	_arena.pattern_finished.connect(_on_pattern_finished)
	_arena.note.connect(_on_arena_note)
	_arena.defense_used.connect(_on_defense_used)
	_arena.leaked.connect(_on_leaked)
	_arena.healed.connect(_on_arena_healed)
	_finish_screen.extra_requested.connect(func() -> void: SceneManager.load_scene(scene_file_path))
	_finish_screen.continue_requested.connect(_on_leave_pressed)
	_arena.hide()
	_speech.hide()
	var top_bar := ObjectiveBar.new()
	top_bar.icon = load("res://assets/ui/Response Icon.png")
	add_child(top_bar)
	move_child(top_bar, _finish_screen.get_index()) # the results of the fight cover it
	_draw_pile = _deck.duplicate()
	_draw_pile.shuffle()
	_build_upgrade_icons(build)
	_start_player_turn()
	await SceneManager.wait_for_transition()
	_fx.appear(_hero)
	_fx.appear(_enemy, 0.25)
	UiFx.banner("YOUR TURN", UiFx.CYAN, 150.0, 0.5, &"r_turn_you")
	Tutorial.maybe_show(self, "response")
	Tutorial.maybe_show_new(self, str(_boss.get("tutorial", "")))
	if not _doom.is_empty(): # nothing was done about this threat: the fight says so before it starts
		_set_strip(str(_doom["name"]), str(_doom["warn"]))
		await _wait(4.0)
		if not _over and _teach_title.text == str(_doom["name"]):
			_set_strip("")


## The equipped upgrades as small icons under the player's bar, so the player sees what they brought. An icon
## lights up when its upgrade does its job. Hover one to read it.
func _build_upgrade_icons(build: HardeningState) -> void:
	var row := HBoxContainer.new()
	row.name = "UpgradeIcons"
	row.position = _player_bar.position + Vector2(0, 26)
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
	_block = int(_passive.get("block_per_turn", 0)) # Block only lasts through the enemy's turn
	_cap = 0 # and Cap
	_reflect = 0 # and Reflect
	_dodge = int(_passive.get("dodge_per_turn", 0)) # and so does Dodge: an upgrade can start every turn with some
	if _leak > 0: # what leaked during the enemy turn is paid now; Block does not help
		_player_hp = maxi(_player_hp - _leak, 0)
		_float_text("-%d LEAK" % _leak, _hero.position + Vector2(0, -44), GameColors.bad, 1.0, 6, true)
		_fx.hurt(_hero, Vector2.LEFT)
		_leak = 0
		if _player_hp <= 0:
			_refresh()
			_finish(false)
			return
	_energy = int(_boss["energy"]) + _charge
	if _charge > 0:
		_float_text("+%d ENERGY" % _charge, _hero.position + Vector2(0, -44), Keywords.color_of("charge"), 1.0, 6, true)
		_charge = 0
	_player_hp = mini(_player_hp + int(_passive.get("heal_per_turn", 0)), _player_max)
	var first := _turn == 0
	if first:
		_energy += int(_passive.get("first_energy", 0))
	for i in int(_boss["hand_size"]) + (int(_passive.get("first_draw", 0)) if first else 0):
		_draw_one()
	_hand_fan.set_hand(_hand, _cards)
	_hand_fan.energy = _energy
	_hand_fan.enabled = true
	_end_turn.disabled = false
	if _turn > 0:
		UiFx.banner("YOUR TURN", UiFx.CYAN, 150.0, 0.5, &"r_turn_you")
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
## Draw gold sparks that rise from the card, Heal a green bolt to the player, Energy a gold ring and a bigger energy pool now.
func _on_card_clicked(index: int) -> void:
	var id := _hand[index]
	var card: Dictionary = _cards[id]
	var cost := int(card["cost"])
	if _over or _busy or cost > _energy:
		return
	_busy = true
	Sfx.play(&"r_card")
	_energy -= cost
	var effects: Dictionary = card.get("effects", {})
	var from := _hand_fan.card_center(index)
	_discard.append(id)
	_hand.remove_at(index)
	_hand_fan.remove_card(index)
	var damage := int(effects.get("damage", 0))
	if damage > 0:
		damage += int(_passive.get("attack_bonus", 0)) + _exposed # an upgrade makes every attack card hit harder, and so does the threat being Exposed
		if _exposed > 0: # Exploit: a bonus that only pays while the threat is Exposed
			damage += int(effects.get("exploit", 0))
			if int(effects.get("exploit", 0)) > 0:
				_float_text("EXPLOIT +%d" % int(effects["exploit"]), from + Vector2(0, -20), Keywords.color_of("exploit"), 0.6, 6, true)
	var block := int(effects.get("block", 0))
	var draw := int(effects.get("draw", 0))
	var heal := int(effects.get("heal", 0))
	var energy_gain := int(effects.get("energy", 0))
	var dodge := int(effects.get("dodge", 0))
	var expose := int(effects.get("expose", 0))
	var charge := int(effects.get("charge", 0))
	var cap := int(effects.get("cap", 0))
	var reflect := int(effects.get("reflect", 0))
	var wait := 0.1
	if damage > 0:
		_fx.attack(_hero, _enemy.global_position, GameColors.bad, 10.0)
		wait = maxf(wait, _fx.bolt(from, _enemy.global_position + Vector2(0, -4), GameColors.bad, damage / 20.0, func() -> void: _apply_damage(damage)))
	if block > 0:
		if damage == 0:
			_fx.cast(_hero, GameColors.block)
		wait = maxf(wait, _fx.bolt(from, _hero.global_position, GameColors.block, block / 10.0, func() -> void: _apply_block(block), 4.0))
	if dodge > 0:
		if damage == 0 and block == 0 and heal == 0:
			_fx.cast(_hero, GameColors.dodge)
		wait = maxf(wait, _fx.bolt(from, _hero.global_position, GameColors.dodge, dodge / 4.0, func() -> void: _apply_dodge(dodge), 4.0))
	if expose > 0: # it works on the cards played after this one (the damage above already counted)
		if damage == 0 and block == 0 and dodge == 0:
			_fx.cast(_hero, GameColors.exposed)
		wait = maxf(wait, _fx.bolt(from, _enemy.global_position + Vector2(0, -4), GameColors.exposed, expose / 3.0, func() -> void: _apply_expose(expose), 4.0))
	if heal > 0:
		if damage == 0 and block == 0:
			_fx.cast(_hero, GameColors.good)
		wait = maxf(wait, _fx.bolt(from, _hero.global_position, GameColors.good, heal / 6.0, func() -> void: _apply_heal(heal), 4.0))
	if energy_gain > 0:
		Sfx.play(&"r_energy")
		_energy += energy_gain # it can go above the usual energy: it is spent like the rest
		_fx.ring(from, GameColors.highlight, 4.0, 26.0)
		_float_text("+%d ENERGY" % energy_gain, from + Vector2(0, -20), GameColors.highlight, 0.6, 6, true)
	if reflect > 0: # the enemy turn: every hit that lands on you is sent back
		Sfx.play(&"r_reflect")
		_reflect += reflect
		_fx.ring(from, Keywords.color_of("reflect"), 4.0, 26.0)
		_float_text("REFLECT %d" % reflect, from + Vector2(0, -20), Keywords.color_of("reflect"), 0.6, 6, true)
	if cap > 0: # the enemy turn: no hit does more than this (the lowest Cap played counts)
		Sfx.play(&"r_cap")
		_cap = cap if _cap == 0 else mini(_cap, cap)
		_fx.ring(from, Keywords.color_of("cap"), 4.0, 26.0)
		_float_text("CAP %d" % cap, from + Vector2(0, -20), Keywords.color_of("cap"), 0.6, 6, true)
	if charge > 0: # Energy next turn, not now: it waits under the player's bar
		Sfx.play(&"r_energy")
		_charge += charge
		_fx.ring(from, Keywords.color_of("charge"), 4.0, 26.0)
		_float_text("+%d CHARGE" % charge, from + Vector2(0, -20), Keywords.color_of("charge"), 0.6, 6, true)
	for i in draw:
		var drawn := _draw_one()
		if not drawn.is_empty():
			_hand_fan.add_card(drawn, _cards[drawn])
	if draw > 0:
		Sfx.play(&"r_draw")
		if damage == 0 and block == 0 and dodge == 0:
			_fx.cast(_hero, GameColors.highlight)
		_fx.rise(from, GameColors.highlight, 8 + draw * 3)
		_fx.ring(from, GameColors.highlight, 4.0, 22.0)
		_float_text("DRAW %d" % draw, from + Vector2(0, -20), GameColors.highlight, 0.6, 6, true)
	_hand_fan.energy = _energy
	_refresh()
	await get_tree().create_timer(wait).timeout
	_busy = false


## The red bolt landed.
func _apply_damage(amount: int) -> void:
	Sfx.play(&"r_strike")
	_boss_hp = maxi(_boss_hp - amount, 0)
	_fx.slash(_enemy.global_position, GameColors.bad)
	_fx.hurt(_enemy, Vector2.RIGHT)
	_float_text("-%d" % amount, _enemy.position + Vector2(0, -44), Color.WHITE, 0.6, 12, true)
	_shake(2.0)
	_refresh()
	if _boss_hp <= 0:
		_finish(true)


## The green bolt landed: HP goes up, never above the maximum.
func _apply_heal(amount: int) -> void:
	Sfx.play(&"r_heal")
	var healed := mini(amount, _player_max - _player_hp)
	_player_hp += healed
	_fx.rise(_hero.global_position, GameColors.good, 8)
	_float_text("+%d HP" % healed, _hero.position + Vector2(0, -44), GameColors.good, 0.6, 6, true)
	_refresh()


## The pink bolt landed: the threat is Exposed (the status under its bar shows how much).
func _apply_expose(amount: int) -> void:
	Sfx.play(&"r_expose")
	_exposed += amount
	_fx.ring(_enemy.global_position, GameColors.exposed, 4.0, 24.0, 0.35)
	_float_text("EXPOSED +%d" % amount, _enemy.position + Vector2(0, -52), GameColors.exposed, 0.6, 6, true)
	_refresh()


## The purple bolt landed: the next hits of the enemy turn do nothing (_refresh shows the status under the bar).
func _apply_dodge(amount: int) -> void:
	Sfx.play(&"r_dodge")
	_dodge += amount
	_fx.rise(_hero.global_position, GameColors.dodge, 6)
	_float_text("+%d DODGE" % amount, _hero.position + Vector2(0, -44), GameColors.dodge, 0.6, 6, true)
	_refresh()


## The cyan bolt landed: the shield goes up around the player (_refresh shows it).
func _apply_block(amount: int) -> void:
	Sfx.play(&"r_block")
	_block += amount
	_fx.pulse_aura()
	_float_text("+%d BLOCK" % amount, _hero.position + Vector2(0, -44), GameColors.block, 0.6, 6, true)
	_refresh()


func _on_end_turn_pressed() -> void:
	if _busy:
		return
	_exposed = 0 # Exposed lasts until the end of your turn
	_discard.append_array(_hand)
	_hand.clear()
	_hand_fan.discard_all(_discard_icon.global_position + Vector2(6.0, 6.0)) # the hand flies to the discard pile
	_hand_fan.enabled = false
	_end_turn.disabled = true
	UiFx.banner("ENEMY TURN", UiFx.RED, 150.0, 0.5, &"r_turn_enemy")
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	var pattern_id := str(pattern.get("id", pattern["name"]))
	_hits = 0
	_dodged = 0
	_blocked = 0
	_through = 0
	_used.clear()
	_skip = false
	_intent.hide()
	_set_strip(str(pattern["name"]).to_upper())
	_refresh()
	var first_time := not _taught.has(pattern_id)
	if first_time: # the lesson is read now, before the bullets, and only the first time
		_taught.append(pattern_id)
		_type(_teach_body, str(pattern["teach"]))
	Sfx.play(&"r_windup")
	await _say(str(pattern["say"]))
	if first_time:
		await _wait(1.2)
	if _over:
		return
	Sfx.play(&"r_enemy_attack")
	await _fx.attack(_enemy, _hero.global_position, GameColors.bad, 16.0).finished # the threat strikes, then the bullets come
	if _over:
		return
	if _harder(pattern):
		await _announce_harder(pattern)
		if _over:
			return
	_set_strip("%s%s" % [str(pattern["name"]).to_upper(), " - HARDER" if _harder(pattern) else ""]) # while dodging, nothing to read
	_arena.defenses = _equipped
	_set_helper()
	Sfx.play(&"r_shoot")
	_arena.start(_doom_version(pattern) if not _doom.is_empty() else pattern)


## The equipped upgrade that warns early (a "helper" of the day's data: "helper_warning" seconds), if there is one.
func _set_helper() -> void:
	_arena.warning_bonus = 0.0
	_arena.helper_id = ""
	for defense: Dictionary in _boss["defenses"]:
		if defense.has("helper_warning") and _equipped.has(str(defense["id"])):
			_arena.warning_bonus = float(defense["helper_warning"])
			_arena.helper_id = str(defense["id"])
			_arena.helper_note = str(defense.get("helper_note", "EARLY WARNING"))


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
	Sfx.play(&"r_harder")
	_set_strip("%s - HARDER VERSION" % str(pattern["name"]).to_upper(), "", str(_counter_of(pattern).get("harder", "")))
	_fx.ring(_enemy.global_position, GameColors.bad, 10.0, 60.0, 0.5)
	_fx.burst(_enemy.global_position, GameColors.bad, 18, 110.0, 0.5)
	_float_text("HARDER", _enemy.position + Vector2(0, -52), GameColors.bad, 1.0, 6, true)
	_shake(3.0)
	await _wait(2.4) # time to read why (a click skips it)


## What the player should take from the enemy turn, from what actually happened in it.
func _lessons(pattern: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for defense: Dictionary in _boss["defenses"]:
		var id := str(defense["id"])
		if _used.has(id):
			lines.append(str(defense["works"]))
	return lines


func _on_arena_note(text: String, good: bool) -> void:
	var color := GameColors.good if good else GameColors.bad
	_float_text(text, Vector2(320.0, _arena.position.y + _arena.size.y + 22.0), color, 1.4, 6, true) # under the box (it is narrower than the text)


func _on_defense_used(id: String) -> void:
	_used[id] = int(_used.get(id, 0)) + 1
	if not _worked.has(id):
		_worked.append(id)
	if _upgrade_icons.has(id):
		_flash(_upgrade_icons[id])


# --- the enemy's turn ---

func _on_leaked(amount: int) -> void:
	_incoming_leak = amount


func _on_hit(damage: int) -> void:
	Sfx.play(&"r_stopped" if _dodge > 0 and _doom.is_empty() else &"r_hurt")
	var leak := _incoming_leak
	_incoming_leak = 0
	if _dodge > 0 and _doom.is_empty(): # a dodged hit does nothing at all, and does not touch Block (and adds no Leak); nothing can be dodged without the key upgrade
		_dodge -= 1
		_dodged += 1
		_fx.rise(_hero.global_position, GameColors.dodge, 6)
		_float_text("DODGED", _hero.position + Vector2(0, -44), GameColors.dodge, 0.6, 6, true)
		_shake(1.5)
		_refresh()
		return
	if _cap > 0 and damage > _cap: # Cap: a big hit is made small before Block takes its share
		_float_text("CAPPED %d" % (damage - _cap), _hero.position + Vector2(0, -56), Keywords.color_of("cap"), 0.6, 6, true)
		damage = _cap
	var absorbed := mini(_block, damage)
	_block -= absorbed
	_hits += 1
	_blocked += absorbed
	_through += damage - absorbed
	_player_hp = maxi(_player_hp - (damage - absorbed), 0)
	if leak > 0:
		_leak += leak
		_float_text("+%d LEAK" % leak, _hero.position + Vector2(0, -26), GameColors.bad, 0.6, 6, true)
	if damage - absorbed > 0 or leak > 0:
		var pattern_id := str(_patterns[_turn % _patterns.size()].get("id", ""))
		if not pattern_id.is_empty() and not hit_patterns.has(pattern_id):
			hit_patterns.append(pattern_id)
	if damage - absorbed > 0:
		_fx.hurt(_hero, Vector2.LEFT)
		if damage - absorbed >= 8:
			_fx.screen_flash(GameColors.bad, 0.25) # a heavy hit
	if absorbed > 0:
		_fx.pulse_aura()
	_shake(3.0 if absorbed == damage else 4.0 + damage * 0.25)
	if absorbed > 0:
		_float_text("BLOCKED %d" % absorbed, _hero.position + Vector2(0, -50), GameColors.block, 0.6, 6, true)
	if damage - absorbed > 0:
		_float_text("-%d" % (damage - absorbed), _hero.position + Vector2(0, -38), Color.WHITE, 0.6, 12, true)
	_refresh()
	if _player_hp <= 0:
		_arena.stop()
		_finish(false)
		return
	if _reflect > 0: # the hit is sent back (even when Block took it)
		if _boss_hp <= _reflect:
			_arena.stop()
		_apply_damage(_reflect)


## A real envelope of the Lure was touched: a little HP back.
func _on_arena_healed(amount: int) -> void:
	_apply_heal(amount)


func _on_pattern_finished() -> void:
	_arena.stop()
	if _over:
		return
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	_skip = false
	_set_strip("RESULT: %s" % str(pattern["name"]).to_upper())
	var line := "No hits. Nice dodging!"
	if _hits > 0:
		line = "You were hit %d time%s. %d damage got through" % [_hits, "" if _hits == 1 else "s", _through]
		line += (", Block stopped %d." % _blocked) if _blocked > 0 else "."
	if _dodged > 0:
		line = ("%s Dodge cancelled %d." % [line, _dodged]) if _hits > 0 else ("No damage got through. Dodge cancelled %d." % _dodged)
	await _type(_teach_body, line)
	await _wait(0.8)
	for lesson in _lessons(pattern):
		await _type(_teach_defense, lesson)
		await _wait(2.6)
	if _over:
		return
	_turn += 1
	_start_player_turn()


## The upgrade this threat cannot be beaten without is missing, so its attacks cannot be stopped: every pattern comes as a
## wall that fills the whole box (no gap to dodge through), each hit takes a share of the maximum HP, and Dodge does
## not cancel it. Block still takes its share, but it is not enough.
func _doom_version(pattern: Dictionary) -> Dictionary:
	var wall := pattern.duplicate(true)
	wall["kind"] = "doomwall"
	wall["harsh"] = {}
	wall["damage"] = ceili(_player_max * float(_doom.get("percent", 30)) / 100.0)
	wall["interval"] = 1.0
	wall["speed"] = 80
	wall["radius"] = 6.0
	wall["spacing"] = 8
	wall["scale"] = 1
	wall["rotate"] = false
	wall["duration"] = minf(float(pattern.get("duration", 8.0)), 8.0)
	wall["lead"] = 0.3
	return wall


## The line over the fight that says what the missing upgrade means.
func _refresh_doom() -> void:
	if _doom_label == null:
		return
	_doom_label.text = "%s: THE ATTACKS CANNOT BE DODGED" % str(_doom["name"])


func _show_next_pattern() -> void:
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	var harder := _harder(pattern)
	_intent_name.text = "%s%s" % [str(pattern["name"]), "  HARDER" if harder else ""]
	_intent_name.add_theme_color_override("font_color", GameColors.bad if harder else Color(0.95686275, 0.95686275, 0.95686275))
	_teach.hide()
	_intent.show()
	_intent_icon.queue_redraw()


## Pointing at the next attack (above the threat) opens the strip with what the player may want to know:
## what it is and, when the upgrade that counters it is missing, why it comes harder.
func _on_intent_hover(entered: bool) -> void:
	if not _hand_fan.enabled or _over:
		return
	if not entered:
		_teach.hide()
		return
	var pattern: Dictionary = _patterns[_turn % _patterns.size()]
	_set_strip("NEXT ATTACK: %s" % str(pattern["name"]).to_upper(), str(pattern["teach"]), str(_counter_of(pattern).get("harder", "")) if _harder(pattern) else "")


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


## The strip at the top: a title and, optionally, a body and a defense line. The panel is as tall as what
## it shows, so a title alone is a slim line and the strip is gone when there is nothing to read.
func _set_strip(title: String, body: String = "", defense: String = "") -> void:
	for pair: Array in [[_teach_title, title], [_teach_body, body], [_teach_defense, defense]]:
		var label: Label = pair[0]
		_typing[label] = 0 # a text still being typed into it stops
		label.text = pair[1]
		label.visible_characters = -1
	_fit_strip()


## Stacks the labels of the strip and sizes the panel to them (an empty label takes no room).
func _fit_strip() -> void:
	var y := 4.0
	for label: Label in [_teach_title, _teach_body, _teach_defense]:
		label.visible = not label.text.is_empty()
		if not label.visible:
			continue
		label.size = Vector2(328.0, 0.0)
		label.position.y = y
		label.size.y = label.get_minimum_size().y
		y += label.size.y + 3.0
	_teach.size.y = y + 1.0
	_teach.visible = not _teach_title.text.is_empty()


## Types a text into a label one letter at a time. A click shows the rest at once.
func _type(label: Label, text: String) -> void:
	var id := Time.get_ticks_usec()
	_typing[label] = id
	label.text = text
	_fit_strip()
	label.visible_characters = 0
	var shown := 0.0
	while shown < text.length() and not _skip and _typing[label] == id and is_inside_tree():
		await get_tree().process_frame
		shown += TYPE_SPEED * get_process_delta_time()
		if _typing[label] == id:
			if int(shown) / 3 != label.visible_characters / 3:
				Sfx.type_tick("Enemy" if label == _speech_text else "Joshua")
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
	_doomed = not won and not _doom.is_empty()
	Sfx.play(&"r_win" if won else &"r_lose")
	_hand_fan.enabled = false
	_end_turn.disabled = true
	await _play_ending()
	Music.play(&"hope" if won else &"defeat")
	_finish_screen.show_results(_finish_summary())


## What happens before the results: the threat falls apart and the player celebrates, or the player goes down.
func _play_ending() -> void:
	if _won:
		_shake(6.0)
		Sfx.play(&"r_defeat")
		await _fx.defeat(_enemy).finished
		_float_text("VICTORY!", _hero.position + Vector2(0, -52), GameColors.highlight, 1.2, 12, true)
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
			"comment": str(_doom.get("lost", comments["lost"]) if _doomed else comments["lost"]).replace("{threat}", str(_boss["threat"])),
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
	_refresh_doom()
	Music.set_intensity(1.0 - float(_boss_hp) / float(maxi(_boss_max, 1))) # one more instrument as the threat falls
	_boss_bar.set_values(_boss_max, _boss_hp)
	_player_bar.set_values(_player_max, _player_hp, _block)
	var statuses: Array[Dictionary] = []
	if _block > 0:
		var info := Keywords.explain("block")
		statuses.append({"id": "block", "amount": _block, "color": GameColors.block, "tip": "%s %d: %s" % [info.get("name", "Block"), _block, info.get("text", "")]})
	if _dodge > 0:
		var info := Keywords.explain("dodge")
		statuses.append({"id": "dodge", "amount": _dodge, "color": GameColors.dodge, "tip": "%s %d: %s" % [info.get("name", "Dodge"), _dodge, info.get("text", "")]})
	if _reflect > 0:
		var reflect_info := Keywords.explain("reflect")
		statuses.append({"id": "reflect", "amount": _reflect, "color": Keywords.color_of("reflect"), "tip": "%s %d: %s" % [reflect_info.get("name", "Reflect"), _reflect, reflect_info.get("text", "")]})
	if _cap > 0:
		var cap_info := Keywords.explain("cap")
		statuses.append({"id": "cap", "amount": _cap, "color": Keywords.color_of("cap"), "tip": "%s %d: %s" % [cap_info.get("name", "Cap"), _cap, cap_info.get("text", "")]})
	if _charge > 0:
		var charge_info := Keywords.explain("charge")
		statuses.append({"id": "charge", "amount": _charge, "color": Keywords.color_of("charge"), "tip": "%s %d: %s" % [charge_info.get("name", "Charge"), _charge, charge_info.get("text", "")]})
	if _leak > 0:
		var leak_info := Keywords.explain("leak")
		statuses.append({"id": "leak", "amount": _leak, "color": Keywords.color_of("leak"), "tip": "%s %d: %s" % [leak_info.get("name", "Leak"), _leak, leak_info.get("text", "")]})
	_player_bar.set_statuses(statuses)
	var threat_statuses: Array[Dictionary] = []
	if _exposed > 0:
		var exposed_info := Keywords.explain("exposed")
		threat_statuses.append({"id": "exposed", "amount": _exposed, "color": GameColors.exposed, "tip": "%s %d: %s" % [exposed_info.get("name", "Exposed"), _exposed, exposed_info.get("text", "")]})
	_boss_bar.set_statuses(threat_statuses)
	_energy_orbs.tooltip_text = "Energy: %d left. Cards cost energy. It is full again at the start of every turn." % _energy
	_energy_orbs.queue_redraw()
	_draw_icon.queue_redraw()
	_discard_icon.queue_redraw()
	if not _over:
		_fx.set_aura(_block > 0, _hero.global_position) # the shield is up while there is Block


## The energy as orbs: a bright one for each point left, a dark one for each spent. Extra energy from a card
## adds orbs.
func _draw_energy_orbs() -> void:
	var count := maxi(int(_boss["energy"]), _energy)
	for i in count:
		var at := Vector2(i * 13, 1)
		var lit := i < _energy
		var color: Color = GameColors.highlight if lit else Color(0.2, 0.23529412, 0.34117648)
		_energy_orbs.draw_rect(Rect2(at + Vector2(1, 0), Vector2(8, 10)), color)
		_energy_orbs.draw_rect(Rect2(at + Vector2(0, 1), Vector2(10, 8)), color)
		if lit:
			_energy_orbs.draw_rect(Rect2(at + Vector2(2, 2), Vector2(2, 2)), Color.WHITE)


## A pile as a small stack of card backs with its count next to it.
func _paint_pile(icon: Control, discard: bool) -> void:
	var count := _discard.size() if discard else _draw_pile.size()
	var back := Color(0.16078432, 0.21176471, 0.43529412)
	var edge := Color(0.5803922, 0.6901961, 0.7607843)
	for layer in (2 if count > 1 else 1):
		var at := Vector2(1 + layer * 2, 3 - layer * 2)
		icon.draw_rect(Rect2(at - Vector2(1, 1), Vector2(11, 14)), edge)
		icon.draw_rect(Rect2(at, Vector2(9, 12)), back)
	icon.draw_rect(Rect2(Vector2(4, 6), Vector2(3, 3)), edge)
	icon.draw_string(FONT, Vector2(16, 12), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.95686275, 0.95686275, 0.95686275))


# --- for the Debug panel (=) ---

## Wins the fight as if every attack of the day had hit once: the player ends with the HP that is left after one hit of each
## pattern (at least 1), and Recovery gets the most repairs it can have.
func debug_win_with_every_repair() -> void:
	if _over:
		return
	var taken := 0
	for pattern: Dictionary in _patterns:
		var id := str(pattern.get("id", ""))
		if not id.is_empty() and not hit_patterns.has(id):
			hit_patterns.append(id)
		taken += int(pattern.get("damage", 1))
	_arena.stop()
	_arena.hide()
	_player_hp = clampi(_player_max - taken, 1, _player_max)
	_boss_hp = 0
	_refresh()
	_finish(true)


func debug_actions() -> Array:
	return [
		["Win the fight >", func() -> void: _boss_hp = 0; _refresh(); _finish(true)],
		["Win, every attack got through >", debug_win_with_every_repair],
		["Heal to full >", func() -> void: _player_hp = _player_max; _refresh()],
		["Give 3 energy >", func() -> void: _energy += 3; _hand_fan.energy = _energy; _refresh()],
	]
