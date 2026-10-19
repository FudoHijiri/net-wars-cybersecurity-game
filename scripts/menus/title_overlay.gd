extends Control

@onready var title_overlay: Control = $"."


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	title_overlay.hide()
	


func _on_exit_pressed() -> void:
	title_overlay.hide()
