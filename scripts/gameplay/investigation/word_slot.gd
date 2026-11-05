class_name WordSlot
extends Button

## A blank in the report sentence. It accepts one WordChip, by drop or by click (the report does
## the clicking). A filled slot can be dragged out; a locked (correct) slot cannot be changed.

signal chip_dropped(slot_number: int, data: Dictionary)

var slot_number := 0
var chip_id := "" # empty while the blank is empty
var chip_label := ""
var locked := false


func _get_drag_data(_at_position: Vector2) -> Variant:
	if chip_id.is_empty() or locked:
		return null
	set_drag_preview(WordChip.make_drag_preview(chip_label))
	return {"type": WordChip.DRAG_TYPE, "chip_id": chip_id, "from_slot": slot_number}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return not locked and data is Dictionary and data.get("type", "") == WordChip.DRAG_TYPE


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	chip_dropped.emit(slot_number, data)
