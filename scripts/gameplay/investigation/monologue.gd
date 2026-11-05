class_name Monologue
extends CanvasLayer

## A few lines in the bottom text box over a dimmed Investigation.
## Usage: monologue.play(["First line.", "Second line."], "Name"), then await monologue.finished.
##
## Each line fades in. A click (left mouse button, anywhere on the screen), Space or Enter
## first completes the fade; the next one shows the next line.

signal finished

# The nodes copied from Dialogue.tscn's Base layer sit directly under this CanvasLayer.
@onready var _name_box: Control = $NameContainer
@onready var _name: Label = $NameContainer/MarginContainer/Name
@onready var _text: RichTextLabel = $Panel/Text
@onready var _skip_button: Button = $SkipButton

var _lines: Array = []
var _index := 0
var _fade: FadeText


func _ready() -> void:
	_fade = FadeText.new(_text)
	_skip_button.pressed.connect(_close)
	_set_open(false)


## Shows the lines one by one. The speaker box is hidden when `speaker` is empty.
func play(lines: Array, speaker: String = "") -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines
	_index = 0
	_name.text = speaker
	_name_box.visible = not speaker.is_empty()
	_set_open(true)
	_show_line()


func is_open() -> bool:
	return visible


func _input(event: InputEvent) -> void:
	if not is_open():
		return
	# Handled here, before the GUI, so a click on the text panel counts too and
	# Space/Enter never also presses a button underneath.
	var pressed := event.is_action_pressed("ui_accept")
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pressed = not _skip_button.get_global_rect().has_point(click.position) # Skip does its own thing
	if pressed:
		get_viewport().set_input_as_handled()
		if _fade.press():
			_advance()


func _show_line() -> void:
	_fade.show_text(str(_lines[_index]))


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	if not is_open():
		return
	_set_open(false)
	finished.emit()


func _set_open(value: bool) -> void:
	if not value:
		_fade.finish()
	visible = value # hides every child of the CanvasLayer
	set_process_input(value)
