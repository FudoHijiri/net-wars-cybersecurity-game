class_name SceneFade
extends RefCounted

## Fades the screen to dark, switches scene, then fades back in (or just switches when
## Reduce Screen Effects is on). Static and fire-and-forget:
## `SceneFade.go(get_tree(), "res://...")`. The fade layer lives on the root, so it survives
## the scene change and removes itself when done.

const FADE_SECONDS := 0.35
const COLOR := Color("1a1c2c")
const LAYER := 150 # above the game and the colorblind filter, below the debug panel

static var _busy := false # a second request during a fade is ignored


static func go(tree: SceneTree, scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		push_error("SceneFade: scene not found: %s" % scene_path)
		return
	if ScreenEffects.reduce_effects:
		tree.change_scene_to_file(scene_path) # Reduce Screen Effects: no fade, switch right away
		return
	if _busy:
		return
	_busy = true
	var layer := CanvasLayer.new()
	layer.layer = LAYER
	var cover := ColorRect.new()
	cover.color = COLOR
	cover.modulate.a = 0.0
	cover.mouse_filter = Control.MOUSE_FILTER_STOP # no clicks while the screen fades
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(cover)
	tree.root.add_child(layer)

	await _fade(tree, cover, 1.0)
	tree.change_scene_to_file(scene_path)
	await tree.process_frame # the swap happens at the end of this frame
	await tree.process_frame # the new scene has run its _ready()
	await _fade(tree, cover, 0.0)
	layer.queue_free()
	_busy = false


static func _fade(tree: SceneTree, cover: ColorRect, alpha: float) -> void:
	var tween := tree.create_tween()
	tween.tween_property(cover, "modulate:a", alpha, FADE_SECONDS)
	await tween.finished
