extends Node

## Autoload for the Sounds & Volume settings. The game has no sound yet, so this only keeps the
## player's choices and puts them on the audio buses: Master, and a Music and an SFX bus (made here
## when the project has none). Sound that is added later should play on "Music" or "SFX".
##
## Volumes are 0 to 100. Mute in Background silences the game while its window is not the active one.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "audio"
const KEY_MUTE_BACKGROUND := "mute_in_background"
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX"]

var mute_in_background: bool = false

var _volumes := {&"Master": 100.0, &"Music": 100.0, &"SFX": 100.0}
var _in_background := false


func _ready() -> void:
	for bus in BUSES:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			AudioServer.set_bus_send(index, &"Master")
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		mute_in_background = bool(config.get_value(SECTION, KEY_MUTE_BACKGROUND, false))
		for bus in BUSES:
			_volumes[bus] = clampf(float(config.get_value(SECTION, String(bus).to_lower(), 100.0)), 0.0, 100.0)
	for bus in BUSES:
		_apply(bus)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_in_background = true
		_apply(&"Master")
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_in_background = false
		_apply(&"Master")


func volume(bus: StringName) -> float:
	return _volumes[bus]


## `save` is false when only trying a value (the tests).
func set_volume(bus: StringName, value: float, save: bool = true) -> void:
	_volumes[bus] = clampf(value, 0.0, 100.0)
	_apply(bus)
	if save:
		_save()


func set_mute_in_background(value: bool, save: bool = true) -> void:
	mute_in_background = value
	_apply(&"Master")
	if save:
		_save()


func _apply(bus: StringName) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index == -1:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(_volumes[bus] / 100.0))
	if bus == &"Master":
		AudioServer.set_bus_mute(index, mute_in_background and _in_background)


func _save() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_MUTE_BACKGROUND, mute_in_background)
	for bus in BUSES:
		config.set_value(SECTION, String(bus).to_lower(), _volumes[bus])
	config.save(SETTINGS_PATH)
