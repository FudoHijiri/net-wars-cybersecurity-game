extends CanvasLayer

@export var b_group: ButtonGroup
var dia_choices: Dictionary

signal next_id(id: String)

func _ready() -> void:
	b_group.pressed.connect(get_choice)


func set_choices(choices: Dictionary):
	dia_choices = choices
	var buttons = b_group.get_buttons()
	var labels = choices.keys()
	for c in buttons.size():
		var button = buttons[c]
		button.visible = c < labels.size() # only show as many buttons as there are choices
		button.set_pressed_no_signal(false) # forget the last selection so it can be pressed again
		if c < labels.size(): 
			button.text = labels[c]


func get_choice(b: Button):
	var id = dia_choices[b.text]
	next_id.emit(id)
	pass
