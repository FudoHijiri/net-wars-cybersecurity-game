class_name HandFan
extends Control
## The player's hand, fanned out along the bottom of the screen. The card under the mouse pops
## up, grows to twice its size and shows a panel next to it: what kind of card it is, its text with the
## special words in color (see Keywords) and, when the mouse moves onto one of those words, what it means.
## The mouse can move from the card onto the panel without it closing. Click the card to play it.

signal card_clicked(index: int)

const CARD_SCENE := preload("res://scenes/gameplay/hardening/Card.tscn")
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const CENTER_X := 320.0
const BASE_Y := 366.0 # bottom centre of a resting card (its bottom edge is just off screen)
const SPACING := 42.0 # distance between two cards in the fan
const SINK := 5.0 # how far a card sinks for each step (squared) from the middle: the curve of the fan
const MAX_SINK := 28.0 # a big hand stops curving here, so the outer cards still show their names
const TILT := 0.04 # radians of rotation per step from the middle, 0 for no rotation. Small on purpose: rotated 6px text is less crisp, and the card under the mouse is straightened
const POP_SCALE := 2.0
const POP_Y := 358.0 # bottom centre of the card under the mouse
const PILE := Vector2(40.0, 336.0) # the draw pile (bottom left): cards fly out of it, and the discard goes back there
const HIDDEN_Y := 480.0 # where the cards wait during the enemy turn
const SMOOTH := 16.0
const TIP_SIZE := Vector2(112, 66)
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)

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
var _tip_label := RichTextLabel.new()
var _tip_key := "" # what the panel shows now (card and energy), so its text is only set again when that changes
var _tip_zone := Rect2() # the panel and the gap to its card: the mouse may rest here without the card closing
var _bridge := Rect2() # the top half of the popped card on the panel's side: the card stays here, so the mouse can slide to the panel
var _word_tip := Panel.new() # what the word under the mouse means
var _word_label := Label.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101960786, 0.10980392, 0.17254902, 1)
	style.set_border_width_all(1)
	style.border_color = GameColors.highlight
	_tip.add_theme_stylebox_override("panel", style)
	_tip.size = TIP_SIZE
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE # the words inside take the mouse, the panel itself does not
	_tip.z_index = 100
	_tip.hide()
	add_child(_tip)
	_tip_label.bbcode_enabled = true
	_tip_label.scroll_active = false
	_tip_label.add_theme_font_override("normal_font", FONT)
	_tip_label.add_theme_font_size_override("normal_font_size", 6)
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_label.position = Vector2(5, 4)
	_tip_label.size = TIP_SIZE - Vector2(10, 8)
	_tip_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_tip_label.meta_hover_started.connect(_on_word_hover)
	_tip_label.meta_hover_ended.connect(func(_meta: Variant) -> void: _word_tip.hide())
	_tip.add_child(_tip_label)
	var word_style := style.duplicate() as StyleBoxFlat
	word_style.border_color = Color.WHITE
	_word_tip.add_theme_stylebox_override("panel", word_style)
	_word_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_word_tip.z_index = 101
	_word_tip.hide()
	add_child(_word_tip)
	_word_label.add_theme_font_override("font", FONT)
	_word_label.add_theme_font_size_override("font_size", 6)
	_word_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_word_label.position = Vector2(5, 4)
	_word_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_word_tip.add_child(_word_label)


## Replaces the hand. ids are card ids, cards is the card table of data/cards.json.
func set_hand(ids: Array, cards: Dictionary) -> void:
	for view in _views:
		view.queue_free()
	_views.clear()
	_data.clear()
	for i in ids.size():
		add_card(ids[i], cards[ids[i]], i * 0.07) # one after another
	_hover = -1


## The whole hand flies to `to` (the discard pile), one card after another, shrinking and fading. The cards
## leave the hand at once, so the next set_hand() starts clean.
func discard_all(to: Vector2) -> void:
	var views := _views.duplicate()
	_views.clear()
	_data.clear()
	_hover = -1
	for i in views.size():
		var view: CardView = views[i]
		if UiFx.reduced():
			view.queue_free()
			continue
		view.z_index = 60
		var tween := view.create_tween()
		tween.tween_interval(i * 0.04)
		tween.tween_property(view, "position", to - view.pivot_offset, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.parallel().tween_property(view, "scale", Vector2.ONE * 0.3, 0.28)
		tween.parallel().tween_property(view, "modulate:a", 0.0, 0.28)
		tween.tween_callback(view.queue_free)


func card_count() -> int:
	return _views.size()


## Where the middle of a card is on the screen (an effect starts there when the card is played).
func card_center(index: int) -> Vector2:
	var view := _views[index]
	return view.position + view.pivot_offset + Vector2(0.0, -50.0 * view.scale.y)


## Takes one card out of the hand (it was played).
func remove_card(index: int) -> void:
	_views[index].queue_free()
	_views.remove_at(index)
	_data.remove_at(index)
	_hover = -1


## Adds one card to the end of the hand (a card that draws).
func add_card(id: String, card: Dictionary, delay: float = 0.0) -> void:
	var view: CardView = CARD_SCENE.instantiate()
	add_child(view)
	view.setup(id, card)
	view.pivot_offset = Vector2(36, 100)
	view.position = PILE - view.pivot_offset # the cards fly out of the draw pile, growing as they go
	view.scale = Vector2.ONE * 0.4
	if delay > 0.0 and not UiFx.reduced():
		view.hide()
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			if is_instance_valid(view):
				view.show())
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
		var anchor := Vector2(CENTER_X + step * SPACING, BASE_Y + minf(step * step * SINK, MAX_SINK))
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


