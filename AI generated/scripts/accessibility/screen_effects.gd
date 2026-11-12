extends Node

## Autoload for the Reduce Screen Effects setting in Settings > General.
##
## Reduce Screen Effects: with it on, scenes change instantly (no fade of the loading screen) and the short shake of the
## Response fight is not played (shake_allowed()). The Color Blind filter is an accessibility tool and is not an "effect",
## so it is never reduced.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "accessibility"
const KEY_REDUCE_EFFECTS := "reduce_screen_effects"

var reduce_effects: bool = false


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		reduce_effects = bool(config.get_value(SECTION, KEY_REDUCE_EFFECTS, false))


func set_reduce_effects(value: bool) -> void:
	reduce_effects = value
	_save()


## True when the short shake of the Response fight may be played: the player has not asked for fewer effects.
func shake_allowed() -> bool:
	return not reduce_effects


func _save() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_REDUCE_EFFECTS, reduce_effects)
	config.save(SETTINGS_PATH)
