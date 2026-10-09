extends Node

## Autoload for the "Interface Colors" accessibility setting.
##
## Three presets change how every Button looks (fill, border, text): the game's own look,
## a high-contrast look, and a blue and orange look that stays distinguishable with red-green
## color blindness. It works on the buttons themselves, so no scene needs editing: each Button
## that enters the tree is restyled, and "Default" puts back exactly what the button had.
##
## Image buttons (TextureButton: the title icons, the X buttons) are pictures and are not
## affected. The Colorblind Mode filter is a separate screen shader and keeps working on top.

enum Preset { DEFAULT, HIGH_CONTRAST, BLUE_ORANGE }

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "accessibility"
const KEY_PRESET := "interface_colors"

const PRESET_NAMES: Array[String] = ["Default", "High Contrast Buttons", "Blue and Orange"]

## Looks per button state. A state is {fill, border, halo, text}: the border is 2px, and the
## halo is a thin dark outline around it so the button also stands out from light backgrounds.
const PALETTES := {
	Preset.HIGH_CONTRAST: {
		"normal": {"fill": Color("0a0c18"), "border": Color("ffffff"), "halo": Color("000000"), "text": Color("ffffff")},
		"hover": {"fill": Color("1b2a63"), "border": Color("ffffff"), "halo": Color("000000"), "text": Color("ffffff")},
		"pressed": {"fill": Color("ffffff"), "border": Color("ffffff"), "halo": Color("000000"), "text": Color("0a0c18")},
		"disabled": {"fill": Color("0a0c18"), "border": Color("9aa3bf"), "halo": Color("000000"), "text": Color("aab2c8")},
	},
	Preset.BLUE_ORANGE: {
		"normal": {"fill": Color("14275f"), "border": Color("ff9d1c"), "halo": Color("060814"), "text": Color("ffffff")},
		"hover": {"fill": Color("ff9d1c"), "border": Color("ffffff"), "halo": Color("060814"), "text": Color("0a0c18")},
		"pressed": {"fill": Color("e8f3ff"), "border": Color("ff9d1c"), "halo": Color("060814"), "text": Color("0a0c18")},
		"disabled": {"fill": Color("1a1c2c"), "border": Color("7a86b0"), "halo": Color("060814"), "text": Color("aab2d6")},
	},
}

## Button style name -> palette state it uses.
const STYLE_STATES := {
	&"normal": "normal", &"hover": "hover", &"pressed": "pressed",
	&"hover_pressed": "pressed", &"disabled": "disabled",
}
## Button font color name -> palette state whose text color it uses.
const COLOR_STATES := {
	&"font_color": "normal", &"font_focus_color": "normal", &"font_hover_color": "hover",
	&"font_pressed_color": "pressed", &"font_hover_pressed_color": "pressed",
	&"font_disabled_color": "disabled",
}
const FOCUS_STYLE := &"focus"
const ORIGINAL_META := &"_interface_colors_original"
const BORDER_WIDTH := 2
# Keyboard focus: a second ring drawn just OUTSIDE the button, with a 1px gap. A ring on the
# button's own border would be invisible when that border is already white.
const FOCUS_RING_WIDTH := 2
const FOCUS_RING_GAP := 1
const FOCUS_RING_COLOR := Color("ffffff")

var preset: int = Preset.DEFAULT


func _ready() -> void:
	preset = _load_saved_preset()
	get_tree().node_added.connect(_on_node_added)
	if preset != Preset.DEFAULT:
		_apply_to_tree(get_tree().root)


## Switches the preset. `save` is false when only showing a stored value.
func set_preset(new_preset: int, save: bool = true) -> void:
	preset = clampi(new_preset, 0, PRESET_NAMES.size() - 1)
	_apply_to_tree(get_tree().root)
	if save:
		_save_preset()


func _on_node_added(node: Node) -> void:
	if preset != Preset.DEFAULT and node is Button:
		_skin_button.call_deferred(node) # deferred: let the scene finish setting the button up


func _apply_to_tree(node: Node) -> void:
	if node is Button:
		_skin_button(node)
	for child in node.get_children():
		_apply_to_tree(child)


func _skin_button(button: Button) -> void:
	if not is_instance_valid(button):
		return
	if not button.has_meta(ORIGINAL_META):
		if preset == Preset.DEFAULT:
			return # never touched, nothing to undo
		button.set_meta(ORIGINAL_META, _remember_original(button))
	if preset == Preset.DEFAULT:
		_restore_original(button)
	else:
		_apply_palette(button)
	if button is OptionButton:
		_skin_popup((button as OptionButton).get_popup())


## What the button looked like before: its own override for each style / color, or null when
## it had none (so it fell back to its theme).
func _remember_original(button: Button) -> Dictionary:
	var styles: Dictionary = {}
	for style_name: StringName in STYLE_STATES.keys() + [FOCUS_STYLE]:
		styles[style_name] = null
		if button.has_theme_stylebox_override(style_name):
			styles[style_name] = button.get_theme_stylebox(style_name)
	var colors: Dictionary = {}
	for color_name: StringName in COLOR_STATES:
		colors[color_name] = null
		if button.has_theme_color_override(color_name):
			colors[color_name] = button.get_theme_color(color_name)
	return {
		"styles": styles,
		"colors": colors,
		# Keep the button's size: new styles reuse the margins its normal style had, and the
		# button is never allowed to end up smaller than it was.
		"margins": _margins_of(button.get_theme_stylebox(&"normal")),
		"min_size": button.get_combined_minimum_size(),
		"custom_min": button.custom_minimum_size,
	}


