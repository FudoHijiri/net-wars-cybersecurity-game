class_name PhaseTransition
extends Control

## Reusable "objective complete" card: a 5-step tracker, what carries over, what comes
## next, and a button that loads the next scene. Add it to the tree, then call setup().

signal continue_pressed

const STEPS: Array[String] = ["INVESTIGATE", "MONITOR", "HARDEN", "RESPOND", "RECOVER"]
const TITLE_MENU_SCENE := "res://scenes/menus/TitleMenu.tscn"
# Where the title menu keeps its overlays and the stage select (see TitleMenu.tscn).
const MENU_TITLE_PATH := "Control/Screen Content/TitleOverlay"
const MENU_SETTINGS_PATH := "Control/Screen Content/SettingsOverlay"
const MENU_STAGE_SELECT_PATH := "Control/Screen Content/StageSelect"
const NOT_BUILT_TEXT := "! This part is not built yet. Going back to the stage select..."
const NOT_BUILT_DELAY := 2.5

const COLOR_DARK := Color("1a1c2c")
const COLOR_NAVY := Color("29366f")
const COLOR_BLUE := Color("3b5dc9")
const COLOR_LIGHT := Color("94b0c2")
const COLOR_WHITE := Color("f4f4f4")

var _next_scene := ""

@onready var _backdrop: ColorRect = %Backdrop
@onready var _day_label: Label = %DayLabel
@onready var _headline_label: Label = %HeadlineLabel
@onready var _tracker_row: HBoxContainer = %TrackerRow
@onready var _carried_lines: VBoxContainer = %CarriedLines
@onready var _next_title: Label = %NextTitle
@onready var _next_description: Label = %NextDescription
@onready var _continue_button: Button = %ContinueButton
@onready var _notice_label: Label = %NoticeLabel


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)
	# Run on its own (F6) it fills the screen and shows sample data; as an overlay it
	# sits on top of whatever is below it.
	var standalone := get_tree().current_scene == self
	_backdrop.visible = standalone
	if standalone:
		setup(ReportLogic.build_transition_data(GameState.scenario.get("threat_name", "")))


## data: day_title, headline, phase_index (the NEXT phase, 0-based), carried (Array of
## strings), next_title, next_description, button_text, next_scene.
func setup(data: Dictionary) -> void:
	_day_label.text = str(data.get("day_title", ""))
	_headline_label.text = str(data.get("headline", "OBJECTIVE COMPLETE"))
	_build_tracker(int(data.get("phase_index", 0)))
	_fill_carried(data.get("carried", []))
	_next_title.text = "NEXT: %s" % str(data.get("next_title", "")).to_upper()
	_next_description.text = str(data.get("next_description", ""))
	_continue_button.text = str(data.get("button_text", "CONTINUE >"))
	_continue_button.disabled = false
	_next_scene = str(data.get("next_scene", ""))
	_notice_label.hide()


## True when `path` points to a scene that exists in the project.
static func scene_exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)


## Returns to the stage select screen. StageSelect.tscn is not a screen of its own (alone it
## is a blank gray window): it lives inside the title menu. So load the title menu and show
## its StageSelect with the TitleOverlay and SettingsOverlay hidden.
static func go_to_stage_select(tree: SceneTree) -> void:
	tree.change_scene_to_file(TITLE_MENU_SCENE)
	await tree.process_frame # the scene swap happens at the end of this frame
	await tree.process_frame # the menu's own _ready() has run by now, so we can override it
	var menu := tree.current_scene
	if menu == null:
		return
	for path in [MENU_TITLE_PATH, MENU_SETTINGS_PATH]:
		var overlay := menu.get_node_or_null(path) as Control
		if overlay != null:
			overlay.hide()
	var stage_select := menu.get_node_or_null(MENU_STAGE_SELECT_PATH) as Control
	if stage_select != null:
		stage_select.show()


func _build_tracker(next_index: int) -> void:
	clear_children(_tracker_row)
	for i in STEPS.size():
		var status := "LOCKED"
		if i < next_index:
			status = "DONE"
		elif i == next_index:
			status = "NEXT"
		_tracker_row.add_child(_make_step("%d. %s" % [i + 1, STEPS[i]], status))


func _make_step(step_name: String, status: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size = Vector2(0, 42)
	var style := StyleBoxFlat.new()
	style.bg_color = {"DONE": COLOR_BLUE, "NEXT": COLOR_WHITE, "LOCKED": COLOR_NAVY}[status]
	box.add_theme_stylebox_override("panel", style)
	var text_color := COLOR_DARK if status == "NEXT" else COLOR_WHITE
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(column)
	for text in [step_name, status]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", text_color)
		column.add_child(label)
	return box


func _fill_carried(lines: Array) -> void:
	clear_children(_carried_lines)
	for line in lines:
		_carried_lines.add_child(_make_line(str(line)))
	_carried_lines.add_child(_make_line("These go with you into the next objective."))


func _make_line(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## Removes and frees every child. remove_child first: queue_free alone is deferred.
static func clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_continue_pressed() -> void:
	continue_pressed.emit()
	if scene_exists(_next_scene):
		get_tree().change_scene_to_file(_next_scene)
		return
	_continue_button.disabled = true
	_notice_label.text = NOT_BUILT_TEXT
	_notice_label.show()
	await get_tree().create_timer(NOT_BUILT_DELAY).timeout
	go_to_stage_select(get_tree())
