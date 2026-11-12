extends RecoveryTask

## Restore from the right backup, then make sure it never happens again. Step 1: a timeline of backups with a red
## marker where the infection began; pick the newest one that is from BEFORE the infection, kept offline and
## checked, test it, restore it, and read how much work the gap cost. Step 2: the 3-2-1 rule: three copies, on two
## kinds of storage, one of them offline. Layout: BackupTimeline.tscn (everything is built here from the content:
## backups [{id, label, ok, bad, detail}], marker {after, label}, lost, storage [..], copies, offline_place).

const OPTION_THEME := preload("res://assets/ui/optionbar/option_button_theme.tres")

var selected := ""
var tested := ""
var _buttons: Dictionary = {} # backup id -> Button
var _details: Label
var _test: Button
var _restore: Button
var _rule: VBoxContainer
var _copy_options: Array[OptionButton] = []
var _restored := false


func setup_task() -> void:
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("heading", ""))
	body.add_child(heading)
	var line := HBoxContainer.new()
	body.add_child(line)
	var group := ButtonGroup.new()
	var marker: Dictionary = content.get("marker", {})
	for backup: Dictionary in content.get("backups", []):
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = str(backup["label"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select.bind(str(backup["id"])))
		line.add_child(button)
		_buttons[str(backup["id"])] = button
		if str(marker.get("after", "")) == str(backup["id"]):
			var infection := Label.new()
			infection.theme_type_variation = &"RecoveryWarning"
			infection.text = str(marker.get("label", ""))
			infection.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			line.add_child(infection)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.custom_minimum_size = Vector2(0, 30)
	body.add_child(_details)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	_test = Button.new()
	_test.text = str(content.get("test", "TEST COPY"))
	_test.pressed.connect(_test_pressed)
	actions.add_child(_test)
	_restore = Button.new()
	_restore.text = str(content.get("restore", "RESTORE"))
	_restore.pressed.connect(_restore_pressed)
	actions.add_child(_restore)
	_build_rule()


func _build_rule() -> void:
	_rule = VBoxContainer.new()
	body.add_child(_rule)
	var title := Label.new()
	title.theme_type_variation = &"RecoveryAccent"
	title.text = str(content.get("rule_heading", ""))
	_rule.add_child(title)
	var row := HBoxContainer.new()
	_rule.add_child(row)
	for i in int(content.get("copies", 3)):
		var option := OptionButton.new()
		option.theme = OPTION_THEME
		option.add_item(str(content.get("rule_pick", "Where?")))
		for place: String in content.get("storage", []):
			option.add_item(place)
		row.add_child(option)
		_copy_options.append(option)
	var check := Button.new()
	check.text = str(content.get("rule_check", "CHECK"))
	check.pressed.connect(_check_rule)
	_rule.add_child(check)


func reset_state() -> void:
	selected = ""
	tested = ""
	_restored = false
	for button: Button in _buttons.values():
		button.set_pressed_no_signal(false)
	for option in _copy_options:
		option.select(0)
	_details.text = str(content.get("choose", ""))
	_rule.hide()
	_test.disabled = false
	_restore.disabled = false
	set_feedback(str(content.get("pick", "")))


func _backup(id: String) -> Dictionary:
	for backup: Dictionary in content.get("backups", []):
		if str(backup["id"]) == id:
			return backup
	return {}


func _select(id: String) -> void:
	if solved or _restored:
		return
	selected = id
	tested = ""
	_details.text = str(_backup(id).get("detail", ""))


func _test_pressed() -> void:
	if solved or _restored:
		return
	if selected.is_empty():
		set_feedback(str(content.get("select_first", "")))
		return
	var backup := _backup(selected)
	if not backup.get("ok", false):
		note_mistake(str(backup.get("bad", "")))
		return
	tested = selected
	set_feedback(str(content.get("tested", "")), "good")


func _restore_pressed() -> void:
	if solved or _restored:
		return
	if selected.is_empty() or tested != selected:
		set_feedback(str(content.get("test_first", "")))
		return
	_restored = true
	_test.disabled = true
	_restore.disabled = true
	if str(content.get("rule_heading", "")).is_empty(): # versions of one file: nothing more to set up
		succeed()
		return
	_rule.show()
	set_feedback("%s %s" % [content.get("restored", ""), content.get("lost", "")], "good")


## 3 copies, at least 2 kinds of storage, at least 1 offline.
func _check_rule() -> void:
	if solved or not _restored:
		return
	var places: Array[String] = []
	for option in _copy_options:
		if option.selected <= 0:
			set_feedback(str(content.get("rule_empty", "")))
			return
		places.append(option.get_item_text(option.selected))
	var kinds: Array[String] = []
	for place in places:
		if not kinds.has(place):
			kinds.append(place)
	if kinds.size() < 2:
		note_mistake(str(content.get("rule_one_kind", "")))
	elif not places.has(str(content.get("offline_place", "Offline drive"))):
		note_mistake(str(content.get("rule_not_offline", "")))
	else:
		succeed()
