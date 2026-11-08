class_name HardeningDeckEditor
extends Panel
## Chooses the deck from the cards the player owns. Hover a card to read it, click a card in the
## collection to put it in the deck, click a card in the deck to take it out.

## The player pressed LEAVE.
signal leave_requested

const ART := "res://assets/cards/art/art_%s.png"
const ANY_COST := 5 # the id of "-" in the cost filter
const TYPE_NAMES := {"offensive": "Offensive", "defensive": "Defensive", "utility": "Utility"}
const HELP := "Click a card in the collection to add it to the deck. Click a card in the deck to take it out."

var _state: HardeningState
var _rows: Array[String] = [] # collection row -> card id

@onready var _grid: GridContainer = $CardsPanel/CardGrid
@onready var _title: Label = $DeckTitle
@onready var _list: ItemList = $Collection/ScrollContainer/CardGrid
@onready var _offensive: Button = $Collection/OffensiveFilter
@onready var _defensive: Button = $Collection/DefensiveFilter
@onready var _utility: Button = $Collection/UtilityFilter
@onready var _cost: OptionButton = $Collection/CostFilter
@onready var _info_card: CardView = $Info/Card
@onready var _info_name: Label = $Info/Name
@onready var _info_text: RichTextLabel = $Info/Description


func setup(state: HardeningState) -> void:
	_state = state
	CollectionList.style(_list, Vector2i(64, 44))
	_list.item_clicked.connect(_on_collection_clicked)
	_list.gui_input.connect(_on_collection_input)
	for button: Button in [_offensive, _defensive, _utility]:
		button.toggle_mode = true
		button.toggled.connect(_on_filter_changed)
	_cost.item_selected.connect(_on_filter_changed)
	$Buttons/LeaveButton.pressed.connect(leave_requested.emit)
	_show_info("")
	refresh()


## Draws the deck and the collection again.
func refresh() -> void:
	var deck := _state.sorted_ids(_state.deck_list())
	var views := DeckGrid.fill(_grid, deck, _state.cards, HardeningState.DECK_SIZE)
	for i in views.size():
		views[i].make_clickable()
		views[i].mouse_entered.connect(_show_info.bind(deck[i]))
		views[i].gui_input.connect(_on_deck_card_input.bind(deck[i]))
	_title.text = _deck_text()
	_refresh_collection()


func _refresh_collection() -> void:
	var scroll := _list.get_v_scroll_bar().value
	_list.clear()
	_rows.clear()
	for id: String in _state.sorted_ids(_state.owned_card_ids()):
		var left := _state.in_collection(id)
		var card: Dictionary = _state.cards[id]
		if left <= 0 or not _passes_filters(card):
			continue
		var index := _list.add_item("[%d]  %s  x%d" % [int(card.get("cost", 0)), card.get("name", id), left]) # [energy cost]
		_list.set_item_icon(index, load(ART % id))
		_rows.append(id)
	_restore_scroll.call_deferred(scroll)


func _restore_scroll(value: float) -> void:
	_list.get_v_scroll_bar().value = value


func _passes_filters(card: Dictionary) -> bool:
	var types: Array[String] = []
	if _offensive.button_pressed:
		types.append("offensive")
	if _defensive.button_pressed:
		types.append("defensive")
	if _utility.button_pressed:
		types.append("utility")
	if not types.is_empty() and not types.has(str(card.get("type", ""))):
		return false
	var cost_id := _cost.get_item_id(_cost.selected)
	return cost_id == ANY_COST or int(card.get("cost", 0)) == cost_id


func _on_filter_changed(_value: Variant) -> void:
	_refresh_collection()


func _on_collection_clicked(index: int, _at: Vector2, button: int) -> void:
	if button == MOUSE_BUTTON_LEFT and index < _rows.size():
		_add(_rows[index])


## Hovering a row of the collection shows that card in the info panel.
func _on_collection_input(event: InputEvent) -> void:
	var index := CollectionList.row_at(_list, event)
	if index >= 0 and index < _rows.size():
		_show_info(_rows[index])


func _on_deck_card_input(event: InputEvent, id: String) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_remove(id)


func _add(id: String) -> void:
	if _state.deck_list().size() >= HardeningState.DECK_SIZE:
		_flash("DECK FULL")
		return
	_state.deck_list().append(id)
	refresh()


func _remove(id: String) -> void:
	_state.deck_list().erase(id) # takes out one copy
	refresh()


func _deck_text() -> String:
	return "DECK  %d / %d" % [_state.deck_list().size(), HardeningState.DECK_SIZE]


## Shows a short message in place of the deck count, then puts the count back.
func _flash(message: String) -> void:
	_title.text = message
	await get_tree().create_timer(1.0).timeout
	_title.text = _deck_text()


## The info panel: the card with its name and what it does. An empty id shows the help text.
func _show_info(id: String) -> void:
	if id.is_empty() or not _state.cards.has(id):
		_info_card.hide()
		_info_name.text = "Deck Editor"
		_info_text.text = HELP
		return
	var card: Dictionary = _state.cards[id]
	var type := str(card.get("type", "offensive"))
	_info_card.show()
	_info_card.setup(id, card)
	_info_name.text = str(card.get("name", id))
	_info_text.text = "%s  -  %d energy\n%s" % [TYPE_NAMES.get(type, type), int(card.get("cost", 0)), card.get("text", "")]
