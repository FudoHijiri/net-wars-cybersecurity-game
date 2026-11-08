extends Control

## Tab bar of the Investigation screen. One app view is reused for every tab.
## The shown app is also named in the panel's title, so the active tab is never
## signalled by the button's pressed color alone.
##
## The buttons' `pressed` signals are connected in Investigation.tscn.

const DEFAULT_APP := "email"
const OBJECTIVE_FIND_TEXT := "OBJECTIVE - INVESTIGATE AND FIND CLUES"
const OBJECTIVE_REPORT_TEXT := "OBJECTIVE - WRITE THE REPORT"

@onready var _objective: RichTextLabel = $FramePanel/MainPanel/Objective
@onready var _clues_found: RichTextLabel = $FramePanel/MainPanel/CluesFound
@onready var _app_view: AppViewPanel = $FramePanel/MainPanel/MainPanelAppView
@onready var _report_button: Button = $FramePanel/MainPanel/ReportButton
@onready var _report: ReportScreen = $ReportScreen
@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _monologue: Monologue = $Monologue
@onready var _finish: FinishScreen = $FinishScreen
@onready var _email_button: Button = $FramePanel/MainPanel/HBoxContainer/EmailButton
@onready var _logs_button: Button = $FramePanel/MainPanel/HBoxContainer/LogsButton
@onready var _computers_button: Button = $FramePanel/MainPanel/HBoxContainer/ComputersButton
@onready var _login_button: Button = $FramePanel/MainPanel/HBoxContainer/LoginButton
@onready var _files_button: Button = $FramePanel/MainPanel/HBoxContainer/FilesButton
@onready var _net_button: Button = $FramePanel/MainPanel/HBoxContainer/NetButton
@onready var _servers_button: Button = $FramePanel/MainPanel/HBoxContainer/ServersButton


func _ready() -> void:
	_app_view.monologue = _monologue

	# One group, so exactly one tab shows as pressed.
	var group := ButtonGroup.new()
	for button: Button in [_email_button, _logs_button, _computers_button, _login_button,
			_files_button, _net_button, _servers_button]:
		button.toggle_mode = true
		button.button_group = group

	# Setting button_pressed doesn't emit `pressed`, so open the default app by hand.
	_email_button.button_pressed = true
	_app_view.load_app(DEFAULT_APP)

	GameState.clues_changed.connect(_update_clues_found)
	_update_clues_found()

	# REPORT unlocks after the monologue that follows the last clue.
	_report_button.disabled = GameState.marked_count() < GameState.clues_required()
	_app_view.all_clues_found.connect(func() -> void: _report_button.disabled = false)

	_report.completed.connect(_on_report_completed)

	await SceneManager.wait_for_transition()
	Tutorial.maybe_show(self, "investigation")


func _on_email_button_pressed() -> void:
	_app_view.load_app("email")


func _on_logs_button_pressed() -> void:
	_app_view.load_app("logs")


func _on_computers_button_pressed() -> void:
	_app_view.load_app("computers")


func _on_login_button_pressed() -> void:
	_app_view.load_app("login")


func _on_files_button_pressed() -> void:
	_app_view.load_app("files")


func _on_net_button_pressed() -> void:
	_app_view.load_app("network")


func _on_servers_button_pressed() -> void:
	_app_view.load_app("servers")


func _on_report_button_pressed() -> void:
	_animation.play(&"ReportScreenOpening")
	_animation.advance(0.0) # apply the first frame before the screen shows
	_report.open()
	await _animation.animation_finished # the tutorial pauses the game, so it waits for the screen to be there
	Tutorial.maybe_show(_report, "investigation_report")


## The report is right and CONTINUE was pressed: the phase is over. The FinishScreen pays out and goes on.
## Clues and mistakes are paid per the scenario's "finish" section; a report right on the first try
## earns Joshua's bonus.
func _on_report_completed() -> void:
	var finish: Dictionary = GameState.scenario["finish"]
	var clues := GameState.marked_count()
	var mistakes := _report.mistakes()
	var flawless := mistakes == 0
	_report.hide()
	_finish.show_results({
		"rows": [
			{"count": clues, "points": clues * int(finish["points_per_clue"])},
			{"name": "Report Mistakes:", "count": mistakes, "points": -mistakes * int(finish["points_per_mistake"])},
		],
		"comment": finish["comments"]["flawless" if flawless else "done"],
		"bonus": int(finish["bonus"]) if flawless else 0,
	})


func _update_clues_found() -> void:
	_clues_found.text = "Found Clues: %d/%d" % [GameState.marked_count(), GameState.clues_required()]
	# With every clue found, the next step is the REPORT button.
	var done := GameState.marked_count() >= GameState.clues_required()
	_objective.text = OBJECTIVE_REPORT_TEXT if done else OBJECTIVE_FIND_TEXT


func _on_pause_button_pressed() -> void:
	PauseMenu.open()


# --- Debug panel (=) ---

func debug_info() -> String:
	return "CLUES %d/%d   REPORT MISTAKES %d" % [GameState.marked_count(), GameState.clues_required(), _report.mistakes()]


func debug_actions() -> Array:
	return [
		["COMPLETE PHASE >", debug_complete],
		["Find all clues", debug_find_all_clues],
		["Clear all clues", debug_clear_clues],
		["Open the report", debug_open_report],
	]


func debug_find_all_clues() -> void:
	for app: Dictionary in GameState.scenario.get("investigation", {}).values():
		for entry: Dictionary in app.get("entries", []):
			if entry.get("is_clue", false):
				GameState.set_investigated(str(entry["id"]))
				GameState.set_marked(str(entry["id"]), true)
	_report_button.disabled = false


func debug_clear_clues() -> void:
	GameState.marked_clues.clear()
	GameState.investigated.clear()
	GameState.clues_changed.emit()
	_report_button.disabled = true


func debug_open_report() -> void:
	debug_find_all_clues()
	_on_report_button_pressed()


## Same outcome as a solved report with CONTINUE pressed: the FinishScreen.
func debug_complete() -> void:
	debug_find_all_clues()
	_on_report_completed()
