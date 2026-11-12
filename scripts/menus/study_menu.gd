class_name StudyMenu
extends Control
## The small "Study" button at the bottom edge of the day select (the same place and look as Credits in the title menu).
## It opens a little pop-up with the three parts of the study (the pre-test, the post-test and the feedback form), each
## with what is done and what is not, and Close. A part that is due can be opened from here; the Day 8 ending opens the
## post-test by itself. The button is not there once all three are done.

const FONT := preload("res://assets/font/Press Start 8p/PressStart2P.ttf")
const BACK := Color(0.101960786, 0.10980392, 0.17254902)
const LINE := Color(0.3372549, 0.42352942, 0.5254902)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275)
const MUTED := Color(0.45, 0.52, 0.62)

var _button: Button
var _popup: PanelContainer
var _rows: Dictionary = {} # "pre" / "post" / "feedback" -> its button
var _style_source: Button # the Credits button of the title menu, when there is one: the same styles


## `credits` is the Credits button of the title menu (its place and look are copied); it may be null.
func setup(credits: Button) -> void:
	_style_source = credits
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button = Button.new()
	_button.name = "StudyButton"
	_button.text = "Study"
	_button.tooltip_text = "The pre-test, the post-test and the feedback form of the study."
	_button.toggle_mode = true
	_style(_button)
	_button.position = Vector2(4, 339)
	_button.size = Vector2(62, 17) # after the styles: the size it had with the default look must not stay
	_button.toggled.connect(_on_toggled)
	add_child(_button)
	_button.size = Vector2(62, 17) # once it is in the tree: its look and the theme above it are known by then

	_popup = PanelContainer.new()
	_popup.name = "StudyPopup"
	_popup.top_level = true # over the day select, in screen coordinates
	_popup.z_index = 100
	_popup.add_theme_stylebox_override("panel", _box(BACK, LINE, 4))
	_popup.hide()
	add_child(_popup)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	_popup.add_child(column)
	for part: Array in [["pre", "Pre-test"], ["post", "Post-test"], ["feedback", "Feedback"]]:
		var row := _item(str(part[1]))
		row.name = "Open%s" % str(part[0]).capitalize()
		row.pressed.connect(_open)
		column.add_child(row)
		_rows[part[0]] = row
	var close := _item("Close")
	close.name = "CloseStudyButton"
	close.pressed.connect(func() -> void: _button.button_pressed = false)
	column.add_child(close)
	refresh()


## Shows or hides the button, and tells each part whether it is done, due, or not yet.
func refresh() -> void:
	if _button == null:
		return
	_button.visible = Assessment.needs_more()
	if not _button.visible:
		_button.button_pressed = false
	_set_row("pre", "Pre-test", not Assessment.needs_pre(), Assessment.needs_pre())
	var post_done: bool = not Assessment.record().get("post", {}).is_empty()
	_set_row("post", "Post-test", post_done, Assessment.needs_post())
	var feedback_done: bool = not Assessment.record().get("feedback", {}).is_empty()
	_set_row("feedback", "Feedback", feedback_done, Assessment.needs_feedback())


func _set_row(part: String, label: String, done: bool, due: bool) -> void:
	var row: Button = _rows[part]
	row.disabled = not due
	row.text = "%s - done" % label if done else (label if due else "%s - later" % label)
	row.tooltip_text = "" if due else ("Already answered." if done else "It comes after the previous part.")


func _open() -> void:
	_button.button_pressed = false
	SceneManager.load_scene(Assessment.SCENE_PATH)


func _on_toggled(open: bool) -> void:
	if open:
		_popup.show()
		_popup.reset_size()
		_popup.global_position = Vector2(_button.global_position.x, _button.global_position.y - _popup.size.y - 2.0)
	else:
		_popup.hide()


## A click outside the pop-up (and not on the button) closes it; Escape closes it too.
func _input(event: InputEvent) -> void:
	if _popup == null or not _popup.visible:
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		var where := get_global_mouse_position()
		if not _popup.get_global_rect().has_point(where) and not _button.get_global_rect().has_point(where):
			_button.button_pressed = false
	elif event.is_action_pressed(&"ui_cancel"):
		_button.button_pressed = false
		get_viewport().set_input_as_handled()


func _item(text: String) -> Button:
	var item := Button.new()
	item.text = text
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_style(item)
	item.custom_minimum_size = Vector2(150, 17)
	item.size = item.custom_minimum_size
	item.add_theme_color_override("font_disabled_color", MUTED)
	return item


## The look of the Credits button of the title menu (or a plain version when it is not there).
func _style(button: Button) -> void:
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_color_override("font_color", TEXT)
	for state in ["normal", "hover", "pressed", "focus"]:
		if _style_source != null:
			button.add_theme_stylebox_override(state, _style_source.get_theme_stylebox(state))
		else:
			button.add_theme_stylebox_override(state, _box(BACK, LINE, 2))
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	button.add_theme_stylebox_override("disabled", _box(BACK, Color(0.2, 0.23, 0.32), 2))


static func _box(fill: Color, border: Color, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(1)
	style.border_color = border
	style.set_content_margin_all(margin)
	return style
