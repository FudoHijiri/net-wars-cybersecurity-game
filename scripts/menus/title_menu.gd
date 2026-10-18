extends Control

@onready var play_icon: TextureButton = $"Control/Screen Content/Play"
@onready var settings_icon: TextureButton = $"Control/Screen Content/Settings"
@onready var exit_icon: TextureButton = $"Control/Screen Content/Exit"
@onready var title_overlay: Control = $"Control/Screen Content/TitleOverlay"
@onready var settings_overlay: Control = $"Control/Screen Content/SettingsOverlay"




func _ready() -> void:
	title_overlay.show()
	settings_overlay.hide()
	SceneTransitions.fade_in()


func _on_play_pressed() -> void:
	await SceneTransitions.fade_out()
	title_overlay.show()
	settings_overlay.hide()
	SceneTransitions.fade_in()


func _on_settings_pressed() -> void:
	await SceneTransitions.fade_out()
	settings_overlay.show()
	title_overlay.hide()
	SceneTransitions.fade_in()


func _on_exit_pressed() -> void:
	await SceneTransitions.fade_out()
	get_tree().quit()
