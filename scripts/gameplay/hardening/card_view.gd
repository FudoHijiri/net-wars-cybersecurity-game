class_name CardView
extends Control
## One card, drawn from separate pieces: frame, art, cost orb, type icon and text.
## Call setup() after the card is in the tree.

const FRAME := "res://assets/cards/frames/frame_%s.png"
const ICON := "res://assets/cards/type_icons/type_icon_%s.png"
const ART := "res://assets/cards/art/art_%s.png"
const DARK_TEXT := Color(0.101960786, 0.10980392, 0.17254902)
## Card type -> the name used in the frame and icon file names.
const TYPE_FILE := {"offensive": "attack", "defensive": "defense", "utility": "spell"}

@onready var _frame: TextureRect = $Frame
@onready var _art: TextureRect = $Art
@onready var _type_icon: TextureRect = $TypeIcon
@onready var _cost: Label = $CostLabel
@onready var _name: Label = $NameLabel
@onready var _text: Label = $EffectLabel


## Lets the card itself take the mouse (clicks and hover): its parts would otherwise catch them first.
func make_clickable() -> void:
	for part: Control in get_children():
		part.mouse_filter = Control.MOUSE_FILTER_IGNORE


## card: {name, type, cost, text} plus the id the art is named after.
func setup(id: String, card: Dictionary) -> void:
	var type := str(card.get("type", "offensive"))
	var file: String = TYPE_FILE[type]
	_frame.texture = load(FRAME % file)
	_type_icon.texture = load(ICON % file)
	_art.texture = load(ART % id)
	_cost.text = str(int(card.get("cost", 0))) # JSON numbers load as floats
	_name.text = str(card.get("name", id))
	_text.text = str(card.get("text", ""))
	# The utility band is amber, so its name needs dark text. The label's own settings win over a theme
	# color, and the settings resource is shared by every card, so each card gets its own copy.
	var settings: LabelSettings = _name.label_settings.duplicate()
	settings.font_color = DARK_TEXT if type == "utility" else Color.WHITE
	_name.label_settings = settings
