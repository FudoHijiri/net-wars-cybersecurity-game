extends RecoveryTask

## Change the Locks. Layout: ChangeTheLocks.tscn.
## Each door under %Doors is one account (content.doors). Drag the stolen key (%Key) onto a door,
## or press the key and then a door, to test it: doors with "reused": true open, the others hold.
## Press an opened door to change its lock. The task finishes when every reused door has a new lock.
## Changing a lock that held, or before testing it, is a mistake with a reason.

var door_buttons: Dictionary = {}
## door id -> "untested", "opened", "held" or "rekeyed"
var door_state: Dictionary = {}
var key_picked := false
var _doors: Dictionary = {}

@onready var key: RecoveryDragItem = %Key


func setup_task() -> void:
	%KeyLabel.text = str(content.get("key_label", "Stolen key:"))
	key.text = str(content.get("key", "KEY"))
	key.item_id = "key"
	key.pressed.connect(_pick_key)
	var doors: Array = content.get("doors", [])
	var nodes := %Doors.get_children()
	for i in nodes.size():
		var door := nodes[i] as RecoveryDropSlot
		door.visible = i < doors.size()
		if not door.visible:
			continue
		var id := str(doors[i]["id"])
		door.slot_id = id
		door.pressed.connect(_door_pressed.bind(id))
		door.item_dropped.connect(func(_item: RecoveryDragItem) -> void: _test(id))
		door_buttons[id] = door
		_doors[id] = doors[i]
	if door_buttons.size() < doors.size():
		push_warning("ChangeTheLocks.tscn has fewer doors than the JSON lists.")


func reset_state() -> void:
	key_picked = false
	for id: String in door_buttons:
		_set_door(id, "untested")
	set_feedback(str(content.get("pick", "")))


func _pick_key() -> void:
	if solved:
		return
	key_picked = true
	set_feedback(str(content.get("key_picked", "")))


func _door_pressed(id: String) -> void:
	if solved:
		return
	if key_picked:
		_test(id)
		return
	match door_state[id]:
		"opened":
			_set_door(id, "rekeyed")
			var left := _reused_left()
			if left == 0:
				succeed()
			else:
				set_feedback(str(content.get("rekeyed", "")).format({"left": left}), "good")
		"held":
			door_buttons[id].bounce()
			note_mistake(str(_doors[id].get("reason", "")))
		"untested":
			note_mistake(str(content.get("test_first", "")))
		_:
			pass


## Tries the stolen key in one door.
func _test(id: String) -> void:
	key_picked = false
	if solved or door_state[id] != "untested":
		return
	var reused: bool = _doors[id].get("reused", false)
	_set_door(id, "opened" if reused else "held")
	set_feedback(str(content.get("opened" if reused else "held", "")).format({"name": str(_doors[id].get("name", "")).replace("\n", " ")}))
	door_buttons[id].grab_focus()


func _set_door(id: String, state: String) -> void:
	door_state[id] = state
	var labels: Dictionary = content.get("door_states", {})
	var door: Button = door_buttons[id]
	door.text = "%s\n\n%s" % [_doors[id].get("name", id), labels.get(state, state)]
	# Green once re-locked, amber while the stolen key still opens it, grey when it held.
	door.theme_type_variation = &"RecoveryCardGood" if state == "rekeyed" else &"RecoveryCard"
	door.remove_theme_color_override("font_color")
	if state == "opened":
		door.add_theme_color_override("font_color", Color(1, 0.8039216, 0.45882353))
	elif state == "held":
		door.add_theme_color_override("font_color", Color(0.5803922, 0.6901961, 0.7607843))


func _reused_left() -> int:
	var left := 0
	for id: String in _doors:
		if _doors[id].get("reused", false) and door_state[id] != "rekeyed":
			left += 1
	return left
