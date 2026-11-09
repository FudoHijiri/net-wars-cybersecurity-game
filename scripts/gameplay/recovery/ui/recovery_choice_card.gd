class_name RecoveryChoiceCard
extends Button

## One option the player can pick: a big heading and a short detail line.
## Layout: tasks/parts/ChoiceCard.tscn. States: "pending", "picked" (green) and "wrong" (crossed out).

const GOOD := Color(0.654902, 0.9411765, 0.4392157)
const FADED := Color(0.5803922, 0.6901961, 0.7607843)

var choice_id := ""
var _detail := ""

@onready var heading_label: Label = %Heading
@onready var detail_label: Label = %Detail


func show_choice(id: String, heading: String, detail: String) -> void:
	choice_id = id
	_detail = detail
	heading_label.text = heading
	detail_label.text = detail


func set_state(state: String, note := "") -> void:
	disabled = state != "pending"
	theme_type_variation = &"RecoveryCardGood" if state == "picked" else &"RecoveryCard"
	# The heading keeps its big font; only its colour follows the state.
	heading_label.remove_theme_color_override("font_color")
	match state:
		"picked":
			heading_label.add_theme_color_override("font_color", GOOD)
			detail_label.theme_type_variation = &"RecoverySuccess"
			detail_label.text = "[OK] " + (note if not note.is_empty() else _detail)
		"wrong":
			heading_label.add_theme_color_override("font_color", FADED)
			detail_label.theme_type_variation = &"RecoveryDanger"
			detail_label.text = "[X] " + (note if not note.is_empty() else _detail)
		_:
			detail_label.theme_type_variation = &"RecoveryMuted"
			detail_label.text = _detail


func bounce() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	for angle: float in [0.04, -0.04, 0.02, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.05)
