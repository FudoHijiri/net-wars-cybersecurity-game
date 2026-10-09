extends Node

## Autoload for the two screen-effect settings in Settings > General.
##
## Reduce Screen Effects: the only screen effect the game has is the short fade between
## scenes (SceneFade). With this on, scenes change instantly. The Color Blind filter is an
## accessibility tool and is not an "effect", so it is never reduced.
##
## Screen Shake: the game has no screen shake yet, so this setting only stores the player's
## choice. Anything that adds a shake later should ask shake_allowed() first.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "accessibility"
const KEY_REDUCE_EFFECTS := "reduce_screen_effects"
const KEY_SCREEN_SHAKE := "screen_shake"

var reduce_effects: bool = false
var screen_shake: bool = true


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		reduce_effects = bool(config.get_value(SECTION, KEY_REDUCE_EFFECTS, false))
		screen_shake = bool(config.get_value(SECTION, KEY_SCREEN_SHAKE, true))


func set_reduce_effects(value: bool) -> void:
	reduce_effects = value
	_save()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	_save()


## True when a screen shake would be allowed: the player wants it and has not asked for
## fewer effects. Nothing uses this yet because the game has no shake.
func shake_allowed() -> bool:
	return screen_shake and not reduce_effects


func _save() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_REDUCE_EFFECTS, reduce_effects)
	config.set_value(SECTION, KEY_SCREEN_SHAKE, screen_shake)
	config.save(SETTINGS_PATH)
