class_name HintTag
extends Label
## The small tag Joshua puts next to a hint: NORMAL or SUSPICIOUS. It answers what the player has to
## decide (report or let pass), so there is no in-between. A hint about something that looks unusual
## but is allowed is tagged NORMAL, and its text says why.
## The word always says it too, so the color is never the only signal.

enum State { OK, BAD }

const TEXTS := {
	State.OK: "NORMAL",
	State.BAD: "SUSPICIOUS",
}
const FILLS := {
	State.OK: Color("38b764"),
	State.BAD: Color("b13e53"),
}
## The dark navy and the white of the palette, whichever reads better on the fill.
const DARK_TEXT := Color("1a1c2c")
const LIGHT_TEXT := Color("f4f4f4")

var _box: StyleBoxFlat


func _ready() -> void:
	# The scene's style is shared by every copy of the tag, so each tag gets its own.
	_box = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("normal", _box)
	set_state(State.OK)


func set_state(state: State) -> void:
	text = TEXTS[state]
	_box.bg_color = FILLS[state]
	_box.border_color = FILLS[state]
	add_theme_color_override("font_color", LIGHT_TEXT if state == State.BAD else DARK_TEXT)
