extends CanvasLayer

const OPTION_THEME := preload("res://assets/ui/optionbar/option_button_theme.tres")
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const LABEL_WIDTH := 64.0 # the width of a color's name, so the squares line up

@onready var exit_button: TextureButton = %ExitButton
@onready var colorblind_option: OptionButton = find_child("ColorblindModeOptions", true, false)
@onready var interface_colors_option: OptionButton = find_child("InterfaceColorsOptions", true, false)
@onready var reduce_effects_toggle: CheckButton = find_child("ReduceEffects", true, false)
@onready var resolution_option: OptionButton = find_child("ResolutionOptions", true, false)
@onready var borderless_toggle: CheckButton = find_child("BorderlessWindowed", true, false)
@onready var palette_option: OptionButton = find_child("PaletteOptions", true, false)
@onready var color_rows: VBoxContainer = find_child("ColorRows", true, false)
@onready var mute_toggle: CheckButton = find_child("MuteInBackground", true, false)
@onready var master_slider: HSlider = find_child("MasterVolSlider", true, false)
@onready var music_slider: HSlider = find_child("MusicVolSlider", true, false)
@onready var sfx_slider: HSlider = find_child("SFXSlider", true, false)
@onready var default_button: Button = find_child("DefaultButton", true, false)
@onready var apply_button: Button = find_child("ApplyButton", true, false)

var _swatches := {} # role -> Array[ColorSwatch]
var _reset_buttons := {} # role -> Button
## What the controls show. Nothing is changed in the game until Apply (or Reset to Default, then Apply).
var _pending := {}
var _confirm: DisplayConfirm


func _ready() -> void:
	hide()
	var button_theme := _make_button_theme()
	for button: Button in [default_button, apply_button]:
		if button.theme == null:
			button.theme = button_theme
	_build_color_rows()
	_show_saved_values()
	# The overlay can stay alive while hidden (the pause menu keeps one), so refresh on show.
	visibility_changed.connect(_show_saved_values)


## What the game uses now.
func _applied_values() -> Dictionary:
	return {
		"colorblind": ColorblindFilter.mode,
		"interface": InterfaceColors.preset,
		"reduce": ScreenEffects.reduce_effects,
		"borderless": DisplaySettings.borderless,
		"size": DisplaySettings.current_size(),
		"colors": GameColors.custom_colors(),
		"mute": AudioSettings.mute_in_background,
		"master": AudioSettings.volume(&"Master"),
		"music": AudioSettings.volume(&"Music"),
		"sfx": AudioSettings.volume(&"SFX"),
	}


func _default_values() -> Dictionary:
	return {
		"colorblind": 0,
		"interface": InterfaceColors.Preset.DEFAULT,
		"reduce": false,
		"borderless": true,
		"size": DisplaySettings.default_size(),
		"colors": {},
		"mute": false,
		"master": 100.0,
		"music": 100.0,
		"sfx": 100.0,
	}


## Shows what the game uses now (select() and set_pressed_no_signal() do not emit the signals the
## handlers below listen to).
func _show_saved_values() -> void:
	_pending = _applied_values()
	_show_pending()


func _show_pending() -> void:
	colorblind_option.select(_pending["colorblind"])
	interface_colors_option.select(_pending["interface"])
	reduce_effects_toggle.set_pressed_no_signal(_pending["reduce"])
	_show_display()
	_show_colors()
	mute_toggle.set_pressed_no_signal(_pending["mute"])
	master_slider.set_value_no_signal(_pending["master"])
	music_slider.set_value_no_signal(_pending["music"])
	sfx_slider.set_value_no_signal(_pending["sfx"])
	_refresh_apply()


## Apply is only for when something is different from what the game uses.
func _refresh_apply() -> void:
	apply_button.disabled = _pending == _applied_values()


func open() -> void:
	show()


func close() -> void:
	hide()


# --- Display ---

