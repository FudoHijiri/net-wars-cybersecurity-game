extends CanvasLayer

## Pause menu for the gameplay screens. Autoloaded, so it works everywhere without being
## part of any scene. Esc opens it; while it is open the game is frozen (the Monitoring
## clock stops too). It does nothing on the title menu or stage select.

const SETTINGS_SCENE := preload("res://scenes/menus/SettingsOverlay.tscn")
const TITLE_MENU_SCENE := "res://scenes/menus/TitleMenu.tscn"

## A scene counts as gameplay when its path starts with one of these.
const GAMEPLAY_PATHS: Array[String] = [
	"res://scenes/gameplay/",
	"res://AI generated/scenes/monitoring/Monitoring.tscn",
]

var _settings: Control # the existing settings overlay, created the first time it is needed

@onready var _screen: Control = %Screen
@onready var _window: Panel = %Window
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _stage_select_button: Button = %StageSelectButton
@onready var _main_menu_button: Button = %MainMenuButton


func _ready() -> void:
	_resume_button.pressed.connect(close)
	_settings_button.pressed.connect(_open_settings)
	_stage_select_button.pressed.connect(_go_to_stage_select)
	_main_menu_button.pressed.connect(_go_to_title_menu)


func is_open() -> bool:
	return visible


## True on the screens where pausing makes sense.
func in_gameplay() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for prefix in GAMEPLAY_PATHS:
		if scene.scene_file_path.begins_with(prefix):
			return true
	return false


func open() -> void:
	if visible or not in_gameplay():
		return
	get_tree().paused = true
	_window.show()
	show()
	_resume_button.grab_focus() # keyboard users can arrow up and down from here


func close() -> void:
	if _settings != null:
		_settings.hide()
	get_tree().paused = false
	hide()


func toggle() -> void:
	if visible:
		close()
	else:
		open()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"): # Esc
		return
	if visible and _settings != null and _settings.visible:
		_settings.hide() # back from settings to the pause window
	else:
		toggle()
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# The scene changed underneath us (for example through the debug panel).
	if visible and not in_gameplay():
		close()


func _open_settings() -> void:
	if _settings == null:
		_settings = SETTINGS_SCENE.instantiate()
		_screen.add_child(_settings)
		# The overlay hides itself with its own X button; bring the pause window back then.
		_settings.visibility_changed.connect(_on_settings_visibility_changed)
	_window.hide()
	_settings.show()


func _on_settings_visibility_changed() -> void:
	if visible and not _settings.visible:
		_window.show()
		_settings_button.grab_focus()


func _go_to_stage_select() -> void:
	close()
	PhaseTransition.go_to_stage_select(get_tree())


func _go_to_title_menu() -> void:
	close()
	SceneFade.go(get_tree(), TITLE_MENU_SCENE)
