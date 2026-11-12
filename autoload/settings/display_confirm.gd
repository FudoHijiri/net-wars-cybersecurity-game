class_name DisplayConfirm
extends Control
## "Is this correct for you?": the panel that comes up after the window size or mode was changed, with a
## countdown. The player chooses It's Good (keep it) or Go Back. When the time runs out it goes back by
## itself, so a player who cannot see the new window (a size the screen does not show well) is never stuck.
## Escape also means Go Back, and Go Back has the focus, so Enter does not keep a display by accident.
## answered(keep) is emitted once; the one who made the panel frees it.

signal answered(keep: bool)

const PANEL := preload("res://assets/ui/Panel.png")
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const SECONDS := 10
const SIZE := Vector2(340, 96)
const BUTTON_SIZE := Vector2(72, 20)
const BUTTON_GAP := 32.0 # the room between the two buttons, as on the Quit panel of the title menu

var _left := float(SECONDS)
var _countdown: Label
var _keep: Button
var _back: Button
var _done := false


## `button_theme` is the look of the two buttons.
func setup(button_theme: Theme) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # the pause menu pauses the game while Settings is open
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP # nothing behind the panel can be clicked

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var frame := NinePatchRect.new()
	frame.texture = PANEL
	frame.region_rect = Rect2(0, 0, 33, 33)
	for side in ["left", "top", "right", "bottom"]:
		frame.set("patch_margin_" + side, 11)
	frame.size = SIZE
	frame.position = (Vector2(640, 360) - SIZE) / 2.0
	add_child(frame)

	var title := _label("IS THIS CORRECT FOR YOU?", BOLD, 12)
	title.position = Vector2(0, 14)
	title.size = Vector2(SIZE.x, 16)
	frame.add_child(title)

	_countdown = _label("", FONT, 6)
	_countdown.position = Vector2(0, 38)
	_countdown.size = Vector2(SIZE.x, 10)
	frame.add_child(_countdown)

	_keep = _button("IT'S GOOD", button_theme)
	_keep.position = Vector2(SIZE.x / 2.0 - BUTTON_GAP / 2.0 - BUTTON_SIZE.x, 56)
	_keep.pressed.connect(_answer.bind(true))
	frame.add_child(_keep)

	_back = _button("GO BACK", button_theme)
	_back.position = Vector2(SIZE.x / 2.0 + BUTTON_GAP / 2.0, 56)
	_back.pressed.connect(_answer.bind(false))
	frame.add_child(_back)

	_show_time()


func _ready() -> void:
	# Only now, with the theme in use: a size given earlier would be the (larger) size of the text in the
	# default theme, and a Button never shrinks by itself.
	for button in [_keep, _back]:
		button.size = BUTTON_SIZE
	_back.grab_focus()


func _process(delta: float) -> void:
	if _done:
		return
	_left -= delta
	if _left <= 0.0:
		_answer(false)
		return
	_show_time()


func _input(event: InputEvent) -> void:
	if not _done and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)


func _show_time() -> void:
	var seconds := ceili(_left)
	_countdown.text = "Going back in %d second%s if you do nothing." % [seconds, "" if seconds == 1 else "s"]


func _answer(keep: bool) -> void:
	if _done:
		return
	_done = true
	answered.emit(keep)


func _label(text: String, font: Font, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _button(text: String, button_theme: Theme) -> Button:
	var button := Button.new()
	button.text = text
	button.theme = button_theme
	return button