## The window sizes that fit this screen (with a title bar there is less room); the pending one is selected.
func _show_display() -> void:
	borderless_toggle.set_pressed_no_signal(_pending["borderless"])
	resolution_option.clear()
	var wanted: Vector2i = _pending["size"]
	var chosen := 0
	for window_size in DisplaySettings.available_sizes(not _pending["borderless"]):
		var fills: bool = _pending["borderless"] and window_size == DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
		@warning_ignore("integer_division") # the scale is a whole number
		resolution_option.add_item("%d x %d  (%dx%s)" % [window_size.x, window_size.y, window_size.x / DisplaySettings.BASE_SIZE.x, ", fullscreen" if fills else ""])
		resolution_option.set_item_metadata(resolution_option.item_count - 1, window_size)
		if window_size.x <= wanted.x:
			chosen = resolution_option.item_count - 1 # the largest one that is not bigger than the wanted size
	resolution_option.select(chosen)


func _on_resolution_options_item_selected(index: int) -> void:
	_pending["size"] = resolution_option.get_item_metadata(index)
	_refresh_apply()


func _on_borderless_windowed_toggled(toggled_on: bool) -> void:
	_pending["borderless"] = toggled_on
	_show_display() # a window with a title bar has less room, so the sizes that fit change
	_pending["size"] = resolution_option.get_item_metadata(resolution_option.selected)
	_refresh_apply()


## Changes the window, then asks the player whether it is right. The player has to answer (or the time
## runs out) before it is kept; going back puts the old border and size back.
func _try_display(borderless: bool, window_size: Vector2i) -> void:
	var was_borderless := DisplaySettings.borderless
	var was_size := DisplaySettings.window_size
	DisplaySettings.set_display(borderless, window_size)
	_confirm = DisplayConfirm.new()
	_confirm.setup(_make_button_theme())
	$Control.add_child(_confirm)
	_confirm.answered.connect(_on_display_answered.bind(was_borderless, was_size), CONNECT_ONE_SHOT)


func _on_display_answered(keep: bool, was_borderless: bool, was_size: Vector2i) -> void:
	_confirm.queue_free()
	_confirm = null
	if keep:
		DisplaySettings.save()
	else:
		DisplaySettings.set_display(was_borderless, was_size)
	_show_saved_values()


# --- Custom Colors ---

## One row for each color role of GameColors: its name, the squares to choose from, and a Reset button.
func _build_color_rows() -> void:
	var button_theme := _make_button_theme()
	for role in GameColors.ROLES:
		var info: Dictionary = GameColors.INFO[role]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		color_rows.add_child(row)
		var name_label := _make_label(str(info["name"]))
		name_label.custom_minimum_size.x = LABEL_WIDTH
		name_label.mouse_filter = Control.MOUSE_FILTER_STOP
		name_label.tooltip_text = str(info["hint"])
		row.add_child(name_label)
		var squares := HBoxContainer.new()
		squares.add_theme_constant_override("separation", 4)
		squares.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(squares)
		_swatches[role] = []
		for swatch_color in GameColors.SWATCHES:
			var swatch := ColorSwatch.new()
			swatch.color = swatch_color
			swatch.tooltip_text = "#%s" % swatch_color.to_html(false).to_upper()
			swatch.picked.connect(_on_swatch_picked.bind(role, swatch_color))
			squares.add_child(swatch)
			_swatches[role].append(swatch)
		var reset := Button.new()
		reset.text = "Reset"
		reset.theme = button_theme
		reset.tooltip_text = "Back to the game's color."
		reset.pressed.connect(_on_color_reset.bind(role))
		row.add_child(reset)
		_reset_buttons[role] = reset


func _show_colors() -> void:
	var colors: Dictionary = _pending["colors"]
	palette_option.select(GameColors.palette_of(colors))
	for role in GameColors.ROLES:
		var now: Color = colors.get(role, GameColors.INFO[role]["color"])
		for swatch: ColorSwatch in _swatches[role]:
			swatch.selected = swatch.color.is_equal_approx(now)
		(_reset_buttons[role] as Button).disabled = not colors.has(role)


