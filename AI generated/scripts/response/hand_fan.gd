class_name HandFan
extends Control
## The player's hand, fanned out along the bottom of the screen. The card under the mouse pops
## up, grows to twice its size and shows a short explanation next to it. Click it to play it.

signal card_clicked(index: int)

const CARD_SCENE := preload("res://scenes/gameplay/hardening/Card.tscn")
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const CENTER_X := 320.0
const BASE_Y := 366.0 # bottom centre of a resting card (its bottom edge is just off screen)
const SPACING := 42.0 # distance between two cards in the fan
const SINK := 3.0 # how far a card sinks for each step (squared) from the middle
const TILT := 0.07 # radians of rotation per step from the middle, 0 for no rotation
const POP_SCALE := 2.0
const POP_Y := 358.0 # bottom centre of the card under the mouse
const HIDDEN_Y := 480.0 # where the cards wait during the enemy turn
const SMOOTH := 16.0
const TIP_SIZE := Vector2(112, 66)
const EXPLAIN := {
	"damage": "Damage lowers the threat's HP.",
	"block": "Block absorbs hits until the enemy's turn is over.",
	"draw": "Draw takes cards from your deck right now.",
}

var enabled := true
var energy := 3: # the cards that cost more than this are dimmed
	set(value):
		energy = value
		_dim_cards()

var _views: Array[CardView] = []
var _data: Array[Dictionary] = []
var _hover := -1
var _hover_was_set := false
var _tip := Panel.new()
var _tip_label := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101960786, 0.10980392, 0.17254902, 1)
	style.set_border_width_all(1)
	style.border_color = Color(1, 0.8039216, 0.45882353, 1)
	_tip.add_theme_stylebox_override("panel", style)
	_tip.size = TIP_SIZE
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.z_index = 100
	_tip.hide()
	add_child(_tip)
	_tip_label.add_theme_font_override("font", FONT)
	_tip_label.add_theme_font_size_override("font_size", 6)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.position = Vector2(5, 4)
	_tip_label.size = TIP_SIZE - Vector2(10, 8)
	_tip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_child(_tip_label)


## Replaces the hand. ids are card ids, cards is the card table of data/cards.json.
func set_hand(ids: Array, cards: Dictionary) -> void:
	for view in _views:
		view.queue_free()
	_views.clear()
	_data.clear()
	for id: String in ids:
		add_card(id, cards[id])
	_hover = -1


func card_count() -> int:
	return _views.size()


## Takes one card out of the hand (it was played).
func remove_card(index: int) -> void:
	_views[index].queue_free()
	_views.remove_at(index)
	_data.remove_at(index)
	_hover = -1


## Adds one card to the end of the hand (a card that draws).
func add_card(id: String, card: Dictionary) -> void:
	var view: CardView = CARD_SCENE.instantiate()
	add_child(view)
	view.setup(id, card)
	view.pivot_offset = Vector2(36, 100)
	view.position = Vector2(CENTER_X, HIDDEN_Y) - view.pivot_offset # the cards slide in from below
	_ignore_mouse(view)
	_views.append(view)
	_data.append(card)
	_dim_cards()


func _ignore_mouse(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_mouse(child)


func _dim_cards() -> void:
	for i in _views.size():
		_views[i].modulate = Color.WHITE if int(_data[i].get("cost", 0)) <= energy else Color(0.5, 0.5, 0.6, 1)


func _process(delta: float) -> void:
	_update_hover()
	var blend := 1.0 - exp(-SMOOTH * delta)
	var count := _views.size()
	for i in count:
		var step := i - (count - 1) / 2.0
		var anchor := Vector2(CENTER_X + step * SPACING, BASE_Y + step * step * SINK)
		var target_scale := 1.0
		var target_rotation := step * TILT
		var z := i
		if not enabled:
			anchor.y = HIDDEN_Y
		elif i == _hover:
			anchor = Vector2(clampf(anchor.x, 36.0 * POP_SCALE, 640.0 - 36.0 * POP_SCALE), POP_Y)
			target_scale = POP_SCALE
			target_rotation = 0.0
			z = 50
		var view := _views[i]
		view.z_index = z
		view.position = view.position.lerp(anchor - view.pivot_offset, blend)
		view.scale = view.scale.lerp(Vector2.ONE * target_scale, blend)
		view.rotation = lerpf(view.rotation, target_rotation, blend)
	_show_tip()


func _update_hover() -> void:
	var count := _views.size()
	_hover = -1
	if not enabled or count == 0:
		return
	var mouse := get_viewport().get_mouse_position()
	var half_width := (count - 1) * SPACING / 2.0 + 36.0
	# While a card is popped up, the area of the hand reaches up to its top, so it does not flicker.
	var reach := POP_Y - 100.0 * POP_SCALE if _hover_was_set else BASE_Y - 100.0 - 6.0
	if mouse.y < reach or mouse.y > 360.0 or absf(mouse.x - CENTER_X) > half_width:
		_hover_was_set = false
		return
	_hover = clampi(roundi((mouse.x - CENTER_X) / SPACING + (count - 1) / 2.0), 0, count - 1)
	_hover_was_set = true



func _show_tip() -> void:
	if _hover < 0:
		_tip.hide()
		return
	var card := _data[_hover]
	var lines: Array[String] = ["%s card - cost %d" % [str(card.get("type", "")).capitalize(), int(card.get("cost", 0))]]
	for key: String in EXPLAIN:
		if card.get("effects", {}).has(key):
			lines.append(EXPLAIN[key])
	if int(card.get("cost", 0)) > energy:
		lines.append("Not enough energy.")
	_tip_label.text = "\n".join(lines)
	var card_x := _views[_hover].position.x + 36.0
	var left := card_x + 36.0 * POP_SCALE + 4.0
	if left + TIP_SIZE.x > 636.0:
		left = card_x - 36.0 * POP_SCALE - 4.0 - TIP_SIZE.x
	_tip.position = Vector2(left, POP_Y - 100.0 * POP_SCALE)
	_tip.show()


func _input(event: InputEvent) -> void:
	if enabled and _hover >= 0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(_hover)
		get_viewport().set_input_as_handled()
