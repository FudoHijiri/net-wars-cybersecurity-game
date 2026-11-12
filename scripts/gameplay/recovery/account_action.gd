extends RecoveryTask

## Two steps about a person: first close the right account, then choose how to talk to them. Layout:
## AccountAction.tscn (everything is built here from the content: accounts [{id, label, detail, ok, reason}],
## talk [{id, label, ok, reason}]). A wrong choice bounces back with its reason and counts as a wrong move.
## Used for "Disable the account, then talk to the person" (Day 4); any later day can reuse it with other choices.

var chosen := ""
var _account_buttons: Dictionary = {} # account id -> Button
var _detail: Label
var _disable: Button
var _talk: VBoxContainer
var _talk_buttons: Dictionary = {}
var _disabled_done := false


func setup_task() -> void:
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("heading", ""))
	body.add_child(heading)
	var group := ButtonGroup.new()
	# Many choices (the files of Day 5) wrap onto a second line instead of making the panel wider.
	var row: Container = HFlowContainer.new() if content.get("accounts", []).size() > 4 else HBoxContainer.new()
	body.add_child(row)
	for account: Dictionary in content.get("accounts", []):
		var button := Button.new()
		button.toggle_mode = true
		button.button_group = group
		button.text = str(account["label"])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_choose_account.bind(str(account["id"])))
		row.add_child(button)
		_account_buttons[str(account["id"])] = button
	_detail = Label.new()
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(0, 26)
	body.add_child(_detail)
	_disable = Button.new()
	_disable.text = str(content.get("disable", "DISABLE ACCOUNT"))
	_disable.pressed.connect(_disable_pressed)
	body.add_child(_disable)
	_talk = VBoxContainer.new()
	body.add_child(_talk)
	var talk_heading := Label.new()
	talk_heading.theme_type_variation = &"RecoveryAccent"
	talk_heading.text = str(content.get("talk_heading", ""))
	_talk.add_child(talk_heading)
	for option: Dictionary in content.get("talk", []):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = str(option["label"])
		button.pressed.connect(_talk_pressed.bind(str(option["id"])))
		_talk.add_child(button)
		_talk_buttons[str(option["id"])] = button


func reset_state() -> void:
	chosen = ""
	_disabled_done = false
	for button: Button in _account_buttons.values():
		button.set_pressed_no_signal(false)
		button.disabled = false
	_detail.text = str(content.get("choose", ""))
	_disable.disabled = false
	_talk.hide()
	set_feedback(str(content.get("pick", "")))


func _find(list_key: String, id: String) -> Dictionary:
	for entry: Dictionary in content.get(list_key, []):
		if str(entry["id"]) == id:
			return entry
	return {}


func _choose_account(id: String) -> void:
	if solved or _disabled_done:
		return
	chosen = id
	_detail.text = str(_find("accounts", id).get("detail", ""))


func _disable_pressed() -> void:
	if solved or _disabled_done:
		return
	if chosen.is_empty():
		set_feedback(str(content.get("select_first", "")))
		return
	var account := _find("accounts", chosen)
	if not account.get("ok", false):
		note_mistake(str(account.get("reason", "")))
		return
	_disabled_done = true
	_disable.disabled = true
	for button: Button in _account_buttons.values():
		button.disabled = true
	_talk.show()
	set_feedback(str(content.get("disabled", "")), "good")


func _talk_pressed(id: String) -> void:
	if solved or not _disabled_done:
		return
	var option := _find("talk", id)
	if not option.get("ok", false):
		note_mistake(str(option.get("reason", "")))
		return
	succeed()
