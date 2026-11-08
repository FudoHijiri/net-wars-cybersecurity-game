class_name HardeningDeck
extends Panel
## The Build Hub: the deck as a 3x3 grid of cards, its stats, and the upgrades that are equipped.

var _state: HardeningState

@onready var _grid: GridContainer = $CardsPanel/CardGrid
@onready var _title: Label = $DeckTitle
@onready var _upgrade_load: Label = $Upgrades/UpgradeLoad
@onready var _upgrade_grid: GridContainer = $Upgrades/UpgradesScroll/GridContainer


func setup(state: HardeningState) -> void:
	_state = state
	refresh()


## Draws the deck and the equipped upgrades again (they change in the editors).
func refresh() -> void:
	var deck := _state.sorted_ids(_state.deck_list())
	DeckGrid.fill(_grid, deck, _state.cards, HardeningState.DECK_SIZE)
	_title.text = "DECK  %d / %d" % [mini(deck.size(), HardeningState.DECK_SIZE), HardeningState.DECK_SIZE]
	_update_stats(deck)
	_refresh_upgrades()


func _refresh_upgrades() -> void:
	_upgrade_load.text = "UPGRADE LOAD %d / %d" % [_state.equipped_load(), _state.upgrade_budget()]
	_upgrade_grid.columns = 5
	for tile in UpgradeTile.fill(_upgrade_grid, _state.equipped_list(), _state.upgrades):
		tile.tooltip_text = str(_state.upgrades[tile.get_meta("id")].get("text", ""))


## Fills the Stats panel from the deck: cards per type, the cost curve and the average cost.
func _update_stats(deck: Array) -> void:
	var per_type := {"offensive": 0, "defensive": 0, "utility": 0}
	var per_cost := [0, 0, 0, 0, 0]
	var total_cost := 0
	var count := 0
	for id in deck:
		if not _state.cards.has(id):
			continue
		var card: Dictionary = _state.cards[id]
		var cost := int(card.get("cost", 0)) # JSON numbers load as floats
		per_type[card.get("type", "offensive")] += 1
		per_cost[clampi(cost, 0, 4)] += 1
		total_cost += cost
		count += 1
	$Stats/DeckStats/DamageInDeck/Label.text = "%d Offensive" % per_type["offensive"]
	$Stats/DeckStats/DefenseInDeck/Label.text = "%d Defensive" % per_type["defensive"]
	$Stats/DeckStats/UtilityInDeck/Label.text = "%d Utility" % per_type["utility"]
	var average := float(total_cost) / count if count > 0 else 0.0
	$"Stats/DeckStats/Average Cost/Label".text = "Avg. Cost - %.1f" % average
	for cost in 5:
		($Stats/CostCurveRow.get_child(cost) as ProgressBar).value = per_cost[cost]
