class_name TutorialOverlay
extends CanvasLayer
## A step-by-step tutorial on top of a phase: the screen dims, the control being explained is lit, and a
## panel says what it is for. A click, Space or Enter goes to the next step; SKIP ends it. The game is paused
## while it runs. Steps are {"text": ..., "target": ...}: the target is a node path from the scene, or
## "%Name" for a node found by name, or empty for a step with nothing to point at.

signal finished

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)
const GOLD := Color(1, 0.8039216, 0.45882353, 1)
const LIGHT := Color(0.95686275, 0.95686275, 0.95686275, 1)
const DIM := Color(0, 0, 0, 0.72)
const SCREEN := Vector2(640, 360)
const PANEL_WIDTH := 252.0
const MARGIN := 8.0

var _steps: Array = []
var _scene: Node
var _step := 0
var _target := Rect2() # the lit area of this step, empty when there is none
var _dim: Control
var _panel: PanelContainer
var _text: Label
var _counter: Label
var _next: Button


## Starts the tutorial of `scene` with these steps.
func play(steps: Array, scene: Node) -> void:
	_steps = steps
	_scene = scene
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	get_tree().paused = true
	_show_step()


func _build() -> void:
	_dim = Control.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.draw.connect(_draw_dim)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = INK
	style.set_border_width_all(1)
	style.border_color = GOLD
	style.set_content_margin_all(6)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size.x = PANEL_WIDTH
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE # a click on the text goes on, like a click anywhere
	add_child(_panel)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_text = _label(LIGHT)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = PANEL_WIDTH - 12.0
	box.add_child(_text)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	_counter = _label(GOLD)
	_counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_counter)
	var skip := _button("SKIP")
	skip.pressed.connect(_end)
	row.add_child(skip)
	_next = _button("NEXT")
	_next.pressed.connect(_advance)
	row.add_child(_next)


func _label(color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 6)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	for state in ["normal", "hover", "pressed"]:
		var style := StyleBoxFlat.new()
		style.bg_color = GOLD if state != "hover" else LIGHT
		style.set_content_margin_all(3)
		button.add_theme_stylebox_override(state, style)
	return button


func _show_step() -> void:
	var step: Dictionary = _steps[_step]
	_text.text = str(step.get("text", ""))
	_counter.text = "%d / %d" % [_step + 1, _steps.size()]
	_next.text = "DONE" if _step == _steps.size() - 1 else "NEXT"
	_target = _target_rect(str(step.get("target", "")))
	_panel.reset_size()
	_panel.position = _panel_position(_panel.get_combined_minimum_size())
	_dim.queue_redraw()


## The screen rectangle of a step's target, or an empty one when it has none (or it is not on screen).
func _target_rect(path: String) -> Rect2:
	if path.is_empty():
		return Rect2()
	var node: Node = _scene.find_child(path.trim_prefix("%"), true, false) if path.begins_with("%") else _scene.get_node_or_null(path)
	var control := node as Control
	if control == null or not control.is_visible_in_tree() or control.size.x < 2.0 or control.size.y < 2.0:
		return Rect2()
	return control.get_global_rect()


## The panel goes beside the lit area (below, above, to the right, then to the left: the first side where it
## fits) and in the middle when nothing is lit.
func _panel_position(size: Vector2) -> Vector2:
	if _target.size == Vector2.ZERO:
		return ((SCREEN - size) / 2.0).floor()
	var lit := _target.grow(3.0)
	var x := clampf(lit.get_center().x - size.x / 2.0, MARGIN, SCREEN.x - size.x - MARGIN)
	var y := clampf(lit.get_center().y - size.y / 2.0, MARGIN, SCREEN.y - size.y - MARGIN)
	var spots := [
		Vector2(x, lit.end.y + 6.0),
		Vector2(x, lit.position.y - size.y - 6.0),
		Vector2(lit.end.x + 6.0, y),
		Vector2(lit.position.x - size.x - 6.0, y),
	]
	var room := Rect2(Vector2.ONE * MARGIN, SCREEN - Vector2.ONE * MARGIN * 2.0)
	for spot: Vector2 in spots:
		if room.encloses(Rect2(spot, size)):
			return spot.floor()
	# The lit area is nearly the whole screen: use the corner farthest from its middle.
	var corner_x := MARGIN if lit.get_center().x > SCREEN.x / 2.0 else SCREEN.x - size.x - MARGIN
	var corner_y := MARGIN if lit.get_center().y > SCREEN.y / 2.0 else SCREEN.y - size.y - MARGIN
	return Vector2(corner_x, corner_y)


func _draw_dim() -> void:
	var full := Rect2(Vector2.ZERO, _dim.size)
	if _target.size == Vector2.ZERO:
		_dim.draw_rect(full, DIM)
		return
	var lit := _target.grow(3.0).intersection(full)
	_dim.draw_rect(Rect2(0, 0, full.size.x, lit.position.y), DIM)
	_dim.draw_rect(Rect2(0, lit.end.y, full.size.x, full.size.y - lit.end.y), DIM)
	_dim.draw_rect(Rect2(0, lit.position.y, lit.position.x, lit.size.y), DIM)
	_dim.draw_rect(Rect2(lit.end.x, lit.position.y, full.size.x - lit.end.x, lit.size.y), DIM)
	_dim.draw_rect(lit, GOLD, false, 1.0)


func _on_dim_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_advance()


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_advance()


func _advance() -> void:
	_step += 1
	if _step >= _steps.size():
		_end()
	else:
		_show_step()


func _end() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()
