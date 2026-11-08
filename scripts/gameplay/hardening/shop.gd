class_name HardeningShop
extends Panel
## The shop: cards and upgrades for Security Points. A click on a tile selects it; the BUY button buys
## the selected one. The rows are filled from the first tile of each row (the one laid out in the editor).

## The wallet changed (something was bought).
signal changed

const CARD_SCENE := preload("res://scenes/gameplay/hardening/Card.tscn")
const UPGRADE_ICON := "res://assets/upgrades/icon_%s.png"
const DIM := Color(0.7, 0.7, 0.7)

var _state: HardeningState
var _tiles: Dictionary = {} # "card:<id>" or "upgrade:<id>" -> {"tile": the tile, "price": its price button}
var _selected := "" # the key of the tile that was clicked, or ""
var _typing: Tween

@onready var _card_row: HBoxContainer = $ShopContent/CardsScroll/HBoxContainer
@onready var _upgrade_row: HBoxContainer = $ShopContent/UpgradeShopScroll/UpgradesColumn
@onready var _buy_title: Label = $ShopContent/Panel/HBoxContainer/VBoxContainer/Title
@onready var _buy_text: Label = $ShopContent/Panel/HBoxContainer/VBoxContainer/Description
@onready var _buy_hint: Label = $ShopContent/Panel/HBoxContainer/VBoxContainer/Hint
@onready var _buy_button: Button = $ShopContent/Panel/PriceButton
@onready var _dialogue: RichTextLabel = $Dialogue/Content


func setup(state: HardeningState) -> void:
	_state = state
	_buy_button.pressed.connect(_buy)

	var card_template: Control = _card_row.get_child(0)
	var price_template: Button = card_template.get_node("PriceButton")
	for id: String in _state.shop_cards:
		if not _state.cards.has(id):
			continue
		var tile := VBoxContainer.new()
		var view: CardView = CARD_SCENE.instantiate()
		tile.add_child(view)
		var price: Button = price_template.duplicate()
		tile.add_child(price)
		_card_row.add_child(tile)
		view.setup(id, _state.cards[id])
		view.make_clickable()
		view.gui_input.connect(_on_tile_input.bind("card:" + id))
		price.pressed.connect(_select.bind("card:" + id))
		_tiles["card:" + id] = {"tile": tile, "price": price}
	card_template.queue_free()

	var upgrade_template: Control = _upgrade_row.get_child(0)
	for id: String in _state.shop_upgrades:
		if not _state.upgrades.has(id):
			continue
		var tile: Control = upgrade_template.duplicate()
		_upgrade_row.add_child(tile)
		var icon: TextureRect = tile.get_node("UpgradeImage")
		if ResourceLoader.exists(UPGRADE_ICON % id):
			icon.texture = load(UPGRADE_ICON % id)
		icon.mouse_filter = Control.MOUSE_FILTER_STOP
		icon.gui_input.connect(_on_tile_input.bind("upgrade:" + id))
		tile.get_node("Name").text = str(_state.upgrades[id].get("name", id))
		var price: Button = tile.get_node("PriceButton")
		price.pressed.connect(_select.bind("upgrade:" + id))
		_tiles["upgrade:" + id] = {"tile": tile, "price": price}
	upgrade_template.queue_free()
	refresh()


## Carla greets the player when the shop opens.
func greet() -> void:
	_say(_pick("greeting"))


## Carla says a line, typed out quickly. The next line cancels the one being typed.
func _say(text: String) -> void:
	if _typing != null:
		_typing.kill()
	_dialogue.text = text
	_dialogue.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_dialogue, "visible_ratio", 1.0, maxf(0.3, text.length() / 70.0))


func _pick(list: String) -> String:
	var lines: Array = _state.shop_lines.get(list, [])
	return str(lines.pick_random()) if not lines.is_empty() else ""


## What Carla says about one card or upgrade, from the shop lines.
func _line_for(key: String) -> String:
	var group := "cards" if key.begins_with("card:") else "upgrades"
	return str(_state.shop_lines.get(group, {}).get(key.get_slice(":", 1), ""))


## Prices, OWNED marks and the BUY panel.
func refresh() -> void:
	_refresh_tiles()
	_refresh_buy_panel(GameState.wallet())


func _refresh_tiles() -> void:
	for key: String in _tiles:
		var button: Button = _tiles[key]["price"]
		button.text = "OWNED" if _is_sold_out(key) else "%d SP" % int(_info(key).get("price", 0))
		(_tiles[key]["tile"] as Control).modulate = Color.WHITE if _selected.is_empty() or key == _selected else DIM


## The panel at the bottom: what is selected, what the player owns, and the BUY button.
func _refresh_buy_panel(wallet: int) -> void:
	if _selected.is_empty():
		_buy_title.text = "Nothing selected"
		_buy_text.text = "Click a card or an upgrade."
		_buy_hint.text = "You have %d SP." % wallet
		_buy_button.text = "BUY"
		_buy_button.disabled = true
		return
	var info := _info(_selected)
	var is_card := _selected.begins_with("card:")
	var id := _selected.get_slice(":", 1)
	var price := int(info.get("price", 0))
	var sold_out := _is_sold_out(_selected)
	_buy_title.text = str(info.get("name", id))
	_buy_text.text = str(info.get("text", ""))
	if is_card:
		_buy_hint.text = "You own %d.  You have %d SP." % [_state.copies_owned(id), wallet]
	else:
		_buy_hint.text = "Upgrade load %d.  You have %d SP." % [int(info.get("load", 0)), wallet]
	if sold_out:
		_buy_button.text = "OWNED"
	else:
		_buy_button.text = "BUY %d SP" % price if wallet >= price else "NEED %d SP" % price
	_buy_button.disabled = sold_out or wallet < price


func _on_tile_input(event: InputEvent, key: String) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_select(key)


func _select(key: String) -> void:
	_selected = key
	refresh()
	var line := _line_for(key)
	if not line.is_empty():
		_say(line)


func _buy() -> void:
	if _selected.is_empty() or _is_sold_out(_selected):
		return
	if GameState.spend_points(int(_info(_selected).get("price", 0))):
		_state.owned_list(_selected.get_slice(":", 0)).append(_selected.get_slice(":", 1))
		_say(_pick("bought_card" if _selected.begins_with("card:") else "bought_upgrade"))
		changed.emit()
	refresh()


func _info(key: String) -> Dictionary:
	var source := _state.cards if key.begins_with("card:") else _state.upgrades
	return source.get(key.get_slice(":", 1), {})


## Cards can be bought again and again; an upgrade is bought once.
func _is_sold_out(key: String) -> bool:
	return key.begins_with("upgrade:") and _state.owned_list("upgrade").has(key.get_slice(":", 1))
