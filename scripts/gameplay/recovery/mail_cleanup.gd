extends RecoveryTask

## Clean up after a phishing email, in three stages the player works on:
##   1. THE INBOXES: tick every copy of the fake (also the one that was moved to the archive) and press DELETE. The real notices
##      sit in the same inboxes and look just as official: deleting one bounces back with its reason. A copy left behind is
##      named (whose inbox) when DELETE is pressed.
##   2. THE FILTER: build a rule, "block mail where [what] is [this]". Only the sender's domain is c0mpany-it.com is right: the
##      subject or the word "password" would block the real reminder too, and company-it.com would block the real IT.
##   3. THE WARNING: choose the message for the staff: calm and specific, scary and vague, or none.
## Layout: MailCleanup.tscn (everything is built here). content: {inboxes: [{id, owner, messages: [{id, from, subject, fake,
## reason}]}], rule: {what: [{id, label, reason}], values: [{id, label, reason}], right: {what, value}}, warnings: [{id, label,
## ok, reason}], delete, block, stage_inboxes, stage_rule, stage_warning, left_behind, rule_pick, ...}.

var stage := 1
var deleted: Dictionary = {} # message id -> true
var _ticks: Dictionary = {} # message id -> CheckBox
var _rows: Dictionary = {} # message id -> the row
var _caption: Label
var _stage_inboxes: HBoxContainer
var _stage_rule: VBoxContainer
var _stage_warning: VBoxContainer
var _delete_button: Button
var _what_buttons: Dictionary = {}
var _value_buttons: Dictionary = {}
var _block_button: Button
var _what := ""
var _value := ""
var _rule_label: Label
var _warning_buttons: Dictionary = {}
var _glow_tween: Tween
var _glowing: Control


func setup_task() -> void:
	_caption = Label.new()
	_caption.theme_type_variation = &"RecoveryAccent"
	body.add_child(_caption)
	_stage_inboxes = HBoxContainer.new()
	_stage_inboxes.add_theme_constant_override("separation", 6)
	body.add_child(_stage_inboxes)
	for inbox: Dictionary in content.get("inboxes", []):
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stage_inboxes.add_child(column)
		var owner_label := Label.new()
		owner_label.theme_type_variation = &"RecoveryMuted"
		owner_label.text = str(inbox["owner"])
		column.add_child(owner_label)
		for message: Dictionary in inbox.get("messages", []):
			var row := VBoxContainer.new()
			row.add_theme_constant_override("separation", 0)
			column.add_child(row)
			var tick := CheckBox.new()
			tick.text = str(message["from"])
			tick.focus_mode = Control.FOCUS_ALL
			row.add_child(tick)
			var subject := Label.new()
			subject.text = "   " + str(message["subject"])
			subject.theme_type_variation = &"RecoveryMuted"
			row.add_child(subject)
			_ticks[str(message["id"])] = tick
			_rows[str(message["id"])] = row
	_delete_button = Button.new()
	_delete_button.text = str(content.get("delete", "DELETE THE TICKED MESSAGES"))
	_delete_button.pressed.connect(delete_pressed)
	body.add_child(_delete_button)
	_build_rule()
	_build_warning()


func _build_rule() -> void:
	var rule: Dictionary = content.get("rule", {})
	_stage_rule = VBoxContainer.new()
	body.add_child(_stage_rule)
	var what_row := HFlowContainer.new()
	_stage_rule.add_child(what_row)
	var what_label := Label.new()
	what_label.text = str(rule.get("what_label", "Block mail where the"))
	what_row.add_child(what_label)
	for option: Dictionary in rule.get("what", []):
		var button := Button.new()
		button.toggle_mode = true
		button.text = str(option["label"])
		button.pressed.connect(pick_what.bind(str(option["id"])))
		what_row.add_child(button)
		_what_buttons[str(option["id"])] = button
	var value_row := HFlowContainer.new()
	_stage_rule.add_child(value_row)
	var value_label := Label.new()
	value_label.text = str(rule.get("value_label", "is"))
	value_row.add_child(value_label)
	for option: Dictionary in rule.get("values", []):
		var button := Button.new()
		button.toggle_mode = true
		button.text = str(option["label"])
		button.pressed.connect(pick_value.bind(str(option["id"])))
		value_row.add_child(button)
		_value_buttons[str(option["id"])] = button
	_rule_label = Label.new()
	_rule_label.theme_type_variation = &"RecoveryMuted"
	_stage_rule.add_child(_rule_label)
	_block_button = Button.new()
	_block_button.text = str(content.get("block", "SAVE THE FILTER"))
	_block_button.pressed.connect(block_pressed)
	_stage_rule.add_child(_block_button)


