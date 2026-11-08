extends CanvasLayer

## Developer shortcuts that sit on top of every screen: play any phase of the day, complete the current
## phase, and change the game state. Autoloaded; it removes itself in release builds. Press = to open it.
##
## A screen adds its own shortcuts under THIS SCREEN by having two methods:
##   debug_actions() -> Array   a list of [button text, Callable]
##   debug_info() -> String     one line shown under the title (optional)
## The panel is allowed to know the answers (is_clue and so on): it is a developer tool, never shown to players.

const TITLE_MENU_SCENE := "res://scenes/menus/TitleMenu.tscn"
const COLOR_LIGHT := Color("94b0c2")
const BONUS_POINTS := 100

var _shown_scene: Node # the scene the action list was built for

@onready var _window: Panel = %Window
@onready var _info: Label = %Info
@onready var _actions: VBoxContainer = %Actions


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return


func toggle() -> void:
	_window.visible = not _window.visible
	if _window.visible:
		_rebuild()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_EQUAL:
		toggle()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _window.visible:
		return
	if get_tree().current_scene != _shown_scene:
		_rebuild() # the scene changed: show that scene's actions
	_refresh_info()


func _rebuild() -> void:
	_shown_scene = get_tree().current_scene
	for child in _actions.get_children():
		_actions.remove_child(child)
		child.queue_free()

	_add_section("THIS SCREEN")
	if _shown_scene != null and _shown_scene.has_method("debug_actions"):
		for action: Array in _shown_scene.debug_actions():
			_add_action(action[0], _run_and_close.bind(action[1]))
	else:
		_add_note("Nothing to do on this screen.")

	# Each phase of the current day: its dialogue first, as in the game, or the phase itself.
	_add_section("PLAY A PHASE (DAY %d)" % GameState.current_day)
	for phase in GameState.PHASES:
		var info := GameState.phase_info(phase)
		var has_dialogue := not str(info.get("dialogue", "")).is_empty()
		var has_scene := not str(info.get("scene", "")).is_empty()
		if not has_dialogue and not has_scene:
			_add_action("%s (not built)" % phase.capitalize(), _play_phase.bind(phase, true), true)
			continue
		_add_action(phase.capitalize() + (" (dialogue)" if has_dialogue else ""), _play_phase.bind(phase, true))
		if has_scene and has_dialogue:
			_add_action("%s (skip dialogue)" % phase.capitalize(), _play_phase.bind(phase, false))

	_add_section("GO TO")
	_add_action("Title Menu", _go_to.bind(TITLE_MENU_SCENE))
	_add_action("Stage Select", SceneManager.load_stage_select.bind())

	_add_section("GAME STATE")
	_add_action("+%d Security Points" % BONUS_POINTS, _add_points.bind(BONUS_POINTS))
	_add_action("Reset game state", GameState.reset_progress)
	_refresh_info()


func _refresh_info() -> void:
	var scene_name := str(_shown_scene.name) if _shown_scene != null else "none"
	var line := ""
	if _shown_scene != null and _shown_scene.has_method("debug_info"):
		line = _shown_scene.debug_info()
	var slot := "SLOT %d" % (SaveManager.current_slot + 1) if SaveManager.current_slot >= 0 else "NO SLOT"
	_info.text = "%s   DAY %d: %s\n%s\nSECURITY POINTS: %d (%s)" % [
		scene_name, GameState.current_day, GameState.current_phase, line, GameState.wallet(), slot]


func _add_section(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_LIGHT)
	label.add_theme_font_override("font", preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf"))
	_actions.add_child(label)


func _add_note(text: String) -> void:
	var label := Label.new()
	label.text = text
	_actions.add_child(label)


func _add_action(text: String, action: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = text
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0, 16)
	button.pressed.connect(action)
	_actions.add_child(button)


## Runs one of the screen's own actions, then closes the panel.
func _run_and_close(action: Callable) -> void:
	toggle()
	action.call()


func _go_to(path: String) -> void:
	toggle()
	SceneManager.load_scene(path)


## Plays a phase of the current day, as the game would: its dialogue and then the phase, or the
## phase scene alone.
func _play_phase(phase: String, with_dialogue: bool) -> void:
	toggle()
	GameState.set_phase(phase)
	if with_dialogue:
		SceneManager.open_current_phase()
	else:
		SceneManager.load_scene(str(GameState.phase_info()["scene"]))


## Not saved to disk: it is saved with the next phase.
func _add_points(amount: int) -> void:
	var total := GameState.wallet() + amount
	GameState.security_points = total
	if SaveManager.current_slot >= 0:
		SaveManager.data["security_points"] = total
