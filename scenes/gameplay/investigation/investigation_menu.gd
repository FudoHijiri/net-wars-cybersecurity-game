extends Control

## Tab bar of the Investigation screen. One AppViewPanel is reused for every tab.
## The shown app is also named in the panel's title, so the active tab is never
## signalled by the button's pressed color alone.
##
## The buttons' `pressed` signals are connected in InvestigationMenu.tscn.

const DEFAULT_APP := "email"
const REPORT_PANEL_SCENE := preload("res://AI generated/scenes/report/ReportPanel.tscn")

var _report_panel: ReportPanel # created the first time REPORT is pressed

@onready var _clues_found: RichTextLabel = get_node("FramePanel/MainPanel/CluesFound")
@onready var _app_view: AppViewPanel = %AppViewPanel # one panel for all tabs
@onready var _email_button: Button = %EmailButton
@onready var _logs_button: Button = %LogsButton
@onready var _computers_button: Button = %ComputersButton
@onready var _login_button: Button = %LoginButton
@onready var _files_button: Button = %FilesButton
@onready var _net_button: Button = %NetButton
@onready var _servers_button: Button = %ServersButton


func _ready() -> void:
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


func _on_reports_button_pressed() -> void:
	if _report_panel == null:
		_report_panel = REPORT_PANEL_SCENE.instantiate() as ReportPanel
		add_child(_report_panel) # in the tree first, then size it
		_report_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_report_panel.open()


func _update_clues_found() -> void:
	_clues_found.text = "Found Clues: %02d" % GameState.marked_count()


func _on_exit_button_pressed() -> void:
	PauseMenu.open() # the title-bar X opens the pause menu
