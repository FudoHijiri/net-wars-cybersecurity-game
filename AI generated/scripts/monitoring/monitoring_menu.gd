class_name MonitoringMenu
extends Control

## The Monitoring objective. A company clock runs from start_clock to end_clock; each
## event in the data file appears when the clock reaches its time. The player reports
## the suspicious ones for Security Points; reporting normal activity costs points.

const VIEW_IDS: Array[String] = ["computer", "login", "network", "server"]
const DEFAULT_VIEW := "login"
const JITTER_SECONDS := 3.0 # normal events arrive a little early or late
const TOAST_SECONDS := 4.0
const DONE_TEXT := "OBJECTIVE COMPLETE - MONITORING"

const COLOR_DARK := Color("1a1c2c")
const COLOR_WHITE := Color("f4f4f4")

## Real seconds per company minute: 6 turns the 30 company minutes into 180 seconds.
@export var seconds_per_company_minute := 6.0

var _data: Dictionary = {}
var _events: Array[Dictionary] = [] # sorted by spawn_at
var _spawned := 0 # how many of _events have appeared
var _elapsed := 0.0
var _duration := 0.0
var _start_minutes := 0
var _running := false
var _score := 0
var _view_id := ""
var _shown_second := -1
var _toast_token := 0
var _rng := RandomNumberGenerator.new()
var _tabs: Dictionary = {} # view id -> tab Button

@onready var _view_panel: MonitorViewPanel = %MonitorViewPanel
@onready var _results: MonitoringResults = %MonitoringResults
@onready var _objective: RichTextLabel = %Objective
@onready var _points_value: Label = %PointsValue
@onready var _time_label: Label = %TimeLabel
@onready var _time_bar: ProgressBar = %TimeBar
@onready var _toast: PanelContainer = %Toast
@onready var _toast_title: Label = %ToastTitle
@onready var _toast_text: Label = %ToastText


func _ready() -> void:
	_data = MonitoringData.load_data()
	if _data.is_empty():
		return
	_tabs = {
		"computer": %ComputerButton, "login": %LoginButton,
		"network": %NetworkButton, "server": %ServerButton,
	}
	var group := ButtonGroup.new()
	for view_id in VIEW_IDS:
		var button: Button = _tabs[view_id]
		button.toggle_mode = true
		button.button_group = group
		button.pressed.connect(_show_view.bind(view_id))
	get_node("FramePanel/MainPanel/ExitButton").pressed.connect(PauseMenu.open) # title-bar X
	_view_panel.configure(_data.get("views", {}))
	_view_panel.report_requested.connect(_on_report_requested)
	_start_run()


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed = minf(_elapsed + delta, _duration)
	while _spawned < _events.size() and _events[_spawned]["spawn_at"] <= _elapsed:
		_view_panel.add_event(_events[_spawned])
		_spawned += 1
		_update_tabs()
	_update_clock()
	if _elapsed >= _duration:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	# Debug builds only: F8 skips straight to the results.
	if _running and OS.is_debug_build() and event is InputEventKey \
			and event.pressed and not event.echo and event.keycode == KEY_F8:
		_finish()


## Debug helper (used by the debug panel): lets every remaining event appear and, when
## asked, reports every anomaly (a perfect run), then ends the phase.
func debug_complete(report_anomalies: bool) -> void:
	if not _running:
		return
	while _spawned < _events.size():
		_view_panel.add_event(_events[_spawned])
		_spawned += 1
	if report_anomalies:
		for event in _events:
			if event["kind"] == "anomaly" and not event["reported"]:
				_on_report_requested(event)
	_update_tabs()
	_finish()


func _start_run() -> void:
	_start_minutes = MonitoringData.clock_to_minutes(str(_data.get("start_clock", "00:00")))
	var end_minutes := MonitoringData.clock_to_minutes(str(_data.get("end_clock", "00:00")))
	_duration = (end_minutes - _start_minutes) * seconds_per_company_minute
	_rng.randomize() # once per run
	_events = _make_run_events()
	_spawned = 0
	_elapsed = 0.0
	_score = 0
	_update_score()
	_running = true
	_tabs[DEFAULT_VIEW].button_pressed = true
	_show_view(DEFAULT_VIEW)
	_update_clock()


