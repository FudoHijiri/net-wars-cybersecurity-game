extends Node

## Autoload for the "Custom Colors" accessibility setting.
##
## The Color Blind Mode filter shifts every color on the screen. This is the other way: the game's
## few colors that carry a MEANING are named roles, and the player can change each role on its own.
## Good (your HP, healing, a right answer), Bad (the threat's HP, damage, a wrong answer), Block,
## Highlight (gold: the objective, the card border), Dodge and Exposed.
##
## Whatever draws one of these asks here (GameColors.good, GameColors.bad, ...) instead of holding its
## own copy of the color. Anything that is drawn again (the HP bars, the arena) follows a change at
## once; text and effects that were already made keep the old color until they are made again.
## The `changed` signal tells a node that it should redraw.

signal changed

enum Palette { DEFAULT, RED_GREEN_SAFE, CUSTOM }

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "accessibility"
const KEY_COLORS := "custom_colors"

const PALETTE_NAMES: Array[String] = ["Default", "Red-Green Safe", "Custom"]

## In the order of the Settings rows. `fill` is the darker color used behind text (a bar, a tag); a
## role the player has changed makes its fill by darkening the chosen color.
const ROLES: Array[StringName] = [&"good", &"bad", &"block", &"highlight", &"dodge", &"exposed"]
const INFO := {
	&"good": {"name": "Good", "hint": "Your HP, healing, and a right answer.", "color": Color("a7f070"), "fill": Color("38b764")},
	&"bad": {"name": "Bad", "hint": "The threat's HP, damage, warnings, and a wrong answer.", "color": Color(1.0, 0.35, 0.3), "fill": Color("b13e53")},
	&"block": {"name": "Block", "hint": "Block and the shield around you.", "color": Color("73eff7"), "fill": Color("29b6c4")},
	&"highlight": {"name": "Highlight", "hint": "Gold: the objective, card borders and what to look at.", "color": Color(1, 0.8039216, 0.45882353), "fill": Color("c9953a")},
	&"dodge": {"name": "Dodge", "hint": "Dodge on you and on the cards.", "color": Color("d6a5ff"), "fill": Color("9d6fd0")},
	&"exposed": {"name": "Exposed", "hint": "Exposed on the threat and on the cards.", "color": Color("ff8fb1"), "fill": Color("c9587c")},
}

## The colors the Settings rows offer: the Okabe-Ito set (made for every kind of color blindness) and
## the game's own bright colors.
const SWATCHES: Array[Color] = [
	Color("ffffff"), Color("f0e442"), Color("ffcd75"), Color("e69f00"), Color("d55e00"), Color(1.0, 0.35, 0.3),
	Color("ff8fb1"), Color("cc79a7"), Color("d6a5ff"), Color("41a6f6"), Color("56b4e9"), Color("73eff7"),
	Color("009e73"), Color("a7f070"), Color("94b0c2"),
]

## A palette is only the roles it changes; the rest keep their own color.
const PRESETS := {
	Palette.RED_GREEN_SAFE: {
		&"good": Color("56b4e9"), &"bad": Color("d55e00"), &"block": Color("009e73"),
		&"highlight": Color("f0e442"), &"dodge": Color("cc79a7"), &"exposed": Color("e69f00"),
	},
}
const FILL_DARKEN := 0.3
## A fill lighter than this gets dark text on it, a darker one gets light text.
const DARK_TEXT := Color("1a1c2c")
const LIGHT_TEXT := Color("f4f4f4")

var good: Color: get = _get_good
var bad: Color: get = _get_bad
var block: Color: get = _get_block
var highlight: Color: get = _get_highlight
var dodge: Color: get = _get_dodge
var exposed: Color: get = _get_exposed

var _custom: Dictionary = {} # role -> Color, only the roles the player changed


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var stored: Variant = config.get_value(SECTION, KEY_COLORS, {})
	if stored is Dictionary:
		for role: Variant in stored:
			if StringName(role) in ROLES:
				_custom[StringName(role)] = Color(str(stored[role]))


func color(role: StringName) -> Color:
	return _custom.get(role, INFO[role]["color"])


## The darker color of a role, for the fill of a bar or a tag.
func fill(role: StringName) -> Color:
	if _custom.has(role):
		return (_custom[role] as Color).darkened(FILL_DARKEN)
	return INFO[role]["fill"]


## The text color that reads on `background`.
func text_on(background: Color) -> Color:
	return DARK_TEXT if background.get_luminance() > 0.35 else LIGHT_TEXT


## The roles the player changed, role -> Color.
func custom_colors() -> Dictionary:
	return _custom.duplicate()


## Which palette some changed roles add up to (CUSTOM when they are the player's own mix).
func palette_of(custom: Dictionary) -> int:
	if custom.is_empty():
		return Palette.DEFAULT
	for id: int in PRESETS:
		if custom == PRESETS[id]:
			return id
	return Palette.CUSTOM


## Replaces the changed roles at once (what Settings > Apply does). `save` is false when only trying
## a value (the tests).
func set_custom_colors(custom: Dictionary, save: bool = true) -> void:
	_custom = custom.duplicate()
	changed.emit()
	if save:
		_save()


func _save() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var stored := {}
	for role: StringName in _custom:
		stored[String(role)] = (_custom[role] as Color).to_html(false)
	config.set_value(SECTION, KEY_COLORS, stored)
	config.save(SETTINGS_PATH)


func _get_good() -> Color:
	return color(&"good")


func _get_bad() -> Color:
	return color(&"bad")


func _get_block() -> Color:
	return color(&"block")


func _get_highlight() -> Color:
	return color(&"highlight")


func _get_dodge() -> Color:
	return color(&"dodge")


func _get_exposed() -> Color:
	return color(&"exposed")
