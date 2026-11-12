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
## The color role of each state (GameColors): the fill is the player's Good / Bad color, with the text color that reads on it.
const ROLES := {
	State.OK: &"good",
	State.BAD: &"bad",
}

var _box: StyleBoxFlat


func _ready() -> void:
	# The scene's style is shared by every copy of the tag, so each tag gets its own.
	_box = get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	add_theme_stylebox_override("normal", _box)
	set_state(State.OK)


func set_state(state: State) -> void:
	text = TEXTS[state]
	var fill := GameColors.fill(ROLES[state])
	_box.bg_color = fill
	_box.border_color = fill
	add_theme_color_override("font_color", GameColors.text_on(fill))
