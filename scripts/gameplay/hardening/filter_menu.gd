class_name FilterMenu
extends Button
## One FILTER button for a list, with the filters of the list in a small panel that opens under it. The filters are
## the buttons and the drop-downs the list already has: they are moved into the panel, so the list reads them as it
## always did. A badge on the button says how many filters are on ("FILTER 2"). CLEAR turns them all off, DONE (a click
## outside, or Escape) closes the panel.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BACK := Color(0.101960786, 0.10980392, 0.17254902)
const LINE := Color(0.3372549, 0.42352942, 0.5254902)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275)
const MUTED := Color(0.58, 0.69, 0.76)
const GOLD := Color(1, 0.8039216, 0.45882353)

var _popup: PanelContainer
var _toggles: Array[Button] = []
var _dropdowns: Array[OptionButton] = []


## groups: [{"title": "Type", "controls": [filter controls]}]. Controls that are not visible (a list too short to
## need filters) are left out; with none left there is no button (returns null). `at` is where the button goes
## (screen coordinates).
static func make(parent: Control, at: Vector2, groups: Array[Dictionary]) -> FilterMenu:
	var kept: Array[Dictionary] = []
	for group in groups:
		var controls: Array[Control] = []
		for control: Control in group["controls"]:
			if control.visible:
				controls.append(control)
		if not controls.is_empty():
			kept.append({"title": group["title"], "controls": controls})
	if kept.is_empty():
		return null
	var menu := FilterMenu.new()
	menu.name = "FilterMenu"
	parent.add_child(menu)
	menu.global_position = at
	menu._build(kept)
	return menu


func _build(groups: Array[Dictionary]) -> void:
	text = "FILTER"
	focus_mode = Control.FOCUS_ALL
	add_theme_font_override("font", FONT)
	add_theme_font_size_override("font_size", 6)
	add_theme_stylebox_override("normal", _box(BACK, LINE))
	add_theme_stylebox_override("hover", _box(Color(0.17, 0.19, 0.28), TEXT))
	add_theme_stylebox_override("pressed", _box(Color(0.17, 0.19, 0.28), GOLD))
	add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), GOLD))
	add_theme_color_override("font_color", TEXT)
	add_theme_color_override("font_hover_color", TEXT)
	add_theme_color_override("font_pressed_color", GOLD)
	toggle_mode = true
	toggled.connect(_on_toggled)
	custom_minimum_size = Vector2(52, 14)
	size = custom_minimum_size # after the styles: the size it had with the default look must not stay

	_popup = PanelContainer.new()
	_popup.top_level = true # over everything, in screen coordinates
	_popup.z_index = 150
	_popup.add_theme_stylebox_override("panel", _box(BACK, GOLD, 5))
	_popup.hide()
	add_child(_popup)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	_popup.add_child(column)
	for group in groups:
		var heading := Label.new()
		heading.text = str(group["title"]).to_upper()
		heading.add_theme_font_override("font", FONT)
		heading.add_theme_font_size_override("font_size", 6)
		heading.add_theme_color_override("font_color", MUTED)
		column.add_child(heading)
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 2)
		row.add_theme_constant_override("v_separation", 2)
		row.custom_minimum_size = Vector2(190, 0)
		column.add_child(row)
		for control: Control in group["controls"]:
			control.reparent(row, false)
			control.custom_minimum_size = Vector2(maxf(control.custom_minimum_size.x, 0.0), 15.0)
			if control is Button and not control is OptionButton:
				_toggles.append(control as Button)
				(control as Button).toggled.connect(_on_filter_changed)
			elif control is OptionButton:
				_dropdowns.append(control as OptionButton)
				(control as OptionButton).item_selected.connect(_on_filter_changed)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 4)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	buttons.add_child(_action("CLEAR", clear))
	buttons.add_child(_action("DONE", close))
	_update_badge()


func _action(label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(44, 14)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 6)
	button.add_theme_stylebox_override("normal", _box(BACK, LINE))
	button.add_theme_stylebox_override("hover", _box(Color(0.17, 0.19, 0.28), TEXT))
	button.add_theme_stylebox_override("pressed", _box(Color(0.17, 0.19, 0.28), GOLD))
	button.add_theme_color_override("font_color", TEXT)
	button.pressed.connect(action)
	return button


static func _box(fill: Color, border: Color, margin: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(1)
	style.border_color = border
	style.set_content_margin_all(margin)
	return style


## How many filters are on: the buttons pressed and the drop-downs that are not on "-" (any).
func active_count() -> int:
	var count := 0
	for button in _toggles:
		if button.button_pressed:
			count += 1
	for dropdown in _dropdowns:
		if dropdown.selected > 0:
			count += 1
	return count


func clear() -> void:
	for button in _toggles:
		button.button_pressed = false # sends toggled, so the list is filtered again
	for dropdown in _dropdowns:
		if dropdown.selected != 0:
			dropdown.select(0)
			dropdown.item_selected.emit(0)
	_update_badge()


func close() -> void:
	button_pressed = false


func is_open() -> bool:
	return _popup != null and _popup.visible


func _on_filter_changed(_value: Variant) -> void:
	_update_badge()


func _update_badge() -> void:
	var count := active_count()
	text = "FILTER %d" % count if count > 0 else "FILTER"
	add_theme_color_override("font_color", GOLD if count > 0 else TEXT)


func _on_toggled(open: bool) -> void:
	if open:
		_popup.show()
		_popup.reset_size()
		var at := global_position + Vector2(0, size.y + 1.0)
		at.x = clampf(at.x, 2.0, 638.0 - _popup.size.x)
		at.y = minf(at.y, 358.0 - _popup.size.y)
		_popup.global_position = at
	else:
		_popup.hide()


## A click outside the panel (and not on the button) closes it; Escape closes it too.
func _input(event: InputEvent) -> void:
	if not is_open():
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed:
		var where := get_global_mouse_position()
		if not _popup.get_global_rect().has_point(where) and not get_global_rect().has_point(where):
			close()
	elif event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	if _popup != null:
		_popup.hide()
