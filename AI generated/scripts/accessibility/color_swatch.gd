class_name ColorSwatch
extends Control
## One small square of a color in Settings > Custom Colors. Click it, or focus it and press accept, to
## choose that color. The chosen one has a white frame, so it is not only told by its color. It is a
## plain Control (not a Button), so the Interface Colors setting leaves it alone.

signal picked

const SQUARE := Vector2(13, 13)
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)

var color := Color.WHITE:
	set(value):
		color = value
		queue_redraw()
var selected := false:
	set(value):
		selected = value
		queue_redraw()

var _pointed := false


func _init() -> void:
	custom_minimum_size = SQUARE
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	mouse_entered.connect(_set_pointed.bind(true))
	mouse_exited.connect(_set_pointed.bind(false))
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _gui_input(event: InputEvent) -> void:
	var click := false
	if event is InputEventMouseButton:
		click = (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		picked.emit()
		accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), color)
	if selected:
		draw_rect(Rect2(Vector2(-1, -1), size + Vector2(2, 2)), Color.WHITE, false, 1.0)
	if _pointed or has_focus():
		draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), GameColors.highlight, false, 1.0)


func _set_pointed(value: bool) -> void:
	_pointed = value
	queue_redraw()
