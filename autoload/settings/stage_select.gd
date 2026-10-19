extends Control

@onready var stage_select: Control = $"."
@onready var new_game_button: TextureButton = $NinePatchRect/NewGameButton
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

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
	animation_player.play_backwards("stage_select_animation")
	await animation_player.animation_finished
	stage_select.hide()


func _on_new_game_button_pressed() -> void:
	new_game_button.disabled = true 
	GameState.reset_progress()
	await SceneTransitions.fade_out()
	SceneTransitions.fade_in()
	SCENE_FADE.go(get_tree(), GAMEPLAY_SCENE)
