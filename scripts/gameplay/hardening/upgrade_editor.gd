class_name HardeningUpgradeEditor
extends Panel
## Chooses which of the bought upgrades are equipped, within the upgrade load (2 on Day 1, 2N on Day N).
## Hover an upgrade to read it, click one in the collection to equip it, click an equipped one to take it off.
## Upgrades marked * answer clues the player found in Investigation; the RECOMMENDED button shows only those.

const GOLD := Color(1, 0.8039216, 0.45882353, 1)
const ANY_LOAD := -1 # the "-" of the load dropdown
const HELP := "Click an upgrade in the collection to equip it. Click an equipped one to take it off. A * marks upgrades that answer clues you found."

var _state: HardeningState
var _rows: Array[String] = [] # collection row -> upgrade id

@onready var _title: Label = $UpgradesTitle
@onready var _equipped: GridContainer = $UpgradesPanel/ScrollContainer/UpgradesGrid
@onready var _list: ItemList = $Collection/ScrollContainer/UpgradesGrid
@onready var _recommended: Button = $Collection/RecommendedFilter
@onready var _load_filter: OptionButton = $Collection/CostFilter
@onready var _info_icon: TextureRect = $Info/Sprite
@onready var _info_name: Label = $Info/Name
@onready var _info_text: RichTextLabel = $Info/Description


func setup(state: HardeningState) -> void:
	_state = state
	CollectionList.style(_list, Vector2i(32, 32))
	_list.item_clicked.connect(_on_collection_clicked)
	_list.gui_input.connect(_on_collection_input)
	_recommended.toggle_mode = true
	_recommended.toggled.connect(_on_filter_changed)
	_load_filter.item_selected.connect(_on_filter_changed)
	_show_info("")
	refresh()


## Draws the equipped upgrades and the collection again.
func refresh() -> void:
	_title.text = _load_text()
	for tile in UpgradeTile.fill(_equipped, _state.equipped_list(), _state.upgrades):
		var id: String = tile.get_meta("id")
		tile.mouse_entered.connect(_show_info.bind(id))
		tile.gui_input.connect(_on_equipped_input.bind(id))
	_refresh_collection()


## The bought upgrades that are not equipped, lowest load first, through the filters.
func _refresh_collection() -> void:
	var scroll := _list.get_v_scroll_bar().value
	_list.clear()
	_rows.clear()
	var unequipped: Array = _state.owned_list("upgrade").filter(
		func(id: String) -> bool: return _state.upgrades.has(id) and not _state.equipped_list().has(id))
	unequipped.sort_custom(func(a: String, b: String) -> bool:
		var load_a := int(_state.upgrades[a].get("load", 0))
		var load_b := int(_state.upgrades[b].get("load", 0))
		return load_a < load_b if load_a != load_b else a < b)
	for id: String in unequipped:
		var info: Dictionary = _state.upgrades[id]
		var upgrade_load := int(info.get("load", 0))
		var recommended := _state.is_recommended(id)
		if _recommended.button_pressed and not recommended:
			continue
		var wanted := _wanted_load()
		if wanted != ANY_LOAD and upgrade_load != wanted:
			continue
		var index := _list.add_item("[%d]  %s%s" % [upgrade_load, info.get("name", id), "  *" if recommended else ""], UpgradeTile.icon(id))
		if recommended:
			_list.set_item_custom_fg_color(index, GOLD)
		_rows.append(id)
	if _rows.is_empty():
		var message := "Nothing to equip. Buy upgrades in the shop." if unequipped.is_empty() else "No upgrade matches the filters."
		_list.add_item(message, null, false)
	_restore_scroll.call_deferred(scroll)


func _restore_scroll(value: float) -> void:
	_list.get_v_scroll_bar().value = value


## The number picked in the dropdown ("-" is any load).
func _wanted_load() -> int:
	var text := _load_filter.get_item_text(_load_filter.selected)
	return ANY_LOAD if text == "-" else int(text)


func _on_filter_changed(_value: Variant) -> void:
	_refresh_collection()


func _on_collection_clicked(index: int, _at: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT and index < _rows.size():
		_equip(_rows[index])


## Hovering a row of the collection shows that upgrade in the info panel.
func _on_collection_input(event: InputEvent) -> void:
	var index := CollectionList.row_at(_list, event)
	if index >= 0 and index < _rows.size():
		_show_info(_rows[index])


func _on_equipped_input(event: InputEvent, id: String) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_state.equipped_list().erase(id)
		refresh()


func _equip(id: String) -> void:
	if _state.equipped_load() + int(_state.upgrades[id].get("load", 0)) > _state.upgrade_budget():
		_flash("LOAD FULL")
		return
	_state.equipped_list().append(id)
	refresh()


func _load_text() -> String:
	return "UPGRADES LOAD %d / %d" % [_state.equipped_load(), _state.upgrade_budget()]


## Shows a short message in place of the load, then puts the load back.
func _flash(message: String) -> void:
	_title.text = message
	await get_tree().create_timer(1.0).timeout
	_title.text = _load_text()


## The info panel: icon, name, load and what it does. An empty id shows the help text.
func _show_info(id: String) -> void:
	if id.is_empty() or not _state.upgrades.has(id):
		_info_icon.hide()
		_info_name.text = "Upgrades"
		_info_text.text = HELP
		return
	var info: Dictionary = _state.upgrades[id]
	_info_icon.show()
	_info_icon.texture = UpgradeTile.icon(id)
	_info_name.text = str(info.get("name", id))
	var text := "Load %d\n%s" % [int(info.get("load", 0)), info.get("text", "")]
	if _state.is_recommended(id):
		text += "\n\nRecommended: it answers clues you found."
	_info_text.text = text
