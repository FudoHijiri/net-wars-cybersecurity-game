class_name CaseInvestigation
extends Control

## The Investigation phase: look through the evidence sources, press INVESTIGATE on an entry and
## hear what the player thinks about it. Four entries are real clues; finding all four unlocks the
## REPORT, a fill-in-the-blanks summary of the case. A correct report hands over to the next phase.
##
## Everything the player reads comes from the case file (`case_path`); another day is another
## file. Found clues are also written to GameState (set_marked), so the debug panel and the
## rest of the game see them.

const TRANSITION_SCENE := preload("res://AI generated/scenes/transition/PhaseTransition.tscn")

## Empty: the current day's case (GameState.current_day, see data/days.json). Fill it in to play
## one case file on its own.
@export_file("*.json") var case_path: String = ""

var _case: Dictionary = {}
var _states: Dictionary = {} # entry id -> CaseAppView.STATE_FOUND / STATE_SEEN
var _found_order: Array[String] = [] # ids of the clue entries, in the order the player found them
var _tab_group := ButtonGroup.new()
var _tab_buttons: Dictionary = {} # source id -> Button
var _report_announced := false # the last clue was just found: point the player at REPORT

@onready var _app_view: CaseAppView = %AppView
@onready var _monologue: MonologueBox = %MonologueBox
@onready var _report: CaseReport = %CaseReport
@onready var _tabs: HBoxContainer = %Tabs
@onready var _report_button: Button = %ReportButton
@onready var _objective: Label = %Objective
@onready var _clues_found: Label = %CluesFound
@onready var _title_exe: Label = %TitleExe
@onready var _pause_button: TextureButton = %PauseButton


func _ready() -> void:
	var path := case_path if not case_path.is_empty() else str(GameState.day_info().get("case", CaseData.CASE_PATH))
	_case = CaseData.load_case(path)
	if _case.is_empty():
		push_error("CaseInvestigation: no case data in %s" % path)
		return
	_title_exe.text = CaseData.ui(_case, "window_title")
	_report_button.text = CaseData.ui(_case, "report_button")
	_monologue.configure(str(_case.get("speaker", "")), CaseData.ui(_case, "monologue_hint"),
			CaseData.ui(_case, "monologue_continue"))
	_pause_button.tooltip_text = CaseData.ui(_case, "pause_button")

	_read_found_clues()
	_app_view.setup(_case, _states)
	_build_tabs()
	_app_view.investigate_requested.connect(_on_investigate_requested)
	_monologue.finished.connect(_on_monologue_finished)
	_report.completed.connect(_on_report_completed)
	_report_button.pressed.connect(_open_report)
	_pause_button.pressed.connect(func() -> void: PauseMenu.open()) # the title-bar button opens the pause menu
	GameState.clues_changed.connect(_on_game_state_clues_changed)

	var ids := CaseData.source_ids(_case)
	if not ids.is_empty():
		(_tab_buttons[ids[0]] as Button).set_pressed_no_signal(true)
		_app_view.show_source(ids[0])
	_refresh_objective()


## Clues the player already found (GameState keeps them if the scene is left and re-entered).
func _read_found_clues() -> void:
	_found_order.clear()
	_states.clear()
	for entry in CaseData.clue_entries(_case):
		var id := str(entry["id"])
		if GameState.is_marked(id):
			_found_order.append(id)
			_states[id] = CaseAppView.STATE_FOUND


func _build_tabs() -> void:
	for source_id in CaseData.source_ids(_case):
		var button := Button.new()
		button.text = str(CaseData.get_source(_case, source_id).get("label", source_id))
		button.toggle_mode = true
		button.button_group = _tab_group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_app_view.show_source.bind(source_id))
		_tabs.add_child(button)
		_tab_buttons[source_id] = button


