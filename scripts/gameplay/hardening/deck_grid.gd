class_name DeckGrid
extends RefCounted
## Fills a 3-column grid with cards and empty slots. Used by the Build Hub and the Deck Editor.

const CARD_SCENE := preload("res://scenes/gameplay/hardening/Card.tscn")
const EMPTY_FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")


## One card per id, then empty slots up to `slots`. Returns the cards, in the order of `ids`.
static func fill(grid: GridContainer, ids: Array, cards: Dictionary, slots: int) -> Array[CardView]:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	var views: Array[CardView] = []
	for slot in slots:
		if slot < ids.size() and cards.has(ids[slot]):
			var view: CardView = CARD_SCENE.instantiate()
			grid.add_child(view)
			view.setup(ids[slot], cards[ids[slot]])
			views.append(view)
		else:
			grid.add_child(_empty_slot())
	return views


static func _empty_slot() -> Control:
	var slot := Panel.new()
	slot.custom_minimum_size = Vector2(72, 100)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.set_border_width_all(1)
	style.border_color = Color(0.3372549, 0.42352942, 0.5254902)
	slot.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = "Empty"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", EMPTY_FONT)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(0.3372549, 0.42352942, 0.5254902))
	slot.add_child(label)
	return slot
