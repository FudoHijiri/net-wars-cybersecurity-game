extends Control

@onready var title_overlay: Control = $"../TitleOverlay"
@onready var stage_select: Control = $"."
@onready var new_game_button: TextureButton = $NinePatchRect/NewGameButton

const GAMEPLAY_SCENE := "res://scenes/gameplay/investigation/Investigation.tscn"
# Loaded by path, so this works even before the editor has registered the SceneFade class.
const SCENE_FADE := preload("res://AI generated/scripts/transition/scene_fade.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_pressed() -> void:
	stage_select.hide()
	title_overlay.show()


func _on_new_game_button_pressed() -> void:
	new_game_button.disabled = true # one press is enough while the screen fades
	GameState.reset_progress()
	SCENE_FADE.go(get_tree(), GAMEPLAY_SCENE)
