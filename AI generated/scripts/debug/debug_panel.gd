extends CanvasLayer

## Developer shortcuts that sit on top of every screen: jump between phases, complete the
## current phase, mark clues, reset the game state. Autoloaded; it removes itself in
## release builds. Press F9 to open it.
##
## The panel is allowed to read `is_clue`: that is a developer tool, never shown to players.

const TRANSITION_SCENE := preload("res://AI generated/scenes/transition/PhaseTransition.tscn")
const TITLE_MENU_SCENE := "res://scenes/menus/TitleMenu.tscn"
const COLOR_LIGHT := Color("94b0c2")

## Where to jump to. Scenes that don't exist yet are listed as disabled and switch on by
## themselves once the file exists.
const DESTINATIONS := [
	["Title Menu", TITLE_MENU_SCENE],
	["Stage Select", ""], # special: the title menu with the stage select showing
	["Investigation", "res://scenes/gameplay/investigation/Investigation.tscn"],
	["Monitoring", "res://AI generated/scenes/monitoring/Monitoring.tscn"],
	["Hardening", "res://scenes/gameplay/hardening/Hardening.tscn"],
	["Response", "res://scenes/gameplay/response/Response.tscn"],
	["Recovery", "res://scenes/gameplay/recovery/Recovery.tscn"],
]

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
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
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
	PhaseTransition.clear_children(_actions)
	var path := _shown_scene.scene_file_path if _shown_scene != null else ""
	_add_section("THIS PHASE")
	if path.ends_with("Investigation.tscn"):
		_add_action("COMPLETE PHASE >", _complete_investigation)
		_add_action("Mark all real clues", _mark_real_clues)
		_add_action("Clear all marks", _clear_marks)
	elif path.ends_with("Monitoring.tscn"):
		_add_action("COMPLETE PHASE (perfect run) >", _complete_monitoring.bind(true))
		_add_action("Skip to results (no reports) >", _complete_monitoring.bind(false))
	else:
		_add_note("Nothing to complete on this screen.")
	_add_section("GO TO")
	for destination: Array in DESTINATIONS:
		var target: String = destination[1]
		var exists := target.is_empty() or ResourceLoader.exists(target)
		_add_action(destination[0] if exists else "%s (not built)" % destination[0], _go_to.bind(target), not exists)
	_add_section("GAME STATE")
	_add_action("Reset game state", _reset_state)
	_refresh_info()


func _refresh_info() -> void:
	var scene_name := str(_shown_scene.name) if _shown_scene != null else "none"
	_info.text = "SCENE: %s\nMARKED: %d (%d real)   THREAT: %s\nSECURITY POINTS: %d" % [
		scene_name, GameState.marked_count(), ReportLogic.real_clue_count(),
		GameState.identified_threat if not GameState.identified_threat.is_empty() else "-",
		GameState.security_points]


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


func _go_to(path: String) -> void:
	toggle()
	if path.is_empty():
		PhaseTransition.go_to_stage_select(get_tree())
	else:
		get_tree().change_scene_to_file(path)


func _mark_real_clues() -> void:
	var investigation: Dictionary = GameState.scenario.get("investigation", {})
	for app: Dictionary in investigation.values():
		for entry: Dictionary in app.get("entries", []):
			if entry.get("is_clue", false):
				GameState.set_marked(str(entry["id"]), true)


func _clear_marks() -> void:
	for id: String in GameState.marked_clues.keys():
		GameState.marked_clues[id] = false
	GameState.clues_changed.emit()


## Same outcome as a correct report: save the evidence and threat, then show the card
## that leads to the next phase.
func _complete_investigation() -> void:
	_mark_real_clues()
	var threat := str(GameState.scenario.get("threat_name", ""))
	GameState.investigation_evidence = ReportLogic.marked_ids()
	GameState.identified_threat = threat
	var card := TRANSITION_SCENE.instantiate() as PhaseTransition
	get_tree().current_scene.add_child(card) # in the tree first, then setup
	card.setup(ReportLogic.build_transition_data(threat))
	toggle()


func _complete_monitoring(perfect_run: bool) -> void:
	var menu := get_tree().current_scene.get_node_or_null("%MonitoringMenu") as MonitoringMenu
	if menu == null:
		return
	menu.debug_complete(perfect_run)
	toggle()


func _reset_state() -> void:
	GameState.reset_progress()