## Copies of the data events with their spawn time (seconds into the run) and run flags.
func _make_run_events() -> Array[Dictionary]:
	var run_events: Array[Dictionary] = []
	for source: Dictionary in _data.get("events", []):
		var event := source.duplicate(true)
		var minutes := MonitoringData.clock_to_minutes(str(event["time"])) - _start_minutes
		var spawn_at := minutes * seconds_per_company_minute
		if event.get("kind", "") != "anomaly": # anomalies arrive exactly on time
			spawn_at += _rng.randf_range(-JITTER_SECONDS, JITTER_SECONDS)
		event["spawn_at"] = clampf(spawn_at, 0.0, _duration - 1.0)
		event["seen"] = false
		event["reported"] = false
		event["result"] = ""
		event["points"] = 0
		run_events.append(event)
	run_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["spawn_at"] < b["spawn_at"])
	return run_events


func _show_view(view_id: String) -> void:
	if view_id == _view_id:
		return
	_mark_seen(_view_id) # leaving a view clears its NEW markers
	_view_id = view_id
	_view_panel.show_view(view_id)
	_update_tabs()


func _mark_seen(view_id: String) -> void:
	for i in _spawned:
		if _events[i]["view"] == view_id:
			_events[i]["seen"] = true


## Tab text shows how many unseen events wait in the other views, e.g. "LOGIN (2)".
func _update_tabs() -> void:
	for view_id: String in VIEW_IDS:
		var unseen := 0
		for i in _spawned:
			if _events[i]["view"] == view_id and not _events[i]["seen"] and view_id != _view_id:
				unseen += 1
		var button: Button = _tabs[view_id]
		button.text = view_id.to_upper() + (" (%d)" % unseen if unseen > 0 else "")


func _update_clock() -> void:
	var left := maxf(_duration - _elapsed, 0.0)
	_time_bar.max_value = _duration
	_time_bar.value = left
	var seconds := ceili(left)
	if seconds == _shown_second:
		return
	_shown_second = seconds
	_time_label.text = "TIME LEFT %02d:%02d" % [floori(seconds / 60.0), seconds % 60]
	var minutes := _start_minutes + int(_elapsed / seconds_per_company_minute)
	_view_panel.set_guide_text("Company time %s  |  New events keep arriving" % MonitoringData.minutes_to_clock(minutes))


func _update_score() -> void:
	_points_value.text = "%03d" % _score


func _on_report_requested(event: Dictionary) -> void:
	if not _running or event["reported"]:
		return # an event can be reported only once
	var points := MonitoringData.points_for(event, _data.get("points", {}))
	var result := MonitoringData.result_for(event)
	event["reported"] = true
	event["result"] = result
	event["points"] = points
	_score = maxi(0, _score + points) # the score never goes below 0
	_update_score()
	_view_panel.refresh_status()
	var headline := "CORRECT! %+d SECURITY POINTS" if result != "false_alarm" else "FALSE ALARM %+d SECURITY POINTS"
	_show_toast(headline % points, str(event.get("explain", "")), result == "false_alarm")


func _show_toast(title: String, text: String, bad_news: bool) -> void:
	_toast_title.text = title
	_toast_text.text = text
	# Good news: light box, dark text. Bad news: dark box with a border. The words say which.
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DARK if bad_news else COLOR_WHITE
	style.border_color = COLOR_WHITE
	style.set_border_width_all(2 if bad_news else 0)
	style.set_content_margin_all(5)
	_toast.add_theme_stylebox_override("panel", style)
	var text_color := COLOR_WHITE if bad_news else COLOR_DARK
	_toast_title.add_theme_color_override("font_color", text_color)
	_toast_text.add_theme_color_override("font_color", text_color)
	_toast.show()
	_toast_token += 1
	var token := _toast_token
	await get_tree().create_timer(TOAST_SECONDS).timeout
	if token == _toast_token: # a newer toast keeps its own full time
		_toast.hide()


func _finish() -> void:
	_running = false
	_toast_token += 1
	_toast.hide()
	var reported_ids: Array = []
	for event in _events:
		if event["reported"]:
			reported_ids.append(event["id"])
	GameState.security_points = _score
	GameState.reported_anomalies = reported_ids
	_objective.text = DONE_TEXT
	_results.show_results(MonitoringData.build_results(_events, _data, _score))
