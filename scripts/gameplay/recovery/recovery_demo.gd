extends Control

## Practice launcher. The menu layout is authored in RecoveryDemo.tscn; preset
## buttons are copies of %PresetTemplate, one per JSON preset.

const ROOM := preload("res://scenes/gameplay/recovery/Recovery.tscn")
const DIALOG_SCENE := preload("res://scenes/gameplay/recovery/ui/RecoveryDialog.tscn")
@export var preview_player: RecoveryPlayer
@export var preview_world: Node2D
var _room: RecoveryRoom
var _data: Dictionary = {}
var _credits: RecoveryDialog
var preset_buttons: Dictionary = {}

@onready var _menu: Control = %Frame
@onready var _presets: GridContainer = %Presets
@onready var _preset_template: Button = %PresetTemplate


func _ready() -> void:
	_data = RecoveryData.load_data()
	var texts: Dictionary = _data.get("demo", {})
	preview_player.hide()
	# Preview is scenery only; disabled processing alone does not remove physics bodies.
	for object: CollisionObject2D in preview_world.find_children("*", "CollisionObject2D", true, false):
		object.collision_layer = 0
		object.collision_mask = 0
	for camera: Camera2D in preview_world.find_children("*", "Camera2D", true, false):
		camera.enabled = false
	for marker in preview_world.find_children("*", "Marker2D", true, false):
		if marker is RecoveryStatusMarker:
			marker.hide()
	%Title.text = str(texts.get("title", ""))
	%Description.text = str(texts.get("description", ""))
	%StageSelectButton.text = str(texts.get("return", ""))
	for preset: Dictionary in texts.get("presets", []):
		var button := _preset_template.duplicate() as Button
		button.unique_name_in_owner = false
		button.text = str(preset.get("label", ""))
		button.pressed.connect(launch_preset.bind(str(preset["id"])))
		button.show()
		_presets.add_child(button)
		preset_buttons[str(preset["id"])] = button
	_focus_menu()


func _focus_menu() -> void:
	RecoveryStyle.focus_loop(_menu)
	var choices := preset_buttons.values()
	for i in choices.size():
		choices[i].focus_neighbor_top = choices[maxi(0, i - 2)].get_path()
		if i + 2 < choices.size():
			choices[i].focus_neighbor_bottom = choices[i + 2].get_path()
	if not choices.is_empty():
		choices[0].grab_focus()


func _show_credits() -> void:
	_menu.hide()
	_credits = DIALOG_SCENE.instantiate() as RecoveryDialog
	_credits.configure("Art credits", RecoveryData.credits(_data), [{"id": "close", "label": "Back to lab", "callback": _close_credits}])
	add_child(_credits)


func _close_credits() -> void:
	remove_child(_credits)
	_credits.queue_free()
	_credits = null
	_menu.show()
	_focus_menu()


func launch_preset(preset_id: String) -> void:
	if is_instance_valid(_room):
		return
	for preset: Dictionary in _data.get("demo", {}).get("presets", []):
		if str(preset["id"]) != preset_id:
			continue
		var damage: Array[String] = []
		damage.assign(preset.get("damage", []))
		var context := RecoveryContext.sample_context(str(preset.get("profile", "day1")))
		var outcome := {} if preset_id == "waiting" else RecoveryContext.sample_outcome()
		if preset_id == "backup":
			outcome["summary"] = "Practice result: the incident is contained. A checked backup is needed to restore unavailable records."
		elif preset_id == "all":
			outcome["summary"] = "Practice result: containment is confirmed. Reconnect cleared equipment, restore a checked backup, and verify the result."
		_menu.hide()
		_room = ROOM.instantiate() as RecoveryRoom
		_room.configure_demo(damage, [], outcome, context)
		_room.return_to_demo.connect(_show_presets)
		add_child(_room)
		return


func _show_presets() -> void:
	if is_instance_valid(_room):
		remove_child(_room)
		_room.queue_free()
		_room = null
	_menu.show()
	_focus_menu()


func _go_to_stage_select() -> void:
	SceneManager.load_stage_select()
