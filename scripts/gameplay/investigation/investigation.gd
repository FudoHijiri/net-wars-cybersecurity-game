extends Control

## Tab bar of the Investigation screen. One app view is reused for every tab.
## The shown app is also named in the panel's title, so the active tab is never
## signalled by the button's pressed color alone.
##
## The buttons' `pressed` signals are connected in Investigation.tscn.

const DEFAULT_APP := "email"

var _shown_clues := -1 # the clue count last shown, so only a new clue makes the counter jump

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

	# The scenario may relabel the tabs ("tabs": app id -> label): the same seven slots hold different apps each day.
	var labels: Dictionary = GameState.scenario.get("tabs", {})
	var slots := {"email": _email_button, "logs": _logs_button, "computers": _computers_button, "login": _login_button,
			"files": _files_button, "network": _net_button, "servers": _servers_button}
	for app_id: String in slots:
		if labels.has(app_id):
			(slots[app_id] as Button).text = str(labels[app_id])

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
	# Until then there is no REPORT button at all: a button that cannot be pressed is only noise.
	_report_button.disabled = GameState.marked_count() < GameState.clues_required()
	_report_button.visible = not _report_button.disabled
	if not _report_button.disabled:
		UiFx.attention(_report_button)
	_app_view.all_clues_found.connect(_show_report_button) # it bounces until it is pressed

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
	UiFx.stop_attention(_report_button)
	_animation.play(&"ReportScreenOpening")
	_animation.advance(0.0) # apply the first frame before the screen shows
	_report.open()
	await _animation.animation_finished # the tutorial pauses the game, so it waits for the screen to be there
	Tutorial.maybe_show(_report, "investigation_report")
	Tutorial.maybe_show_new(_report, str(GameState.scenario.get("report", {}).get("tutorial", "")))


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
	var count := GameState.marked_count()
	if _shown_clues >= 0 and count > _shown_clues: # a new clue: the counter jumps
		UiFx.pop(_clues_found, 0.2, 0.3)
		UiFx.flash(_clues_found, UiFx.GOLD, 0.5)
	_shown_clues = count
	_clues_found.text = "Found Clues: %d/%d" % [GameState.marked_count(), GameState.clues_required()]
	# With every clue found, the next step is the REPORT button.
	var done := GameState.marked_count() >= GameState.clues_required()
	_objective.text = GameState.objective("objective_report" if done else "objective", "investigation")


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
	_show_report_button()


## The REPORT button appears (the way it does after the monologue of the last clue).
func _show_report_button() -> void:
	if _report_button.visible and not _report_button.disabled:
		return
	_report_button.disabled = false
	_report_button.show()
	UiFx.attention(_report_button)


func debug_clear_clues() -> void:
	GameState.marked_clues.clear()
	GameState.investigated.clear()
	GameState.clues_changed.emit()
	UiFx.stop_attention(_report_button)
	_report_button.disabled = true
	_report_button.hide() # no REPORT button until every clue is found again


func debug_open_report() -> void:
	debug_find_all_clues()
	_on_report_button_pressed()


## Same outcome as a solved report with CONTINUE pressed: the FinishScreen.
func debug_complete() -> void:
	debug_find_all_clues()
	_on_report_completed()
