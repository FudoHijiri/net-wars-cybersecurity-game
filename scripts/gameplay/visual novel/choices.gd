extends CanvasLayer

@export var b_group: ButtonGroup
var dia_choices: Dictionary

signal next_id(id: String)

func _ready() -> void:
	b_group.pressed.connect(get_choice)


var _picked := false


## The choices appear one after another, and the dim behind them fades in.
func animate_in() -> void:
	var shown: Array = []
	for button in b_group.get_buttons():
		if button.visible:
			shown.append(button)
	UiFx.stagger_fade(shown, 0.08, 0.16)
	var dim := get_node_or_null("Dim") as CanvasItem
	if dim != null:
		UiFx.fade_in(dim, 0.2)


func set_choices(choices: Dictionary):
	_picked = false
	dia_choices = choices
	var buttons = b_group.get_buttons()
	var labels = choices.keys()
	for c in buttons.size():
		var button = buttons[c]
		button.visible = c < labels.size() # only show as many buttons as there are choices
		button.set_pressed_no_signal(false) # forget the last selection so it can be pressed again
		if c < labels.size(): 
			button.text = labels[c]
	_center.call_deferred()


## The buttons are as wide as the longest choice and the box is in the middle of the screen, whatever the text is
## (the box of the scene starts at a fixed place, so a long choice used to push it to the right).
func _center() -> void:
	var box := get_node_or_null("VBoxContainer") as Control
	if box == null:
		return
	box.reset_size()
	var screen := get_viewport().get_visible_rect().size
	box.position = ((screen - box.size) / 2.0).floor()


## The chosen button flashes and the others fade, then the dialogue goes on.
func get_choice(b: Button):
	if _picked:
		return
	_picked = true
	var id = dia_choices[b.text]
	UiFx.flash(b, UiFx.GOLD, 0.3)
	for other in b_group.get_buttons():
		if other != b and other.visible and not UiFx.reduced():
			other.create_tween().tween_property(other, "modulate:a", 0.0, 0.15)
	if not UiFx.reduced():
		await b.get_tree().create_timer(0.2).timeout
	next_id.emit(id)
