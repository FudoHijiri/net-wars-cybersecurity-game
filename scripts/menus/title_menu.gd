extends Node

@onready var stage_select: Control = $"MainContent/StageSelect"
@onready var animation_player: AnimationPlayer = $"MainContent/AnimationPlayer"
@onready var exit_confirmation: NinePatchRect = $"MainContent/ExitConfirmation"


func _ready() -> void:
	stage_select.hide()
	exit_confirmation.hide()
	


func _on_play_button_pressed() -> void:
	stage_select.show()
	animation_player.play("stage_select_animation")
	await animation_player.animation_finished


func _on_settings_button_pressed() -> void:
	SceneManager.fade_through(Settings.open) # covers the whole screen: fade out, open, fade in


func _on_exit_button_pressed() -> void:
	exit_confirmation.show()
	animation_player.play("exit_confirmation")
	await animation_player.animation_finished


func _on_yes_button_pressed() -> void:
	get_tree().quit()



func _on_no_button_pressed() -> void:
	animation_player.play_backwards("exit_confirmation")
	await animation_player.animation_finished
	exit_confirmation.hide()
