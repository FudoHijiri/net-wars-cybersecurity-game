extends Node

## Autoload (Sfx): the sound effects. `Sfx.play(&"click")` plays one sound of a group; the groups and their files
## are in data/sfx.json. A group has several files and plays a different one each time (never the same twice in a
## row), with a little random pitch and volume, so the sounds that come up all the time (clicks, the typing of
## text) do not turn monotonous.
##
## Every button, check box, option list and slider of the game makes its sound by itself: the autoload joins them
## when they enter the tree, so a new button needs nothing. The sound is the one named for what the button does:
## back, close, open, confirmation, select, switch (a tab), toggle (a switch), tick (hover), scroll... The rules
## that say which button is which are "button_rules" in data/sfx.json (by the node's name or the words of its text).
## A control in the group "no_sfx" is left quiet.
## The sounds play on the SFX bus, so the volume sliders of Settings count.

const DATA_PATH := "res://data/sfx.json"
const FOLDER := "res://assets/audio/sfx/"
const VOICES := 12
const SCROLL_SESSION := 0.3 # seconds without scroll input after which the next input is a new scroll

var _groups: Dictionary = {} # name -> {streams, volume, pitch, gap, last (index), last_time (msec)}
var _voices: Dictionary = {} # who speaks -> the pitch of the typing
var _rules: Array = [] # which button makes which group (data/sfx.json)
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0
var _scroll_last := -100000 # msec of the last scroll input
var _scroll_sound := -1 # the sound of the scroll in progress
var _scrollbar_held := false # a scroll bar is held with the left button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # the pause menu and the confirm panel make sounds while the game is paused
	_load()
	var bus: StringName = &"SFX" if AudioServer.get_bus_index(&"SFX") != -1 else &"Master"
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = bus
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)


func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Sfx: cannot read %s" % DATA_PATH)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	_voices = data.get("voices", {})
	_rules = data.get("button_rules", [])
	for group_name: String in data.get("groups", {}):
		var info: Dictionary = data["groups"][group_name]
		var streams: Array = []
		for file_name: String in info.get("files", []):
			var stream := load(FOLDER + file_name) as AudioStream
			if stream != null:
				streams.append(stream)
		if streams.is_empty():
			continue
		_groups[StringName(group_name)] = {
			"streams": streams, "volume": float(info.get("volume", 0.0)), "pitch": float(info.get("pitch", 0.05)),
			"gap": float(info.get("gap", 0.0)), "last": -1, "last_time": -100000,
		}


## Plays one sound of the group. `pitch` is a factor for the group's own pitch (1.0 = as it is).
func play(group: StringName, volume_offset: float = 0.0, pitch: float = 1.0) -> void:
	var info: Dictionary = _groups.get(group, {})
	if info.is_empty():
		return
	var now := Time.get_ticks_msec()
	if now - int(info["last_time"]) < int(float(info["gap"]) * 1000.0):
		return # the same sound twice in an instant is only a louder sound
	info["last_time"] = now
	var streams: Array = info["streams"]
	var index := _pick(info)
	var player := _free_player()
	player.stream = streams[index]
	player.volume_db = float(info["volume"]) + volume_offset + randf_range(-1.5, 1.5)
	player.pitch_scale = maxf(pitch * (1.0 + randf_range(-float(info["pitch"]), float(info["pitch"]))), 0.1)
	player.play()


## A random sound of the group, never the same one twice in a row.
func _pick(info: Dictionary) -> int:
	var count: int = info["streams"].size()
	var index := randi() % count
	if count > 1 and index == int(info["last"]):
		index = (index + 1 + randi() % (count - 1)) % count
	info["last"] = index
	return index


## One step of a scroll (the mouse wheel over a list, or a scroll bar held with the left button). A scroll has one
## sound, repeated while the input goes on; a new input after a pause (or a new press on a scroll bar) gets a new
## random one. No random change of pitch or volume inside a scroll, so the repeats are the same sound.
func scroll_step(new_scroll: bool = false) -> void:
	var info: Dictionary = _groups.get(&"scroll", {})
	if info.is_empty():
		return
	var now := Time.get_ticks_msec()
	var begins := new_scroll or now - _scroll_last > int(SCROLL_SESSION * 1000.0)
	_scroll_last = now
	if begins:
		_scroll_sound = _pick(info)
	if now - int(info["last_time"]) < int(float(info["gap"]) * 1000.0):
		return
	info["last_time"] = now
	var player := _free_player()
	player.stream = info["streams"][_scroll_sound]
	player.volume_db = float(info["volume"])
	player.pitch_scale = 1.0
	player.play()


