class_name Tutorial
extends RefCounted
## Decides when the tutorial of a phase is shown. It is shown once per phase, on Day 1 of a new save, and
## never again: the phase leaves the save's "tutorial" list as soon as it starts. An older save has no
## such list (see SaveManager), so it never gets the tutorials. The steps are in data/tutorials.json.

const STEPS_PATH := "res://data/tutorials.json"


## Call at the end of a phase scene's _ready(), once the scene is on screen. `phase` is the key of the
## phase in tutorials.json. Does nothing when the tutorial is not due.
static func maybe_show(scene: Node, phase: String) -> void:
	if SaveManager.current_slot < 0 or GameState.current_day != 1:
		return
	var due: Array = SaveManager.data.get("tutorial", [])
	if not due.has(phase):
		return
	var steps: Array = _load_steps().get(phase, [])
	if steps.is_empty():
		return
	due.erase(phase)
	var overlay := TutorialOverlay.new()
	scene.add_child(overlay)
	overlay.play(steps, scene)
	overlay.finished.connect(func() -> void: SaveManager.save()) # so it stays gone even if the player quits now


static func _load_steps() -> Dictionary:
	var file := FileAccess.open(STEPS_PATH, FileAccess.READ)
	if file == null:
		push_error("Tutorial: cannot open %s" % STEPS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
