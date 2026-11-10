extends RecoveryTask

## Troubleshoot a laptop that crashes at start (the Blue Screen). Layout: FixBlueScreen.tscn (the controls are
## built here, from content.steps). The blue screen sits on top and changes with the step: the crash,
## the boot menu, Safe Mode and, when it is fixed, the desktop.
## Step types: "choice" (a question with options; an option with "right": true moves on, a wrong one
## explains why) and "remove" (a list of programs; remove every one marked "bad": true, keep the rest).
## content.screen: {title, lines[], code, safe_title, safe_lines[], fixed_title, fixed_lines[]}.

const BLUE := Color("1f4fa8")
const BLUE_SAFE := Color("101a2c")
const GREEN_DESKTOP := Color("1f6b4a")

var step_index := 0
var removed: Array[String] = []
var option_buttons: Array[Button] = []
var _screen: PanelContainer
var _screen_title: Label
var _screen_text: Label
var _question: Label
var _options: GridContainer
var _style: StyleBoxFlat


func setup_task() -> void:
	_style = StyleBoxFlat.new()
	_style.set_content_margin_all(6)
	_style.set_border_width_all(1)
	_style.border_color = RecoveryStyle.LIGHT
	_screen = PanelContainer.new()
	_screen.add_theme_stylebox_override("panel", _style)
	_screen.custom_minimum_size = Vector2(0, 52)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	_screen.add_child(box)
	_screen_title = Label.new()
	_screen_title.theme_type_variation = &"RecoveryHeading"
	box.add_child(_screen_title)
	_screen_text = Label.new()
	_screen_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_screen_text)
	body.add_child(_screen)
	_question = Label.new()
	_question.theme_type_variation = &"RecoveryAccent"
	_question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_question)
	_options = GridContainer.new()
	_options.columns = 1
	_options.add_theme_constant_override("v_separation", 3)
	_options.add_theme_constant_override("h_separation", 4)
	body.add_child(_options)


func reset_state() -> void:
	step_index = 0
	removed.clear()
	_show_screen("crash")
	_show_step()


func _steps() -> Array:
	return content.get("steps", [])


## kind: "crash", "safe" or "fixed". The look of the screen follows it.
func _show_screen(kind: String) -> void:
	var screen: Dictionary = content.get("screen", {})
	var lines: Array = screen.get(kind + "_lines", screen.get("lines", []))
	_style.bg_color = {"crash": BLUE, "safe": BLUE_SAFE, "fixed": GREEN_DESKTOP}[kind]
	_screen_title.text = str(screen.get(kind + "_title", screen.get("title", "")))
	_screen_text.text = "\n".join(lines)
	UiFx.flash(_screen, Color(1, 1, 1, 1), 0.2)


func _show_step(keep_feedback := false) -> void:
	for button in option_buttons:
		button.queue_free()
	option_buttons.clear()
	var step: Dictionary = _steps()[step_index]
	_question.text = str(step.get("question", ""))
	_options.columns = int(step.get("columns", 1))
	if str(step.get("type", "choice")) == "remove":
		for item: Dictionary in step.get("items", []):
			var id := str(item["id"])
			var button := _add_option("%s   %s" % [item["label"], item.get("detail", "")])
			button.pressed.connect(_remove.bind(id, button))
	else:
		var options: Array = step.get("options", [])
		for i in options.size():
			var button := _add_option(str(options[i]["label"]))
			button.pressed.connect(_choose.bind(i))
	if not keep_feedback:
		set_feedback(str(step.get("hint", content.get("pick", ""))))
	UiFx.stagger_fade(option_buttons)
	RecoveryStyle.focus_loop(self)


func _add_option(text: String) -> Button:
	var button := Button.new()
	button.theme_type_variation = &"RecoveryCard"
	button.text = text
	button.custom_minimum_size = Vector2(0, 20)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_options.add_child(button)
	option_buttons.append(button)
	return button


func _choose(index: int) -> void:
	if solved:
		return
	var option: Dictionary = _steps()[step_index]["options"][index]
	if not option.get("right", false):
		UiFx.shake(option_buttons[index])
		note_mistake(str(option.get("reason", "")))
		return
	set_feedback(str(option.get("reason", "")), "good")
	UiFx.pop(option_buttons[index])
	if option.has("screen"):
		_show_screen(str(option["screen"]))
	_next_step(option.get("finish", false))


func _remove(id: String, button: Button) -> void:
	if solved or removed.has(id):
		return
	var item: Dictionary = {}
	for candidate: Dictionary in _steps()[step_index].get("items", []):
		if str(candidate["id"]) == id:
			item = candidate
	if not item.get("bad", false):
		UiFx.shake(button)
		note_mistake(str(item.get("reason", "")))
		return
	removed.append(id)
	button.text = str(content.get("removed", "[OK] REMOVED"))
	button.disabled = true
	button.theme_type_variation = &"RecoveryCardGood"
	UiFx.pop(button)
	set_feedback(str(item.get("reason", "")), "good")
	if _bad_left() == 0:
		_next_step(false)


func _bad_left() -> int:
	var left := 0
	for item: Dictionary in _steps()[step_index].get("items", []):
		if item.get("bad", false) and not removed.has(str(item["id"])):
			left += 1
	return left


func _next_step(finish: bool) -> void:
	if finish or step_index + 1 >= _steps().size():
		succeed()
		return
	step_index += 1
	_show_step_after_pause.call_deferred()


func _show_step_after_pause() -> void:
	var step: Dictionary = _steps()[step_index]
	if step.has("screen"):
		_show_screen(str(step["screen"]))
	_show_step(true)
