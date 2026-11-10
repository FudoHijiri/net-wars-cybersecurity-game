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


## A card on the black screen: "PHASE 3 OF 5", the phase's name, and the day's title. It fades in, stays about
## 0.9 s (a click or Space ends it early) and fades out; the loader waits for it. Returns when it is gone.
func show_card(top: String, title: String, bottom: String) -> void:
	var font := load("res://assets/font/Press Start 8p/PressStart2P.ttf") as Font
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for line in [[top, 8, Color(0.5803922, 0.6901961, 0.7607843)], [title, 16, Color(1, 0.8039216, 0.45882353)], [bottom, 8, Color(0.95686275, 0.95686275, 0.95686275)]]:
		var label := Label.new()
		label.text = str(line[0])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", int(line[1])) # 8 and 16: whole multiples of the font
		label.add_theme_color_override("font_color", line[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	box.modulate.a = 0.0
	add_child(box)
	var tween := create_tween()
	tween.tween_property(box, "modulate:a", 1.0, 0.2)
	await tween.finished
	var held := 0.0
	while held < 0.7 and not _card_skipped:
		held += get_process_delta_time()
		await get_tree().process_frame
	_card_skipped = false
	tween = create_tween()
	tween.tween_property(box, "modulate:a", 0.0, 0.2)
	await tween.finished
	box.queue_free()


var _card_skipped := false


func _input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if (click != null and click.pressed) or event.is_action_pressed("ui_accept"):
		_card_skipped = true
