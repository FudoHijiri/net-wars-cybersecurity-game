class_name WordChip
extends Button

## A word the player can drag into a blank of the report, or click and then click a blank.
## Drag data: {type, chip_id, from_slot}. from_slot is 0 for a chip dragged out of the tray.

const DRAG_TYPE := "case_chip"
const THEME := preload("res://scenes/gameplay/investigation/report_theme.tres")

var chip_id := ""
var chip_label := ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled:
		return null
	set_drag_preview(make_drag_preview(chip_label))
	return {"type": DRAG_TYPE, "chip_id": chip_id, "from_slot": 0}


## The small picture of the word that follows the mouse while dragging. It lives outside
## the screen's own tree, so it carries the theme with it.
static func make_drag_preview(label_text: String) -> Control:
	var preview := Button.new()
	preview.theme = THEME
	preview.theme_type_variation = &"ChipButtonPicked"
	preview.text = label_text
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.focus_mode = Control.FOCUS_NONE
	return preview
