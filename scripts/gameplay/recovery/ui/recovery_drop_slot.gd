class_name RecoveryDropSlot
extends Button

## A place a RecoveryDragItem can go. A mouse drop emits item_dropped; pressing the
## slot (click or Enter) emits pressed as usual, so the task can place the picked item.
## Layout and look: tasks/parts/DropSlot.tscn.

signal item_dropped(item: RecoveryDragItem)

@export var slot_id := ""


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get("recovery_item") is RecoveryDragItem


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data["recovery_item"])


## A short wobble so a refused action is visible as well as explained in text.
func bounce() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	for angle in [0.08, -0.08, 0.04, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.05)
