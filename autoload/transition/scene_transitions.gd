extends CanvasLayer

## The loading screen. SceneManager (scene_loader.gd) instances one of these for every scene
## change: it fades to black, tells the loader it may start loading, and fades away again once
## the new scene is in place. It is not an autoload.
##
## Reduce Screen Effects: no fade at all, the scene just switches.

## Emitted when the screen is fully black (or right away with Reduce Screen Effects).
signal loading_screen_ready

const LAYER := 150 # above the game and the colorblind filter, below the debug panel
const FADE_ANIMATION := &"scene_transition" # forwards: black, then clear. Backwards: clear, then black.

@export var animation_player: AnimationPlayer

@onready var fade_to_black: ColorRect = $FadeToBlack


func _ready() -> void:
	layer = LAYER
	if ScreenEffects.reduce_effects:
		fade_to_black.hide()
		await get_tree().process_frame # the loader starts waiting for the signal after add_child()
		loading_screen_ready.emit()
		return
	fade_to_black.color.a = 0.0 # the scene starts opaque: begin clear so the fade has no flash
	animation_player.play_backwards(FADE_ANIMATION)
	animation_player.advance(0.0)
	await animation_player.animation_finished
	loading_screen_ready.emit()


## Use the new_value for updating a progress bar or other visuals. Nothing shows progress yet.
func _on_progress_changed(_new_value: float) -> void:
	pass


## The new scene is in place (or loading failed): fade back to the game, then remove the screen.
func _on_load_finished() -> void:
	if ScreenEffects.reduce_effects:
		queue_free()
		return
	animation_player.play(FADE_ANIMATION)
	await animation_player.animation_finished
	queue_free()