func _on_investigate_requested(entry: Dictionary) -> void:
	var id := str(entry.get("id", ""))
	var lines: Array[String] = []
	if entry.get("is_clue", false):
		if _states.get(id, "") == CaseAppView.STATE_FOUND:
			lines.append(str(entry.get("monologue_again", CaseData.message(_case, "already_noted"))))
		else:
			var is_last_clue := _found_order.size() + 1 >= int(_case.get("clues_required", 0))
			_report_announced = is_last_clue # before set_marked: its signal refreshes the objective
			_states[id] = CaseAppView.STATE_FOUND
			_found_order.append(id)
			GameState.set_marked(id, true)
			lines.append(str(entry.get("monologue_correct", "")))
			if is_last_clue:
				lines.append(str(_case.get("all_clues_found_monologue", "")))
	else:
		_states[id] = CaseAppView.STATE_SEEN
		lines.append(str(entry.get("monologue_wrong", CaseData.message(_case, "wrong_default"))))
	_app_view.refresh()
	_clues_found.text = _clues_found_text()
	_monologue.play(lines)


func _on_monologue_finished() -> void:
	var announce := _report_announced
	_report_announced = false
	_refresh_objective()
	if announce and _report_button.visible:
		_report_button.grab_focus()


## The counter shows at once; the objective and the REPORT button wait until the monologue is
## over, so the final lines are read before the screen changes.
func _refresh_objective() -> void:
	_clues_found.text = _clues_found_text()
	var ready_to_report := _found_order.size() >= int(_case.get("clues_required", 0)) and not _monologue.is_playing() and not _report_announced
	_objective.text = CaseData.ui(_case, "objective_report" if ready_to_report else "objective_search")
	_report_button.visible = ready_to_report


func _clues_found_text() -> String:
	return CaseData.ui(_case, "clues_found").format({
		"found": _found_order.size(),
		"total": int(_case.get("clues_required", 0)),
	})


## GameState changed from outside (the debug panel, a new game): follow it.
func _on_game_state_clues_changed() -> void:
	for id in _found_order.duplicate():
		if not GameState.is_marked(id):
			_found_order.erase(id)
			_states.erase(id)
	for entry in CaseData.clue_entries(_case):
		var id := str(entry["id"])
		if GameState.is_marked(id) and not _found_order.has(id):
			_found_order.append(id)
			_states[id] = CaseAppView.STATE_FOUND
	_app_view.refresh()
	_refresh_objective()


func _open_report() -> void:
	var found: Array[Dictionary] = []
	for id in _found_order:
		found.append(CaseData.find_entry(_case, id)["entry"])
	_report.setup(_case, found)
	_report.open()


## The report is right: keep the evidence and the threat, then show the card that leads to the
## next phase.
func _on_report_completed() -> void:
	_report.close()
	GameState.investigation_evidence = _found_order.duplicate()
	GameState.identified_threat = str(_case.get("threat_name", ""))
	var backdrop := ColorRect.new() # hides the desktop behind the card and blocks clicks on it
	backdrop.color = Color(0.101960786, 0.10980392, 0.17254902, 0.92)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var card := TRANSITION_SCENE.instantiate() as PhaseTransition
	add_child(card) # in the tree first, then setup
	card.setup(CaseData.transition_data(_case, _found_order.size()))


# --- Debug panel hooks (F9). Developer shortcuts, never shown to players. ---

func debug_find_all_clues() -> void:
	for entry in CaseData.clue_entries(_case):
		GameState.set_marked(str(entry["id"]), true) # the clues_changed handler does the rest


func debug_clear_clues() -> void:
	for entry in CaseData.clue_entries(_case):
		GameState.set_marked(str(entry["id"]), false)


func debug_open_report() -> void:
	debug_find_all_clues()
	_open_report()


## Same outcome as a correct report.
func debug_complete() -> void:
	debug_find_all_clues()
	var found: Array[Dictionary] = []
	for id in _found_order:
		found.append(CaseData.find_entry(_case, id)["entry"])
	_report.setup(_case, found)
	_report.debug_solve()
	_on_report_completed()


func debug_info() -> String:
	return "CLUES: %d/%d   THREAT: %s" % [_found_order.size(), int(_case.get("clues_required", 0)),
			GameState.identified_threat if not GameState.identified_threat.is_empty() else "-"]
