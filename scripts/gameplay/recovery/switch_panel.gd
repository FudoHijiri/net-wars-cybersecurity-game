extends RecoveryTask

## A panel of switches: turn on what is off, leave what is already right. Layout: SwitchPanel.tscn (the rows are
## built here from content.items). Each item is {id, label, note, on, reason}: "on": true is already right and
## must stay on (switching it off bounces back with its reason). The task finishes when every switch is on.
## Used for "Update the other laptops" (Day 2); any later day can reuse it with other items.

var switches: Dictionary = {} # item id -> CheckButton
var _items: Dictionary = {}
var _notes: Dictionary = {} # item id -> Label


func setup_task() -> void:
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("switch_heading", ""))
	body.add_child(heading)
	for item: Dictionary in content.get("items", []):
		var id := str(item["id"])
		_items[id] = item
		var row := PanelContainer.new()
		row.theme_type_variation = &"RecoveryWindow"
		var line := HBoxContainer.new()
		row.add_child(line)
		var name_label := Label.new()
		name_label.text = str(item["label"])
		name_label.custom_minimum_size = Vector2(120, 0)
		line.add_child(name_label)
		var status := Label.new()
		status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(status)
		var toggle := CheckButton.new()
		toggle.text = str(content.get("switch", "Updates"))
		toggle.toggled.connect(_toggled.bind(id))
		line.add_child(toggle)
		body.add_child(row)
		switches[id] = toggle
		_notes[id] = status


func reset_state() -> void:
	for id: String in switches:
		var item: Dictionary = _items[id]
		switches[id].disabled = false
		switches[id].set_pressed_no_signal(item.get("on", false))
		_show(id, item.get("on", false))
	set_feedback(str(content.get("pick", "")))


func _show(id: String, on: bool) -> void:
	var item: Dictionary = _items[id]
	_notes[id].text = str(item.get("note_on" if on else "note_off", ""))
	_notes[id].theme_type_variation = &"" if on else &"RecoveryWarning"


func _toggled(on: bool, id: String) -> void:
	if solved:
		return
	var item: Dictionary = _items[id]
	if not on and item.get("on", false):
		switches[id].set_pressed_no_signal(true) # already right: it stays on
		UiFx.shake(switches[id])
		note_mistake(str(item.get("reason", "")))
		return
	if not on:
		_show(id, false)
		return
	_show(id, true)
	UiFx.pop(_notes[id])
	if not item.get("on", false):
		set_feedback(str(content.get("updated", "")).format({"laptop": item["label"], "left": _off_left()}), "good")
	if _off_left() == 0:
		succeed()


func _off_left() -> int:
	var left := 0
	for id: String in switches:
		if not switches[id].button_pressed:
			left += 1
	return left
