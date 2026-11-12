class_name ObjectiveBar
extends Panel
## The top bar of a phase that has no window of its own (Response), laid out like the ones of Investigation and
## Monitoring: the phase icon on the left, the OBJECTIVE next to it in the bold 6px font, and the pause button
## on the right. The objective is the "objective" of the phase in data/days.json (GameState.objective()), so the
## player always reads what they are here to do.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const PAUSE_ICON := preload("res://assets/ui/Pause Icon.png")

## The icon of the phase, shown before the objective.
var icon: Texture2D


func _ready() -> void:
	size = Vector2(640, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101960786, 0.10980392, 0.17254902, 1)
	style.border_width_bottom = 1
	style.border_color = GameColors.highlight
	add_theme_stylebox_override("panel", style)
	var picture := TextureRect.new()
	picture.texture = icon
	picture.position = Vector2(4, 4)
	picture.size = Vector2(16, 16)
	picture.stretch_mode = TextureRect.STRETCH_KEEP
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)
	var objective := Label.new()
	objective.text = GameState.objective()
	objective.position = Vector2(24, 0)
	objective.size = Vector2(560, 24)
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective.add_theme_font_override("font", FONT)
	objective.add_theme_font_size_override("font_size", 6)
	objective.add_theme_color_override("font_color", GameColors.highlight)
	add_child(objective)
	var pause := TextureButton.new()
	pause.texture_normal = PAUSE_ICON
	pause.position = Vector2(614, 4)
	pause.scale = Vector2(2, 2)
	pause.pressed.connect(PauseMenu.open)
	add_child(pause)