func _on_swatch_picked(role: StringName, swatch_color: Color) -> void:
	var colors: Dictionary = _pending["colors"]
	if swatch_color.is_equal_approx(GameColors.INFO[role]["color"]):
		colors.erase(role) # the game's own color is not a custom one
	else:
		colors[role] = swatch_color
	_show_colors()
	_refresh_apply()


func _on_color_reset(role: StringName) -> void:
	(_pending["colors"] as Dictionary).erase(role)
	_show_colors()
	_refresh_apply()


func _on_palette_options_item_selected(index: int) -> void:
	if GameColors.PRESETS.has(index):
		_pending["colors"] = (GameColors.PRESETS[index] as Dictionary).duplicate()
	elif index == GameColors.Palette.DEFAULT:
		_pending["colors"] = {}
	_show_colors() # "Custom" applies nothing, so put the real palette back in the list
	_refresh_apply()


func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 6)
	return label


## A Button in the look of the option bar (its frames, without the room for the arrow).
func _make_button_theme() -> Theme:
	var button_theme := Theme.new()
	for state: StringName in [&"normal", &"hover", &"pressed", &"disabled", &"focus"]:
		var box := OPTION_THEME.get_stylebox(state, &"OptionButton").duplicate() as StyleBoxTexture
		if box.content_margin_right >= 0.0:
			box.content_margin_right = box.content_margin_left
		button_theme.set_stylebox(state, &"Button", box)
	button_theme.set_stylebox(&"hover_pressed", &"Button", button_theme.get_stylebox(&"pressed", &"Button"))
	button_theme.set_font(&"font", &"Button", FONT)
	button_theme.set_font_size(&"font_size", &"Button", 6)
	for color_name: StringName in [&"font_color", &"font_focus_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_disabled_color"]:
		button_theme.set_color(color_name, &"Button", OPTION_THEME.get_color(color_name, &"OptionButton"))
	return button_theme


# --- Sounds & Volume ---

func _on_mute_in_background_toggled(toggled_on: bool) -> void:
	_pending["mute"] = toggled_on
	_refresh_apply()


func _on_master_vol_slider_value_changed(value: float) -> void:
	_pending["master"] = value
	_refresh_apply()


func _on_music_vol_slider_value_changed(value: float) -> void:
	_pending["music"] = value
	_refresh_apply()


func _on_sfx_slider_value_changed(value: float) -> void:
	_pending["sfx"] = value
	_refresh_apply()


# --- General ---

func _on_exit_button_pressed() -> void:
	SceneManager.fade_through(close) # covers the whole screen: fade out, close, fade in


func _on_colorblind_mode_options_item_selected(index: int) -> void:
	_pending["colorblind"] = index
	_refresh_apply()


func _on_interface_colors_options_item_selected(index: int) -> void:
	_pending["interface"] = index
	_refresh_apply()


func _on_reduce_effects_toggled(toggled_on: bool) -> void:
	_pending["reduce"] = toggled_on
	_refresh_apply()


## Puts the default of every setting in the controls. Apply makes them count.
func _on_default_button_pressed() -> void:
	_pending = _default_values()
	_show_pending()


## Applies and saves everything that was set. A different border or size is tried first and the
## player is asked whether to keep it; the other settings are already kept.
func _on_apply_button_pressed() -> void:
	var wanted := _pending.duplicate(true)
	ColorblindFilter.set_mode(int(wanted["colorblind"]))
	InterfaceColors.set_preset(int(wanted["interface"]))
	ScreenEffects.set_reduce_effects(wanted["reduce"])
	GameColors.set_custom_colors(wanted["colors"])
	AudioSettings.set_mute_in_background(wanted["mute"])
	AudioSettings.set_volume(&"Master", wanted["master"])
	AudioSettings.set_volume(&"Music", wanted["music"])
	AudioSettings.set_volume(&"SFX", wanted["sfx"])
	var display_differs: bool = wanted["size"] != DisplaySettings.current_size() or wanted["borderless"] != DisplaySettings.borderless
	if display_differs:
		_try_display(wanted["borderless"], wanted["size"])
	else:
		_show_saved_values()
