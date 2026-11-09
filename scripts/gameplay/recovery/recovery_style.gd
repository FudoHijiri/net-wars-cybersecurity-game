class_name RecoveryStyle
extends RefCounted

## Sweetie 16 colours used by in-world drawing (status markers, machine art).
## UI fonts, panels and buttons are styled in assets/recovery/ui/recovery_theme.tres.

const DARK := Color("1a1c2c")
const NAVY := Color("29366f")
const SLATE := Color("333c57")
const STEEL := Color("566c86")
const LIGHT := Color("94b0c2")
const WHITE := Color("f4f4f4")
const CYAN := Color("73eff7")
const GREEN := Color("a7f070")
const YELLOW := Color("ffcd75")
const ORANGE := Color("ef7d57")


## Wraps keyboard/gamepad focus through every visible, enabled button under parent.
static func focus_loop(parent: Node) -> void:
	var buttons: Array[Button] = []
	_collect_buttons(parent, buttons)
	for i in buttons.size():
		buttons[i].focus_next = buttons[(i + 1) % buttons.size()].get_path()
		buttons[i].focus_previous = buttons[(i - 1 + buttons.size()) % buttons.size()].get_path()
		buttons[i].focus_neighbor_bottom = buttons[i].focus_next
		buttons[i].focus_neighbor_top = buttons[i].focus_previous
		buttons[i].focus_neighbor_left = buttons[i].focus_previous
		buttons[i].focus_neighbor_right = buttons[i].focus_next
	if not buttons.is_empty():
		buttons[0].grab_focus()


static func _collect_buttons(parent: Node, buttons: Array[Button]) -> void:
	for child in parent.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled:
			buttons.append(child)
		_collect_buttons(child, buttons)
