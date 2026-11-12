class_name HardeningDeck
extends Panel
## The Build Hub: the deck as a 3x3 grid of cards, its stats, and the upgrades that are equipped.

var _state: HardeningState
var _upgrade_hint := Label.new() # shown only while no upgrade is equipped
var upgrade_columns := 5 # tiles per row of the equipped upgrades

@onready var _grid: GridContainer = $CardsPanel/CardGrid
@onready var _title: Label = $DeckTitle
@onready var _upgrade_load: Label = $Upgrades/UpgradeLoad
@onready var _upgrade_grid: GridContainer = $Upgrades/UpgradesScroll/GridContainer


func setup(state: HardeningState) -> void:
	_state = state
	_upgrade_hint.text = "Nothing equipped yet. Open EDIT UPGRADES to equip upgrades."
	_upgrade_hint.label_settings = _upgrade_load.label_settings
	_upgrade_hint.modulate = Color(1, 1, 1, 0.55)
	_upgrade_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_upgrade_hint.position = $Upgrades/UpgradesScroll.position + Vector2(4, 4)
	$Upgrades.add_child(_upgrade_hint)
	refresh()


## The line shown while no upgrade is equipped.
func set_upgrade_hint(text: String, wrap_width: float = 0.0) -> void:
	_upgrade_hint.text = text
	if wrap_width > 0.0: # a narrower panel: the line wraps
		_upgrade_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_upgrade_hint.custom_minimum_size.x = wrap_width


## Draws the deck and the equipped upgrades again (they change in the editors).
func refresh() -> void:
	var deck := _state.sorted_ids(_state.deck_list())
	DeckGrid.fill(_grid, deck, _state.cards, HardeningState.DECK_SIZE)
	_title.text = "DECK  %d / %d" % [mini(deck.size(), HardeningState.DECK_SIZE), HardeningState.DECK_SIZE]
	_update_stats(deck)
	_refresh_upgrades()


func _refresh_upgrades() -> void:
	_upgrade_load.text = "UPGRADE LOAD %d / %d" % [_state.equipped_load(), _state.upgrade_budget()]
	_upgrade_grid.columns = upgrade_columns
	_upgrade_hint.visible = _state.equipped_list().is_empty()
	for tile in UpgradeTile.fill(_upgrade_grid, _state.equipped_list(), _state.upgrades):
		tile.tooltip_text = str(_state.upgrades[tile.get_meta("id")].get("text", ""))


## Fills the Stats panel from the deck: cards per type and the cost curve.
func _update_stats(deck: Array) -> void:
	var per_type := {"offensive": 0, "defensive": 0, "utility": 0}
	var per_cost := [0, 0, 0, 0, 0]
	for id in deck:
		if not _state.cards.has(id):
			continue
		var card: Dictionary = _state.cards[id]
		var cost := int(card.get("cost", 0)) # JSON numbers load as floats
		per_type[card.get("type", "offensive")] += 1
		per_cost[clampi(cost, 0, 4)] += 1
	$Stats/DeckStats/DamageInDeck/Label.text = "%d Offensive" % per_type["offensive"]
	$Stats/DeckStats/DefenseInDeck/Label.text = "%d Defensive" % per_type["defensive"]
	$Stats/DeckStats/UtilityInDeck/Label.text = "%d Utility" % per_type["utility"]
	for cost in 5:
		($Stats/CostCurveRow.get_child(cost) as ProgressBar).value = per_cost[cost]
