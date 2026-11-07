extends Control
## Hardening phase. For now: the Build Hub shows the deck as a 3x3 grid of cards.

const CARD_SCENE := preload("res://scenes/gameplay/hardening/Card.tscn")
const CARDS_PATH := "res://data/cards.json"
const EMPTY_FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const DECK_SIZE := 9

@onready var _grid: GridContainer = $Deck/CardsPanel/CardGrid
@onready var _deck_label: Label = $Deck/DeckTitle


func _ready() -> void:
	var data := _load_cards()
	var cards: Dictionary = data.get("cards", {})
	var deck: Array = data.get("starter_deck", [])
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 2)
	_grid.add_theme_constant_override("v_separation", 2)
	for slot in DECK_SIZE:
		if slot < deck.size() and cards.has(deck[slot]):
			var card: CardView = CARD_SCENE.instantiate()
			_grid.add_child(card)
			card.setup(deck[slot], cards[deck[slot]])
		else:
			_grid.add_child(_empty_slot())
	_deck_label.text = "DECK  %d / %d" % [mini(deck.size(), DECK_SIZE), DECK_SIZE]


func _load_cards() -> Dictionary:
	var file := FileAccess.open(CARDS_PATH, FileAccess.READ)
	if file == null:
		push_error("Hardening: cannot open %s" % CARDS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _empty_slot() -> Control:
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
