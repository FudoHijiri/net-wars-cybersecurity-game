extends Control

@onready var play_icon: TextureButton = $"Control/Screen Content/Play"
@onready var settings_icon: TextureButton = $"Control/Screen Content/Settings"
@onready var exit_icon: TextureButton = $"Control/Screen Content/Exit"
@onready var title_overlay: Control = $"Control/Screen Content/TitleOverlay"
@onready var settings_overlay: Control = $"Control/Screen Content/SettingsOverlay"


func _ready() -> void:
	title_overlay.show()
	settings_overlay.hide()


func _on_play_pressed() -> void:
	title_overlay.show()
	settings_overlay.hide()


func _on_settings_pressed() -> void:
	settings_overlay.show()
	title_overlay.hide()


func _on_exit_pressed() -> void:
	get_tree().quit()