func _build_warning() -> void:
	_stage_warning = VBoxContainer.new()
	body.add_child(_stage_warning)
	for option: Dictionary in content.get("warnings", []):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = str(option["label"])
		button.pressed.connect(warn_pressed.bind(str(option["id"])))
		_stage_warning.add_child(button)
		_warning_buttons[str(option["id"])] = button


func reset_state() -> void:
	stage = 1
	deleted.clear()
	_what = ""
	_value = ""
	for id: String in _ticks:
		_rows[id].show()
		_ticks[id].set_pressed_no_signal(false)
	for button: Button in _what_buttons.values():
		button.set_pressed_no_signal(false)
	for button: Button in _value_buttons.values():
		button.set_pressed_no_signal(false)
	_show_stage()
	set_feedback(str(content.get("pick", "")))


func _show_stage() -> void:
	_stage_inboxes.visible = stage == 1
	_delete_button.visible = stage == 1
	_stage_rule.visible = stage == 2
	_stage_warning.visible = stage == 3
	_caption.text = str(content.get(["", "stage_inboxes", "stage_rule", "stage_warning"][stage], ""))
	_update_rule_text()
	_glow([null, _delete_button, _block_button, null][stage])


func _glow(target: Control) -> void:
	if _glow_tween:
		_glow_tween.kill()
	if is_instance_valid(_glowing):
		_glowing.modulate = Color.WHITE
	_glowing = target
	if target == null or not is_inside_tree():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(target, "modulate", Color(1.5, 1.4, 0.85), 0.45)
	_glow_tween.tween_property(target, "modulate", Color.WHITE, 0.45)


func _message(id: String) -> Dictionary:
	for inbox: Dictionary in content.get("inboxes", []):
		for message: Dictionary in inbox.get("messages", []):
			if str(message["id"]) == id:
				return message
	return {}


## Stage 1: tick a message (the tests call this; a click on the box does the same).
func select(id: String, on: bool) -> void:
	if _ticks.has(id) and not deleted.has(id):
		_ticks[id].button_pressed = on


func delete_pressed() -> void:
	if solved or stage != 1:
		return
	var picked: Array[String] = []
	for id: String in _ticks:
		if not deleted.has(id) and _ticks[id].button_pressed:
			picked.append(id)
	if picked.is_empty():
		set_feedback(str(content.get("tick_first", "")))
		return
	for id in picked:
		var message := _message(id)
		if not message.get("fake", false):
			_ticks[id].set_pressed_no_signal(false)
			note_mistake(str(message.get("reason", "")))
			return
	for id in picked:
		deleted[id] = true
		_rows[id].hide()
	for inbox: Dictionary in content.get("inboxes", []):
		for message: Dictionary in inbox.get("messages", []):
			if message.get("fake", false) and not deleted.has(str(message["id"])):
				set_feedback(str(content.get("left_behind", "")).format({"owner": inbox["owner"]}))
				return
	stage = 2
	set_feedback(str(content.get("inboxes_done", "")), "good")
	_show_stage()


# --- stage 2: the filter ---

func pick_what(id: String) -> void:
	if solved or stage != 2:
		return
	_what = id
	for key: String in _what_buttons:
		_what_buttons[key].set_pressed_no_signal(key == id)
	_update_rule_text()


func pick_value(id: String) -> void:
	if solved or stage != 2:
		return
	_value = id
	for key: String in _value_buttons:
		_value_buttons[key].set_pressed_no_signal(key == id)
	_update_rule_text()


func _update_rule_text() -> void:
	var rule: Dictionary = content.get("rule", {})
	var what_label := str(_option(rule.get("what", []), _what).get("label", "..."))
	var value_label := str(_option(rule.get("values", []), _value).get("label", "..."))
	_rule_label.text = str(content.get("rule_text", "Rule: block mail where the %s is %s")) % [what_label, value_label]


func _option(list: Array, id: String) -> Dictionary:
	for entry: Dictionary in list:
		if str(entry["id"]) == id:
			return entry
	return {}


func block_pressed() -> void:
	if solved or stage != 2:
		return
	var rule: Dictionary = content.get("rule", {})
	if _what.is_empty() or _value.is_empty():
		set_feedback(str(content.get("rule_pick", "")))
		return
	var right: Dictionary = rule.get("right", {})
	if _what != str(right.get("what", "")):
		note_mistake(str(_option(rule.get("what", []), _what).get("reason", "")))
		return
	if _value != str(right.get("value", "")):
		note_mistake(str(_option(rule.get("values", []), _value).get("reason", "")))
		return
	stage = 3
	set_feedback(str(content.get("rule_done", "")), "good")
	_show_stage()


# --- stage 3: the warning ---

func warn_pressed(id: String) -> void:
	if solved or stage != 3:
		return
	var option := _option(content.get("warnings", []), id)
	if not option.get("ok", false):
		note_mistake(str(option.get("reason", "")))
		return
	succeed()
