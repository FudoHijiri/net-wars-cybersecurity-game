extends Control

const NEXT_SCENE := "uid://cd4swcir106gx"

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


## Esc ends the intro at once.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_animation_player.stop() # a stopped animation does not emit animation_finished
		SceneManager.load_scene(NEXT_SCENE)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	SceneManager.load_scene(NEXT_SCENE)
