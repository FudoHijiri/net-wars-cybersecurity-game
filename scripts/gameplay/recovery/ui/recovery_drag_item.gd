class_name RecoveryDragItem
extends Button

## Something the player can drag onto a RecoveryDropSlot with the mouse.
## Keyboard and click players press it to pick it up, then press a slot to place it.
## Layout and look: tasks/parts/DragItem.tscn.

## Emitted when a drag starts on an item that is locked in place (locked = true).
signal drag_refused(item: RecoveryDragItem)

@export var item_id := ""
## A locked item cannot be dragged; trying explains why via drag_refused.
@export var locked := false


## What a drop slot receives. Null when the item can't be picked up right now.
func drag_payload() -> Variant:
	if disabled:
		return null
	if locked:
		drag_refused.emit(self)
		return null
	return {"recovery_item": self}


func _get_drag_data(_at_position: Vector2) -> Variant:
	var payload: Variant = drag_payload()
	if payload == null:
		return null
	var preview := Label.new()
	preview.text = text
	# The preview floats outside the task's tree, so copy this button's themed font.
	preview.add_theme_font_override("font", get_theme_font("font"))
	preview.add_theme_font_size_override("font_size", get_theme_font_size("font_size"))
	preview.add_theme_color_override("font_color", RecoveryStyle.YELLOW)
	set_drag_preview(preview)
	return payload


## A short wobble so a rejected move is visible as well as explained in text.
func bounce() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	for angle in [0.12, -0.12, 0.06, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.05)
