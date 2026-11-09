@tool
class_name RecoveryEquipment
extends Node2D

@export var equipment_id := "":
	set(value):
		equipment_id = value
		_sync_interaction()
@export_enum("monitoring", "access", "servers", "network", "backup", "workbench", "decoration") var eligible_group := "access":
	set(value):
		eligible_group = value
		_sync_interaction()
## Default minigame for this machine. The Day's equipment_selection can reassign it when Recovery starts.
@export var assigned_task := "file_server":
	set(value):
		assigned_task = value
		_sync_interaction()
@export var display_name := "Equipment":
	set(value):
		display_name = value
		_sync_interaction()
@export var interaction_enabled := true:
	set(value):
		interaction_enabled = value
		_sync_interaction()
@export var interaction: RecoveryInteractable:
	set(value):
		interaction = value
		_sync_interaction()
@export var static_sprite: Sprite2D
@export var activity_sprite: AnimatedSprite2D
@export var animate_activity := true

func _ready() -> void:
	_sync_interaction()
	if is_instance_valid(activity_sprite):
		activity_sprite.visible = animate_activity
		static_sprite.visible = not animate_activity
		if animate_activity and not Engine.is_editor_hint():
			activity_sprite.play("activity")

func _validate_property(property: Dictionary) -> void:
	if property.name == "assigned_task":
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = RecoveryData.enum_hint()

func _sync_interaction() -> void:
	if not is_instance_valid(interaction):
		return
	interaction.equipment_id = equipment_id
	interaction.equipment_group = eligible_group
	interaction.target = assigned_task
	interaction.title = display_name
	interaction.set_enabled(interaction_enabled)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if interaction_enabled and equipment_id.is_empty() and owner != null:
		warnings.append("Give this equipment instance a unique equipment ID in the room scene.")
	if not is_instance_valid(interaction):
		warnings.append("Assign this equipment's Interaction Area2D.")
	return warnings