## One key press of the typing of a text. `speaker` sets the pitch (Carla's voice is higher than Joshua's).
func type_tick(speaker: String = "") -> void:
	play(&"type", 0.0, float(_voices.get(speaker, _voices.get("default", 1.0))))


func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	_next_player = (_next_player + 1) % _players.size() # all are busy: the oldest one is cut
	return _players[_next_player]


# --- the controls make their own sounds ---

## A mouse wheel turn over something that scrolls.
func _input(event: InputEvent) -> void:
	var wheel := event as InputEventMouseButton
	if wheel != null and not wheel.pressed and wheel.button_index == MOUSE_BUTTON_LEFT:
		_scrollbar_held = false
	if wheel == null or not wheel.pressed or not (wheel.button_index == MOUSE_BUTTON_WHEEL_UP or wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN):
		return
	var control := get_viewport().gui_get_hovered_control()
	for step in 5:
		if control == null:
			return
		if control is ScrollContainer or control is ItemList or (control is RichTextLabel and (control as RichTextLabel).scroll_active):
			scroll_step()
			return
		control = control.get_parent() as Control

func _on_node_added(node: Node) -> void:
	if node.has_meta(&"sfx_joined"):
		return # moved to another parent (reparent): it is already joined
	if node is BaseButton or node is Slider or node is ScrollBar:
		node.set_meta(&"sfx_joined", true)
	if node is BaseButton:
		_join_button(node as BaseButton)
	elif node is Slider:
		(node as Slider).value_changed.connect(_on_slider_changed.bind(node))
	elif node is ScrollBar:
		(node as ScrollBar).gui_input.connect(_on_scrollbar_input)
		(node as ScrollBar).value_changed.connect(_on_scrollbar_changed.bind(node))


func _join_button(button: BaseButton) -> void:
	button.pressed.connect(_on_button_pressed.bind(button))
	button.mouse_entered.connect(_on_button_hover.bind(button))
	if button is OptionButton:
		(button as OptionButton).item_selected.connect(func(_index: int) -> void: play(&"select"))


func _quiet(control: Control) -> bool:
	return not is_instance_valid(control) or control.is_in_group(&"no_sfx")


func _on_button_pressed(button: BaseButton) -> void:
	if _quiet(button):
		return
	var kind := _kind_of(button)
	if kind != &"": # an empty group: this button has its own sound
		play(kind)


func _on_button_hover(button: BaseButton) -> void:
	if _quiet(button) or button.disabled or not button.is_visible_in_tree():
		return
	play(&"hover")


func _on_scrollbar_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.button_index == MOUSE_BUTTON_LEFT and click.pressed:
		_scrollbar_held = true
		_scroll_last = -100000 # a new press is a new scroll


## The value of a scroll bar changes while the left button is held on it (dragging, or clicking its arrows or track).
## The mouse wheel has its own sound, so this is only for the button.
func _on_scrollbar_changed(_value: float, bar: ScrollBar) -> void:
	if _scrollbar_held and not _quiet(bar) and bar.is_visible_in_tree():
		scroll_step()


func _on_slider_changed(value: float, slider: Slider) -> void:
	if _quiet(slider) or not slider.is_visible_in_tree():
		return
	var span := maxf(slider.max_value - slider.min_value, 0.001)
	play(&"slider", 0.0, 0.8 + 0.5 * clampf((value - slider.min_value) / span, 0.0, 1.0)) # higher up, higher sound


## What a button sounds like: a switch, a tab, an open or a close, back, confirm, or a plain click.
func _kind_of(button: BaseButton) -> StringName:
	if button is CheckButton or button is CheckBox:
		return &"toggle"
	if button is OptionButton:
		return &"open" # the list opens; choosing an item has its own sound
	var node_name := String(button.name).to_lower()
	var words := _words_of(button)
	var is_icon := words.is_empty()
	for rule: Dictionary in _rules:
		if rule.get("texture", false) and not is_icon:
			continue
		var fits := false
		for part: String in rule.get("names", []):
			fits = fits or node_name.contains(part)
		for word: String in rule.get("texts", []):
			fits = fits or words.has(word)
		if not fits:
			continue
		if rule.get("state", false): # a switch that opens something when it goes down and closes it when it comes up
			return &"open" if button.button_pressed else &"close"
		return StringName(str(rule.get("group", "")))
	if button.toggle_mode:
		return &"tab" if button.button_group != null else &"toggle" # one of a group is a tab; a lone one is a switch
	return &"click"


func _words_of(button: BaseButton) -> Array[String]:
	var found: Array[String] = []
	var text := str(button.get("text")).to_lower() if "text" in button else ""
	for raw: String in text.split(" ", false):
		var word := ""
		for letter in raw:
			if letter >= "a" and letter <= "z":
				word += letter
		if not word.is_empty():
			found.append(word)
	return found
