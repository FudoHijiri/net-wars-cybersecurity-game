extends CanvasLayer

## Autoload that applies the colour-blind simulation shader to the whole game.
## It lives outside any scene so the filter survives scene changes and stays on
## while the settings overlay is closed.

const SHADER := preload("res://assets/shaders/colorblind.gdshader")
const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "accessibility"
const KEY_MODE := "colorblind_mode"
const MODE_COUNT := 9

## Index matches the shader's color_deficiency_type (0 = normal vision).
var mode: int = 0

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 100 # draw above every other CanvasLayer so the whole screen is filtered

	_material = ShaderMaterial.new()
	_material.shader = SHADER

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)

	set_mode(_load_saved_mode(), false)


func set_mode(new_mode: int, save: bool = true) -> void:
	mode = clampi(new_mode, 0, MODE_COUNT - 1)
	_material.set_shader_parameter("color_deficiency_type", mode)
	# The shader reads the screen texture, which costs a screen copy every frame,
	# so skip it entirely for normal vision.
	_rect.visible = mode != 0
	if save:
		_save_mode()


func _load_saved_mode() -> int:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return 0
	return int(config.get_value(SECTION, KEY_MODE, 0))


func _save_mode() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_MODE, mode)
	# Drop the key left behind by the removed High Contrast setting.
	if config.has_section_key(SECTION, "high_contrast"):
		config.erase_section_key(SECTION, "high_contrast")
	config.save(SETTINGS_PATH)
