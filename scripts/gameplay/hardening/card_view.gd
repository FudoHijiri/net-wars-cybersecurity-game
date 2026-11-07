class_name CardView
extends Control
## One card, drawn from separate pieces: frame, art, cost orb, type icon and text.
## Call setup() after the card is in the tree.

const FRAME := "res://assets/cards/frames/frame_%s.png"
const ICON := "res://assets/cards/type_icons/type_icon_%s.png"
const ART := "res://assets/cards/art/art_%s.png"
const DARK_TEXT := Color(0.101960786, 0.10980392, 0.17254902)

@onready var _frame: TextureRect = $Frame
@onready var _art: TextureRect = $Art
@onready var _type_icon: TextureRect = $TypeIcon
@onready var _cost: Label = $CostLabel
@onready var _name: Label = $NameLabel
@onready var _text: Label = $EffectLabel


## card: {name, type, cost, text} plus the id the art is named after.
func setup(id: String, card: Dictionary) -> void:
	var type := str(card.get("type", "attack"))
	_frame.texture = load(FRAME % type)
	_type_icon.texture = load(ICON % type)
	_art.texture = load(ART % id)
	_cost.text = str(int(card.get("cost", 0))) # JSON numbers load as floats
	_name.text = str(card.get("name", id))
	_text.text = str(card.get("text", ""))
	# The spell band is amber, so its name needs dark text.
	_name.add_theme_color_override("font_color", DARK_TEXT if type == "spell" else Color.WHITE)
