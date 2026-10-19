extends Node

@onready var stage_select: Control = $"Main Content/StageSelect"
@onready var animation_player: AnimationPlayer = $"Main Content/AnimationPlayer"
@onready var exit_confirmation: NinePatchRect = $"Main Content/ExitConfirmation"


func _ready() -> void:
	stage_select.hide()
	exit_confirmation.hide()
	SceneTransitions.fade_in()


func _on_play_button_pressed() -> void:
	stage_select.show()
	animation_player.play("stage_select_animation")
	await animation_player.animation_finished


func _on_settings_button_pressed() -> void:
	await SceneTransitions.fade_out()
	SceneTransitions.fade_in()


func _on_exit_button_pressed() -> void:
	exit_confirmation.show()
	animation_player.play("exit_confirmation")
	await animation_player.animation_finished


func _on_yes_button_pressed() -> void:
	await SceneTransitions.fade_out()
	get_tree().quit()


func _on_no_button_pressed() -> void:
	animation_player.play_backwards("exit_confirmation")
	await animation_player.animation_finished
	exit_confirmation.hide()
