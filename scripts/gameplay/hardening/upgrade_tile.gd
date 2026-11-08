class_name UpgradeTile
extends RefCounted
## One equipped upgrade as a small tile: its icon and name. Used by the Build Hub and the Upgrade Editor.

const ICON := "res://assets/upgrades/icon_%s.png"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const LINE := Color(0.3372549, 0.42352942, 0.5254902)


## The icon of an upgrade, or null when it has none yet.
static func icon(id: String) -> Texture2D:
	return load(ICON % id) if ResourceLoader.exists(ICON % id) else null


## One tile per id in the grid; the old tiles go. Ids that are not upgrades are skipped. Each tile keeps its id
## in the meta "id". Returns the tiles.
static func fill(grid: GridContainer, ids: Array, upgrades: Dictionary) -> Array[Control]:
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	var tiles: Array[Control] = []
	for id: String in ids:
		if upgrades.has(id):
			var tile := make(id, upgrades[id])
			tile.set_meta("id", id)
			grid.add_child(tile)
			tiles.append(tile)
	return tiles


## info is the upgrade's entry in upgrades.json. The tile takes the mouse itself (clicks and hover).
static func make(id: String, info: Dictionary) -> Control:
	var tile := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101960786, 0.10980392, 0.17254902, 1)
	style.set_border_width_all(1)
	style.border_color = LINE
	style.set_content_margin_all(2)
	tile.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(box)
	var picture := TextureRect.new()
	picture.texture = icon(id)
	picture.custom_minimum_size = Vector2(32, 32)
	picture.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(picture)
	var label := Label.new()
	label.text = str(info.get("name", id))
	label.custom_minimum_size = Vector2(60, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 6)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return tile
