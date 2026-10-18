extends CanvasLayer

## Signals
signal fade_complete

@onready var fade_to_black: ColorRect = $FadeToBlack
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var scene_to_load: String
var color_rect_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_to_black.hide()


func fade_in()->void:
	fade_to_black.show()
	animation_player.play("scene_transition")
	
	await animation_player.animation_finished
	fade_to_black.hide()


func fade_out()->void:
	fade_to_black.show()
	animation_player.play_backwards("scene_transition")
	
	await animation_player.animation_finished
	# Stay black until the next fade_in() so the swap/scene change isn't visible.
	fade_complete.emit()
