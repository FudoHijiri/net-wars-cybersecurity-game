extends Control

@onready var exit_button: TextureButton = $NinePatchRect/ExitButton
@onready var settings_overlay: Control = $"."
# Looked up by name so moving nodes around in the scene doesn't break the paths.
@onready var colorblind_option: OptionButton = find_child("ColorblindModeOptions", true, false)
@onready var interface_colors_option: OptionButton = find_child("InterfaceColorsOptions", true, false)
@onready var reduce_effects_toggle: CheckButton = find_child("ReduceEffects", true, false)
@onready var shaking_toggle: CheckButton = find_child("Shaking", true, false)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_show_saved_values()
	# The overlay can stay alive while hidden (the pause menu keeps one), so refresh on show.
	visibility_changed.connect(_show_saved_values)


## Shows the stored settings without re-applying them (select() and set_pressed_no_signal()
## do not emit the signals the handlers below listen to).
func _show_saved_values() -> void:
	colorblind_option.select(ColorblindFilter.mode)
	interface_colors_option.select(InterfaceColors.preset)
	reduce_effects_toggle.set_pressed_no_signal(ScreenEffects.reduce_effects)
	shaking_toggle.set_pressed_no_signal(ScreenEffects.screen_shake)


func _on_exit_button_pressed() -> void:
	settings_overlay.hide()


func _on_colorblind_mode_options_item_selected(index: int) -> void:
	ColorblindFilter.set_mode(index)


func _on_interface_colors_options_item_selected(index: int) -> void:
	InterfaceColors.set_preset(index)


func _on_reduce_effects_toggled(toggled_on: bool) -> void:
	ScreenEffects.set_reduce_effects(toggled_on)


func _on_shaking_toggled(toggled_on: bool) -> void:
	ScreenEffects.set_screen_shake(toggled_on)
