class_name MonologueBox
extends Control

## The player character thinking out loud: one or two short lines in a box at the bottom of the
## screen. Click anywhere, or press Enter on the CONTINUE button, to go on; the first press while
## a line is still appearing shows the whole line. Reduce Screen Effects shows lines at once.
## All words come from the caller: configure() once, then play().

signal finished

const CHARS_PER_SECOND := 55.0
const MAX_TYPING_SECONDS := 1.4

var _lines: Array[String] = []
var _index := 0
var _typing: Tween
var _return_focus: Control # whatever had keyboard focus when the monologue began

@onready var _dim: ColorRect = %Dim
@onready var _box: PanelContainer = %Box
@onready var _speaker: Label = %Speaker
@onready var _text: RichTextLabel = %Text
@onready var _hint: Label = %Hint
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	hide()
	_continue_button.pressed.connect(advance)
	_dim.gui_input.connect(_on_background_input)
	_box.gui_input.connect(_on_background_input)
	# Keyboard focus stays on the CONTINUE button while this is open: the screen behind is paused
	# in spirit, and Tab or the arrows must not wander off to buttons the player cannot see.
	var self_path := _continue_button.get_path()
	_continue_button.focus_neighbor_left = self_path
	_continue_button.focus_neighbor_right = self_path
	_continue_button.focus_neighbor_top = self_path
	_continue_button.focus_neighbor_bottom = self_path
	_continue_button.focus_next = self_path
	_continue_button.focus_previous = self_path


func configure(speaker: String, hint: String, continue_text: String) -> void:
	_speaker.text = speaker
	_hint.text = hint
	_continue_button.text = continue_text


func is_playing() -> bool:
	return visible


## Shows the lines one after the other, then emits `finished`.
func play(lines: Array) -> void:
	_lines.clear()
	for line in lines:
		if not str(line).is_empty():
			_lines.append(str(line))
	if _lines.is_empty():
		finished.emit()
		return
	if not visible:
		_return_focus = get_viewport().gui_get_focus_owner()
	_index = 0
	show()
	_show_line()
	_continue_button.grab_focus()


## The next line (or the rest of this one, while it is still appearing).
func advance() -> void:
	if not visible:
		return
	if _typing != null and _typing.is_running():
		_typing.kill()
		_text.visible_ratio = 1.0
		return
	if _index + 1 < _lines.size():
		_index += 1
		_show_line()
	else:
		_close()


func _show_line() -> void:
	_text.text = _lines[_index]
	if _typing != null:
		_typing.kill()
	if ScreenEffects.reduce_effects or _text.get_total_character_count() == 0:
		_text.visible_ratio = 1.0
		return
	_text.visible_ratio = 0.0
	var seconds := minf(_text.get_total_character_count() / CHARS_PER_SECOND, MAX_TYPING_SECONDS)
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, seconds)


func _close() -> void:
	if _typing != null:
		_typing.kill()
	hide()
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	_return_focus = null
	finished.emit()


func _on_background_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()
