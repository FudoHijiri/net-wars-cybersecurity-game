class_name HardeningState
extends RefCounted
## What the Hardening panels share: the card and upgrade data, and what the player owns and has chosen.
## With a save slot loaded everything is kept in the save (SaveManager.data); a scene run alone keeps it here.

const CARDS_PATH := "res://data/cards.json"
const UPGRADES_PATH := "res://data/upgrades.json"
const SHOP_LINES_PATH := "res://data/shop_dialogue.json"
const DECK_SIZE := 9
## The Response phase draws 5 cards, so the phase cannot end with fewer in the deck.
const MIN_DECK := 5

var cards: Dictionary = {}
var starter_deck: Array = []
var shop_cards: Array = []
var upgrades: Dictionary = {}
var shop_upgrades: Array = []
## What Carla says in the shop (data/shop_dialogue.json).
var shop_lines: Dictionary = {}

var _local := {"owned_cards": [], "unlocked_passives": [], "equipped_passives": [], "deck": []}
var _deck_checked := false # the deck was looked at once, so an empty one is the player's own


func _init() -> void:
	var card_data := _load_json(CARDS_PATH)
	cards = card_data.get("cards", {})
	starter_deck = card_data.get("starter_deck", [])
	shop_cards = card_data.get("shop", [])
	var upgrade_data := _load_json(UPGRADES_PATH)
	upgrades = upgrade_data.get("upgrades", {})
	shop_upgrades = upgrade_data.get("shop", [])
	shop_lines = _load_json(SHOP_LINES_PATH)


## One of the save's lists: "owned_cards" (bought), "unlocked_passives" (bought upgrades), "equipped_passives" or "deck".
func list(key: String) -> Array:
	if SaveManager.current_slot >= 0:
		return SaveManager.data[key]
	return _local[key]


## The bought cards (kind "card") or upgrades (any other kind).
func owned_list(kind: String) -> Array:
	return list("owned_cards" if kind == "card" else "unlocked_passives")


## The deck, one id per copy. A new game has no deck yet, so the first call fills it with the starter deck.
## After that an empty deck stays empty: the player may take every card out (the phase cannot end below MIN_DECK).
func deck_list() -> Array:
	var deck := list("deck")
	if not _deck_checked:
		_deck_checked = true
		if deck.is_empty():
			deck.append_array(starter_deck)
	return deck


## The upgrade load the player may use: 2 on Day 1, 2N on Day N.
func upgrade_budget() -> int:
	return 2 * GameState.current_day


## The upgrades that are on, once each. They are chosen from the bought ones in the Upgrade Editor.
func equipped_list() -> Array:
	return list("equipped_passives")


func equipped_load() -> int:
	var total := 0
	for id: String in equipped_list():
		total += int(upgrades.get(id, {}).get("load", 0))
	return total


## True when the player found one of the Investigation clues the upgrade answers. With a save it reads the
## clues kept in it, so a save resumed in Hardening still knows them.
func is_recommended(id: String) -> bool:
	for clue: String in upgrades.get(id, {}).get("clues", []):
		if list("found_clues").has(clue) if SaveManager.current_slot >= 0 else GameState.is_marked(clue):
			return true
	return false


## How many copies of a card the player has: the starter deck plus what was bought.
func copies_owned(id: String) -> int:
	return starter_deck.count(id) + list("owned_cards").count(id)


## How many copies are not in the deck.
func in_collection(id: String) -> int:
	return copies_owned(id) - deck_list().count(id)


## Every card the player has, once each.
func owned_card_ids() -> Array:
	var ids: Array = []
	for id: String in starter_deck + list("owned_cards"):
		if cards.has(id) and not ids.has(id):
			ids.append(id)
	return ids


## Lowest energy cost first, then by id so copies of a card sit together.
func sorted_ids(ids: Array) -> Array:
	var result := ids.duplicate()
	result.sort_custom(func(a: String, b: String) -> bool:
		var cost_a := int(cards.get(a, {}).get("cost", 0)) # JSON numbers load as floats
		var cost_b := int(cards.get(b, {}).get("cost", 0))
		if cost_a != cost_b:
			return cost_a < cost_b
		return a < b)
	return result


func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Hardening: cannot open %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}
