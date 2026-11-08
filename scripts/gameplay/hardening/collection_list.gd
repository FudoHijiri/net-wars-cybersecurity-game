class_name CollectionList
extends RefCounted
## The ItemList of the Deck Editor and the Upgrade Editor: one row per card or upgrade, with its picture.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")


static func style(list: ItemList, icon_size: Vector2i) -> void:
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.max_columns = 1
	list.icon_mode = ItemList.ICON_MODE_LEFT
	list.fixed_icon_size = icon_size
	list.add_theme_font_override("font", FONT)
	list.add_theme_font_size_override("font_size", 6)


## The row under the mouse for a mouse motion event of the list, or -1 (for another kind of event too).
static func row_at(list: ItemList, event: InputEvent) -> int:
	var motion := event as InputEventMouseMotion
	return list.get_item_at_position(motion.position, true) if motion != null else -1
