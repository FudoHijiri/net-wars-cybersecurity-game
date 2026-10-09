class_name MonitoringResults
extends Control

## End-of-phase card: every report with a text tag, the points earned, and what the
## player can learn from their mistakes. Hidden until show_results() is called.

signal continue_pressed

const NEXT_SCENE := "res://scenes/gameplay/hardening/Hardening.tscn"
## Loaded at runtime only: Monitoring.tscn contains this scene, so a preload would be a cycle.
const BACKDROP_SCENE := "res://AI generated/scenes/monitoring/Monitoring.tscn"
const NOT_BUILT_TEXT := "! The hardening part is not built yet. Going back to the stage select..."
const NOT_BUILT_DELAY := 2.5

const COLOR_DARK := Color("1a1c2c")
const COLOR_NAVY := Color("29366f")
const COLOR_LIGHT := Color("94b0c2")
const COLOR_WHITE := Color("f4f4f4")

## The text tag of a line decides its look; the word itself carries the meaning.
const TAG_STYLES := {
	"IMPORTANT": [COLOR_WHITE, COLOR_DARK],
	"CORRECT": [COLOR_WHITE, COLOR_DARK],
	"FALSE ALARM": [COLOR_LIGHT, COLOR_DARK],
	"MISSED": [COLOR_DARK, COLOR_WHITE],
}

@onready var _reports_list: VBoxContainer = %ReportsList
@onready var _points_value: Label = %PointsValue
@onready var _learn_text: Label = %LearnText
@onready var _continue_button: Button = %ContinueButton
@onready var _notice_label: Label = %NoticeLabel


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	if get_tree().current_scene == self: # run on its own (F6): show a sample run
		_add_standalone_backdrop()
		show_results(_sample_results())


## results: lines (Array of {label, tag, points, reported}), points (int), learned (String).
func show_results(results: Dictionary) -> void:
	PhaseTransition.clear_children(_reports_list)
	for line: Dictionary in results.get("lines", []):
		_reports_list.add_child(_make_line(line))
	_points_value.text = "%03d" % int(results.get("points", 0))
	_learn_text.text = str(results.get("learned", ""))
	_continue_button.disabled = false
	_notice_label.hide()
	show()


func _make_line(line: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var marker := "[x]" if line.get("reported", false) else "[ ]"
	var name_label := Label.new()
	name_label.text = "%s %s" % [marker, line.get("label", "")]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	row.add_child(name_label)
	row.add_child(_make_tag(str(line.get("tag", ""))))
	var points_label := Label.new()
	points_label.text = "%+d" % int(line.get("points", 0)) if line.get("points", 0) != 0 else "0"
	points_label.custom_minimum_size.x = 22
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(points_label)
	return row


func _make_tag(tag: String) -> Label:
	var colors: Array = TAG_STYLES.get(tag, [COLOR_NAVY, COLOR_WHITE])
	var label := Label.new()
	label.text = tag
	label.custom_minimum_size.x = 58
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", colors[1])
	var style := StyleBoxFlat.new()
	style.bg_color = colors[0]
	style.set_border_width_all(1)
	style.border_color = COLOR_LIGHT
	style.set_content_margin_all(1)
	label.add_theme_stylebox_override("normal", style)
	return label


func _on_continue_pressed() -> void:
	continue_pressed.emit()
	if PhaseTransition.scene_exists(NEXT_SCENE):
		get_tree().change_scene_to_file(NEXT_SCENE)
		return
	_continue_button.disabled = true
	_notice_label.text = NOT_BUILT_TEXT
	_notice_label.show()
	await get_tree().create_timer(NOT_BUILT_DELAY).timeout
	PhaseTransition.go_to_stage_select(get_tree())


## Sample run for F6: one report of each kind, the rest of the anomalies missed.
func _sample_results() -> Dictionary:
	var data := MonitoringData.load_data()
	var points: Dictionary = data.get("points", {})
	var events: Array = data.get("events", []).duplicate(true)
	var score := 0
	var shown := {"important": false, "correct": false, "false_alarm": false}
	for event: Dictionary in events:
		var result := MonitoringData.result_for(event)
		if shown[result]:
			continue
		shown[result] = true
		event["reported"] = true
		event["result"] = result
		event["points"] = MonitoringData.points_for(event, points)
		score = maxi(0, score + int(event["points"]))
	return MonitoringData.build_results(events, data, score)


## Run on its own, the card would sit on the empty gray window. Put a frozen copy of the
## Monitoring screen behind it so it overlays the menu the way it does in the game.
func _add_standalone_backdrop() -> void:
	var backdrop := (load(BACKDROP_SCENE) as PackedScene).instantiate()
	backdrop.process_mode = Node.PROCESS_MODE_DISABLED # just a picture: no clock, no input
	add_child(backdrop)
	move_child(backdrop, 0) # behind the card
