extends Control

@onready var exit_button: TextureButton = $NinePatchRect/ExitButton
@onready var settings_overlay: Control = $"."
# Looked up by name so moving nodes around in the scene doesn't break the paths.
@onready var colorblind_option: OptionButton = find_child("ColorblindModeOptions", true, false)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Show the saved value without re-applying it.
	colorblind_option.select(ColorblindFilter.mode)


func _on_exit_button_pressed() -> void:
	settings_overlay.hide()


func _on_colorblind_mode_options_item_selected(index: int) -> void:
	ColorblindFilter.set_mode(index)
