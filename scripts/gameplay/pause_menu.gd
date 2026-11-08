extends CanvasLayer

## Pause menu for the gameplay screens. Autoloaded, so it works everywhere without being
## part of any scene. Esc opens it; while it is open the game is frozen. It does nothing on
## the title menu or stage select.

const SETTINGS_SCENE := preload("res://autoload/settings/Settings.tscn")
const TITLE_MENU_SCENE := "res://scenes/menus/TitleMenu.tscn"
const MENU_LAYER := 90 # above the gameplay screens, below the loading screen (150)

## A scene counts as gameplay when its path starts with one of these.
const GAMEPLAY_PATHS: Array[String] = [
	"res://scenes/gameplay/",
	"res://AI generated/scenes/response/",
]

var _settings: CanvasLayer # the settings overlay, created the first time it is needed

@onready var _window: Panel = $Screen/Window
@onready var _resume_button: Button = $Screen/Window/Buttons/ResumeButton
@onready var _settings_button: Button = $Screen/Window/Buttons/SettingsButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keeps working while the tree is paused
	layer = MENU_LAYER
	hide()


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


func _on_resume_button_pressed() -> void:
	close()


func _on_settings_button_pressed() -> void:
	if _settings == null:
		_settings = SETTINGS_SCENE.instantiate() as CanvasLayer
		_settings.layer = MENU_LAYER + 1 # a nested CanvasLayer is not relative to this one
		_settings.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_settings)
		# The overlay hides itself with its own X button; bring the pause window back then.
		_settings.visibility_changed.connect(_on_settings_visibility_changed)
	_window.hide()
	_settings.show()


func _on_back_to_title_button_pressed() -> void:
	close()
	SceneManager.load_scene(TITLE_MENU_SCENE)


func _on_back_to_stage_select_button_pressed() -> void:
	close()
	SceneManager.load_stage_select()


func _on_settings_visibility_changed() -> void:
	if visible and not _settings.visible:
		_window.show()
		_settings_button.grab_focus()