func _restore_original(button: Button) -> void:
	var original: Dictionary = button.get_meta(ORIGINAL_META)
	button.custom_minimum_size = original["custom_min"]
	for style_name: StringName in original["styles"]:
		var style: StyleBox = original["styles"][style_name]
		if style != null:
			button.add_theme_stylebox_override(style_name, style)
		else:
			button.remove_theme_stylebox_override(style_name)
	for color_name: StringName in original["colors"]:
		var color: Variant = original["colors"][color_name]
		if color != null:
			button.add_theme_color_override(color_name, color)
		else:
			button.remove_theme_color_override(color_name)


func _apply_palette(button: Button) -> void:
	var palette: Dictionary = PALETTES[preset]
	var margins: Array = button.get_meta(ORIGINAL_META)["margins"]
	# A check button shows on/off with its switch graphic. Keep its row dark when it is on, so
	# the switch stays readable (an inverted, light row would hide the switch's light track).
	var is_toggle := button is CheckButton or button is CheckBox
	for style_name: StringName in STYLE_STATES:
		var state: String = STYLE_STATES[style_name]
		if is_toggle and state == "pressed":
			state = "normal"
		button.add_theme_stylebox_override(style_name, _make_style(palette[state], margins))
	button.add_theme_stylebox_override(FOCUS_STYLE, _make_focus_style())
	for color_name: StringName in COLOR_STATES:
		var state: String = COLOR_STATES[color_name]
		if is_toggle and state == "pressed":
			state = "normal"
		button.add_theme_color_override(color_name, palette[state]["text"])
	_keep_size(button)


## A button may get bigger with thicker padding but never smaller than it was, so layouts
## built around it do not move.
func _keep_size(button: Button) -> void:
	var original: Dictionary = button.get_meta(ORIGINAL_META)
	var wanted: Vector2 = original["min_size"]
	var custom: Vector2 = original["custom_min"]
	var now := button.get_minimum_size() # without custom_minimum_size
	custom.x = maxf(custom.x, wanted.x if now.x < wanted.x else 0.0)
	custom.y = maxf(custom.y, wanted.y if now.y < wanted.y else 0.0)
	button.custom_minimum_size = custom


func _make_style(state: Dictionary, margins: Array) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = state["fill"]
	style.set_border_width_all(BORDER_WIDTH)
	style.border_color = state["border"]
	style.shadow_color = state["halo"]
	style.shadow_size = 1
	style.shadow_offset = Vector2.ZERO
	style.content_margin_left = maxf(margins[0], BORDER_WIDTH)
	style.content_margin_top = maxf(margins[1], BORDER_WIDTH)
	style.content_margin_right = maxf(margins[2], BORDER_WIDTH)
	style.content_margin_bottom = maxf(margins[3], BORDER_WIDTH)
	return style


## Hollow ring around the outside of the button (expand margin = gap + ring width).
func _make_focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_border_width_all(FOCUS_RING_WIDTH)
	style.border_color = FOCUS_RING_COLOR
	style.set_expand_margin_all(FOCUS_RING_GAP + FOCUS_RING_WIDTH)
	return style


func _margins_of(style: StyleBox) -> Array:
	return [style.get_margin(SIDE_LEFT), style.get_margin(SIDE_TOP), style.get_margin(SIDE_RIGHT), style.get_margin(SIDE_BOTTOM)]


## The list that opens from an OptionButton is its own window; give it the same look.
func _skin_popup(popup: PopupMenu) -> void:
	if popup == null:
		return
	if preset == Preset.DEFAULT:
		for style_name: StringName in [&"panel", &"hover"]:
			popup.remove_theme_stylebox_override(style_name)
		for color_name: StringName in [&"font_color", &"font_hover_color", &"font_disabled_color"]:
			popup.remove_theme_color_override(color_name)
		return
	var palette: Dictionary = PALETTES[preset]
	popup.add_theme_stylebox_override(&"panel", _make_style(palette["normal"], [4, 4, 4, 4]))
	popup.add_theme_stylebox_override(&"hover", _make_style(palette["pressed"], [4, 2, 4, 2]))
	popup.add_theme_color_override(&"font_color", palette["normal"]["text"])
	popup.add_theme_color_override(&"font_hover_color", palette["pressed"]["text"])
	popup.add_theme_color_override(&"font_disabled_color", palette["disabled"]["text"])


func _load_saved_preset() -> int:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return Preset.DEFAULT
	return clampi(int(config.get_value(SECTION, KEY_PRESET, Preset.DEFAULT)), 0, PRESET_NAMES.size() - 1)


func _save_preset() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_PRESET, preset)
	config.save(SETTINGS_PATH)