func _update_hover(mouse: Vector2 = get_viewport().get_mouse_position()) -> void:
	var count := _views.size()
	var before := _hover
	_hover = -1
	if not enabled or count == 0:
		return
	# The popped card is wider than a slot of the fan, so on its way to the panel the mouse crosses the slots of
	# the next cards. Along the top of the card (where the panel is) and on the panel the card stays.
	if before >= 0 and before < count and _tip.visible and (_tip_zone.has_point(mouse) or _bridge.has_point(mouse)):
		_hover = before
		return
	var half_width := (count - 1) * SPACING / 2.0 + 36.0
	# While a card is popped up, the area of the hand reaches up to its top, so it does not flicker.
	var reach := POP_Y - 100.0 * POP_SCALE if _hover_was_set else BASE_Y - 100.0 - 6.0
	if mouse.y < reach or mouse.y > 360.0 or absf(mouse.x - CENTER_X) > half_width:
		_hover_was_set = false
		return
	_hover = clampi(roundi((mouse.x - CENTER_X) / SPACING + (count - 1) / 2.0), 0, count - 1)
	if _hover != before:
		Sfx.play(&"hover", 4.0)
	_hover_was_set = true



func _show_tip() -> void:
	if _hover < 0:
		_tip.hide()
		_word_tip.hide()
		_tip_zone = Rect2()
		_bridge = Rect2()
		return
	var card := _data[_hover]
	var key := "%d|%s|%d" % [_hover, str(card.get("name", "")), energy]
	if key != _tip_key or not _tip.visible: # only then: a new text would drop the word the mouse is on
		_tip_key = key
		var text := "[color=#%s]%s card - cost %d[/color]\n%s" % [GameColors.highlight.to_html(false), str(card.get("type", "")).capitalize(), int(card.get("cost", 0)), Keywords.highlight(str(card.get("text", "")))]
		if not Keywords.ids_in(str(card.get("text", ""))).is_empty():
			text += "\n[color=#94b0c2]Point at a colored word to read what it means.[/color]"
		if int(card.get("cost", 0)) > energy:
			text += "\n[color=#ef7d57]Not enough energy.[/color]"
		_tip_label.text = text
		_tip_label.size = Vector2(TIP_SIZE.x - 10.0, 0.0)
		_tip.size = Vector2(TIP_SIZE.x, _tip_label.get_content_height() + 8.0) # the panel grows with the text
		_tip_label.size = Vector2(TIP_SIZE.x - 10.0, _tip.size.y - 8.0)
	var card_x := _views[_hover].position.x + 36.0
	var left := card_x + 36.0 * POP_SCALE + 4.0
	var on_right := left + TIP_SIZE.x <= 636.0
	if not on_right:
		left = card_x - 36.0 * POP_SCALE - 4.0 - TIP_SIZE.x
	_tip.position = Vector2(left, POP_Y - 100.0 * POP_SCALE)
	# the zone includes the 4 pixels between the card and the panel, so the mouse can cross them
	var zone_left := left - (4.0 if on_right else 0.0)
	_tip_zone = Rect2(zone_left, _tip.position.y, TIP_SIZE.x + 4.0, _tip.size.y)
	var half := 36.0 * POP_SCALE
	var bridge_x := card_x if on_right else card_x - half - 4.0
	_bridge = Rect2(bridge_x, _tip.position.y, half + 4.0, maxf(_tip.size.y, 110.0))
	_tip.show()


## The mouse is on a colored word of the panel: what it means appears under the panel.
func _on_word_hover(meta: Variant) -> void:
	var entry := Keywords.explain(str(meta))
	if entry.is_empty():
		return
	_word_label.text = "%s: %s" % [entry.get("name", ""), entry.get("text", "")]
	_word_label.add_theme_color_override("font_color", Keywords.color_of(str(meta)))
	_word_label.size = Vector2(TIP_SIZE.x - 10.0, 0.0)
	var height := _word_label.get_minimum_size().y + 8.0
	_word_label.size = Vector2(TIP_SIZE.x - 10.0, height - 8.0)
	_word_tip.size = Vector2(TIP_SIZE.x, height)
	_word_tip.position = Vector2(_tip.position.x, _tip.position.y + _tip.size.y + 2.0)
	_word_tip.show()


func _input(event: InputEvent) -> void:
	if enabled and _hover >= 0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _tip.visible and _tip_zone.has_point(get_viewport().get_mouse_position()):
			get_viewport().set_input_as_handled() # a click on the panel does not play the card
			return
		var index := _hover # a copy: the first handler takes the card out, which resets _hover, before the next one reads it
		card_clicked.emit(index)
		get_viewport().set_input_as_handled()
