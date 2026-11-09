@tool
class_name RecoveryInteractable
extends Area2D

@export_enum("task", "work_order") var kind := "task"
@export var target := "network"
@export var title := ""
@export var interaction_shape: CollisionShape2D
@export var status_marker: RecoveryStatusMarker
var equipment_id := ""
var equipment_group := ""
var status := "needs_repair"
var player_nearby := false
var enabled := true

func _validate_property(property: Dictionary) -> void:
	if property.name == "target":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = RecoveryData.enum_hint(["work_order"] as Array[String])

func set_enabled(value: bool) -> void:
	enabled = value
	if Engine.is_editor_hint() or not is_inside_tree():
		monitoring = enabled
	else:
		set_deferred("monitoring", enabled)
	if not enabled:
		player_nearby = false
	_update_marker()


func _ready() -> void:
	_update_marker()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is RecoveryPlayer:
		player_nearby = true
		_update_marker()

func _on_body_exited(body: Node2D) -> void:
	if body is RecoveryPlayer:
		player_nearby = false
		_update_marker()

func is_in_reach(body: Node2D) -> bool:
	if not enabled or not is_instance_valid(interaction_shape) or interaction_shape.disabled:
		return false
	# The Inspector's shape is the single source of truth for reach, measured at feet.
	var point := interaction_shape.to_local(body.global_position)
	var shape := interaction_shape.shape
	if shape is CircleShape2D:
		return point.length_squared() <= shape.radius * shape.radius
	if shape is RectangleShape2D:
		return Rect2(-shape.size / 2, shape.size).has_point(point)
	return false

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not is_instance_valid(interaction_shape) or not (interaction_shape.shape is CircleShape2D or interaction_shape.shape is RectangleShape2D):
		warnings.append("Assign a CollisionShape2D with a circle or rectangle for interaction reach.")
	if not is_instance_valid(status_marker):
		warnings.append("Assign a RecoveryStatusMarker that positions the equipment status symbol.")
	if (kind == "work_order") != (target == "work_order"):
		warnings.append("The work_order ID must use the work_order interaction kind.")
	return warnings

func set_status(value: String) -> void:
	if status != value:
		status = value
		_update_marker()


func _update_marker() -> void:
	if is_instance_valid(status_marker):
		if enabled:
			status_marker.configure_status(status, player_nearby, kind == "work_order")
		else:
			status_marker.hide()
