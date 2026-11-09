class_name RecoveryRoom
extends Node2D

signal return_to_demo
const DIALOG_SCENE := preload("res://scenes/gameplay/recovery/ui/RecoveryDialog.tscn")
@export_file("*.json") var data_path: String = RecoveryData.DEFAULT_PATH
@export_group("Scene references")
@export var world: Node2D
@export var player: RecoveryPlayer
@export var hud: RecoveryHUD
## Repair screens and dialogs are added here, above the HUD.
@export var task_layer: CanvasLayer
## Shared results screen (FinishScreen) that pays the Security Points when the shift ends.
@export var finish_screen: FinishScreen

var demo_mode := false
var active_task: RecoveryTask
var dialog: RecoveryDialog
var summary: RecoveryDialog
var interactables: Array[RecoveryInteractable] = []
var _demo_damage: Array[String] = []
var _demo_completed: Array[String] = []
var _demo_equipment_assignments: Dictionary = {}
var _demo_mistakes: Dictionary = {}
var _demo_reports: Dictionary = {}
var _finishing := false
var _equipment_by_id: Dictionary = {}
var _missing_equipment: Array[String] = []
var _active_equipment_id := ""
var _outcome: Dictionary = {}
var _context: Dictionary = {}
var _data: Dictionary = {}
var _texts: Dictionary = {}
var _required: Array[String] = []
var _unknown: Array[String] = []
var _nearby: RecoveryInteractable
var _hud: Control
var _focus_before_pause: Control

## Explicit practice configuration before entering the tree. No shared state is modified.
func configure_demo(damage: Array[String], completed_components: Array[String] = [], outcome: Dictionary = {}, context: Dictionary = {}, equipment_assignments: Dictionary = {}) -> void:
	demo_mode = true
	_demo_damage = damage.duplicate()
	_demo_completed = completed_components.duplicate()
	_outcome = outcome.duplicate(true)
	_context = context.duplicate(true)
	_demo_equipment_assignments = equipment_assignments.duplicate()
	_demo_mistakes = {}
	_demo_reports = {}
	if _context.is_empty():
		_context = RecoveryContext.sample_context()

func _ready() -> void:
	_data = RecoveryData.load_data(data_path)
	_texts = _data.get("room", {})
	if not demo_mode:
		GameState.set_phase("recovery")
		_context = RecoveryContext.snapshot_live()
		_outcome = GameState.response_outcome.duplicate(true)
		GameState.recovery_changed.connect(_on_run_changed)
	PauseMenu.visibility_changed.connect(_on_pause_visibility_changed)
	_setup_hud()
	_register_stations()
	_refresh()
	open_briefing.call_deferred()

func _on_run_changed() -> void:
	_outcome = GameState.response_outcome.duplicate(true)
	_refresh()

## The HUD layout is authored in RecoveryHUD.tscn; only its text is set here.
func _setup_hud() -> void:
	_hud = hud.root
	hud.set_day(_context.get("day", 1))
	hud.set_practice(demo_mode)

func _register_stations() -> void:
	# Physical nodes belong to the authored scene. Only repair state belongs here.
	for candidate in world.find_children("*", "Area2D", true, false):
		if candidate is not RecoveryInteractable:
			continue
		var station := candidate as RecoveryInteractable
		if not station.enabled:
			continue
		if station.kind == "work_order" and station.equipment_id.is_empty():
			station.equipment_id = "office_exit"
		if station.equipment_id.is_empty() or _equipment_by_id.has(station.equipment_id):
			push_error("Missing or duplicate Recovery equipment ID: " + station.equipment_id)
			continue
		_equipment_by_id[station.equipment_id] = station
		interactables.append(station)

## Wrong moves per finished repair, for the clean bonus.
func mistakes() -> Dictionary:
	return _demo_mistakes if demo_mode else GameState.recovery_mistakes

## What finished repairs left for later tasks (RecoveryTask.report), by component.
func reports() -> Dictionary:
	return _demo_reports if demo_mode else GameState.recovery_reports

## What the results screen will show and pay for this work order.
func results() -> Dictionary:
	return RecoveryData.results(_data, _required, mistakes())

func equipment_assignments() -> Dictionary:
	return _demo_equipment_assignments if demo_mode else GameState.recovery_equipment_assignments

func _ensure_equipment_selection() -> void:
	_missing_equipment.clear()
	if not is_ready():
		return
	var rules: Dictionary = _data.get("equipment_selection", {})
	if _context.get("profile", "") == "backup":
		rules = _data.get("practice_equipment_selection", rules)
	var taken: Array = equipment_assignments().values()
	for component in _required:
		var chosen := str(equipment_assignments().get(component, ""))
		if chosen.is_empty():
			# Any free machine in the Day's eligible groups can host this minigame.
			var candidates: Array[String] = []
			var groups: Array = rules.get(component, [])
			for item in interactables:
				if item.kind == "task" and groups.has(item.equipment_group) and not taken.has(item.equipment_id):
					candidates.append(item.equipment_id)
			if not candidates.is_empty():
				chosen = candidates.pick_random()
				if demo_mode:
					_demo_equipment_assignments[component] = chosen
				else:
					chosen = GameState.assign_recovery_equipment(component, chosen)
				taken.append(chosen)
		if _equipment_by_id.has(chosen):
			_equipment_by_id[chosen].target = component
		else:
			_missing_equipment.append(component)

func station_status(item: RecoveryInteractable) -> String:
	if item.kind == "work_order":
		return "restored" if can_finish() else "needs_repair"
	if not is_ready():
		return "waiting"
	if equipment_assignments().get(item.target, "") != item.equipment_id:
		return "working"
	return _status(item.target)

func _physics_process(_delta: float) -> void:
	if is_instance_valid(active_task) or is_instance_valid(dialog) or _finishing:
		return
	var closest: RecoveryInteractable
	var distance := INF
	var best_priority := 2
	for item in interactables:
		if not item.is_in_reach(player):
			continue
		var d := player.global_position.distance_to(item.interaction_shape.global_position)
		# Closely placed furniture can share reach zones. Keep an available repair
		# from losing the E prompt to an adjacent healthy prop.
		var priority := 0 if item.kind == "task" and station_status(item) == "needs_repair" else 1
		if priority < best_priority or (priority == best_priority and d < distance):
			closest = item
			distance = d
			best_priority = priority
	if closest != _nearby:
		_nearby = closest
		_update_hint()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode == KEY_E or event.keycode == KEY_E):
		if not _finishing and not is_instance_valid(active_task) and not is_instance_valid(dialog) and is_instance_valid(_nearby):
			interact(_nearby)
			get_viewport().set_input_as_handled()

## Proximity is enforced here too: a remote caller cannot open a task or finish a shift.
func interact(item: RecoveryInteractable) -> void:
	if not interactables.has(item) or not item.is_in_reach(player):
		return
	if is_instance_valid(active_task) or is_instance_valid(dialog):
		return
	match item.kind:
		"work_order":
			if can_finish():
				show_summary()
			else:
				open_briefing()
		"task":
			open_station(item)

func _damage() -> Array[String]:
	return _demo_damage if demo_mode else GameState.response_damage

func completed_components() -> Array[String]:
	return _demo_completed if demo_mode else GameState.recovery_completed_components

func repairs_done() -> int:
	var done := 0
	for id in _required:
		if completed_components().has(id):
			done += 1
	return done

func is_ready() -> bool:
	return RecoveryContext.is_cleared(_outcome) and _context.get("profile", "unsupported") in ["day1", "backup"]

func restoration_done() -> bool:
	for id in _required:
		if id != RecoveryData.FINAL_CHECK and not completed_components().has(id):
			return false
	return true

func can_finish() -> bool:
	return is_ready() and _unknown.is_empty() and _missing_equipment.is_empty() and repairs_done() == _required.size()

func _refresh() -> void:
	_required = RecoveryContext.required_components(_damage())
	_ensure_equipment_selection()
	_unknown.clear()
	for id in _damage():
		if not RecoveryData.COMPONENT_IDS.has(id) and not _unknown.has(id):
			_unknown.append(id)
	for item in interactables:
		item.set_status(station_status(item))
	if is_instance_valid(_hud):
		hud.set_counter(str(_texts.get("counter", "")).format({"done": repairs_done(), "total": _required.size()}))
		_update_controls()
		_update_hint()

func _status(id: String) -> String:
	if completed_components().has(id):
		return "restored"
	if not is_ready():
		return "waiting"
	if not _required.has(id):
		return "working"
	if id == RecoveryData.FINAL_CHECK and not restoration_done():
		return "locked"
	return "needs_repair"

func _update_controls() -> void:
	var modal := is_instance_valid(active_task) or is_instance_valid(dialog) or _finishing
	player.set_movement_enabled(not modal)

func _update_hint() -> void:
	if not is_instance_valid(_hud):
		return
	var text := str(_texts.get("controls", ""))
	if not _unknown.is_empty():
		text = str(_texts.get("unknown_damage", "")).format({"ids": ", ".join(_unknown)})
	elif not _missing_equipment.is_empty():
		text = "Equipment missing for: " + ", ".join(_missing_equipment)
	elif is_instance_valid(_nearby):
		if _nearby.kind == "work_order":
			text = "E  " + str(_texts.get("finish" if can_finish() else "work_order", ""))
		else:
			text = "E  " + _nearby.title + "  /  " + str(_data.get("task_ui", {}).get(station_status(_nearby), ""))
	elif can_finish():
		text = str(_texts.get("all_done", ""))
	hud.set_hint(text)

func open_station(station: RecoveryInteractable) -> void:
	if not interactables.has(station) or not station.is_in_reach(player):
		return
	if is_instance_valid(active_task) or is_instance_valid(dialog) or station.kind != "task":
		return
	var status := station_status(station)
	if status != "needs_repair":
		var message := str(_texts.get("waiting_body" if status == "waiting" else ("verify_locked" if status == "locked" else "not_required"), ""))
		_show_dialog(station.title, [message], [{"id": "close", "label": str(_texts.get("close", "CLOSE")), "callback": close_dialog}])
		return
	if not _unknown.is_empty():
		return
	var task_content: Dictionary = _data.get("components", {}).get(station.target, {}).duplicate(true)
	# A Day can give a component its own scene ("scene"); practice scenarios keep the registered one.
	var scene: PackedScene = RecoveryData.task_scene(station.target)
	if task_content.has("scene") and _context.get("profile", "") != "backup":
		scene = load(str(task_content["scene"])) as PackedScene
	active_task = scene.instantiate() as RecoveryTask
	_active_equipment_id = station.equipment_id
	task_content["memory"] = reports().duplicate(true)
	# The task is drawn as this machine's screen: its name and group fill the title bar.
	task_content["machine"] = {"name": station.title, "group": station.equipment_group}
	if _context.get("profile", "") == "backup" and station.target == "file_server":
		task_content["title"] = "Verify the restored database"
		task_content["instruction"] = "Check the restored records, access details, and an ordinary test file before returning to use."
		var checks: Array = task_content.get("checks", [])
		checks[0]["label"] = "RESTORED RECORDS"
		checks[0]["expected"] = "Trusted record: all sample records should be present."
		checks[0]["passed"] = "The restored sample records match the trusted list."
		checks[0]["failed"] = "Some restored records do not match. Recovery is still open."
		checks[1]["label"] = "ACCESS DETAILS"
		checks[1]["expected"] = "Trusted record: approved access details should match."
		checks[1]["comparison"] = "Approved: code A2\nRestored: {observed}"
		checks[1]["trusted_contact"] = "code A2"
		checks[1]["untrusted_contact"] = "code B8"
		checks[1]["passed"] = "The restored access details match the trusted record."
		task_content["lesson"] = str(_data.get("practice", {}).get("lesson", ""))
		task_content["success"] = "All checks passed. Expected records and ordinary access work."
		if _context.get("practice_kind", "") == "server":
			task_content["title"] = "Verify the checked server"
			task_content["instruction"] = "Test normal access and expected records before returning this server to use."
			checks[0]["label"] = "SERVER RECORDS"
			checks[0]["passed"] = "The expected sample records are available."
	active_task.configure(task_content, _data.get("task_ui", {}), _outcome)
	active_task.practice_mode = demo_mode
	active_task.completed.connect(_on_task_completed)
	active_task.closed.connect(close_task)
	task_layer.add_child(active_task)
	_update_controls()

func _on_task_completed(id: String) -> void:
	if not is_ready() or not _required.has(id) or (id == RecoveryData.FINAL_CHECK and not restoration_done()):
		return
	if _active_equipment_id != equipment_assignments().get(id, ""):
		return
	var wrong: int = active_task.mistakes if is_instance_valid(active_task) else 0
	var left: Dictionary = active_task.report if is_instance_valid(active_task) else {}
	if demo_mode:
		if not _demo_completed.has(id):
			_demo_completed.append(id)
			_demo_mistakes[id] = wrong
			if not left.is_empty():
				_demo_reports[id] = left.duplicate(true)
		_refresh()
	else:
		GameState.complete_recovery_component(id, wrong, left)

func close_task() -> void:
	if not is_instance_valid(active_task):
		return
	var task := active_task
	active_task = null
	_active_equipment_id = ""
	task_layer.remove_child(task)
	task.queue_free()
	_update_controls()
	_update_hint()

func _show_dialog(title: String, paragraphs: Array[String], actions: Array[Dictionary]) -> void:
	if is_instance_valid(dialog):
		return
	dialog = DIALOG_SCENE.instantiate() as RecoveryDialog
	dialog.configure(title, paragraphs, actions)
	task_layer.add_child(dialog)
	_update_controls()

func close_dialog() -> void:
	if not is_instance_valid(dialog):
		return
	var old := dialog
	dialog = null
	if summary == old:
		summary = null
	task_layer.remove_child(old)
	old.queue_free()
	_update_controls()
	_update_hint()

func open_briefing() -> void:
	if is_instance_valid(dialog) or is_instance_valid(active_task):
		return
	var paragraphs: Array[String] = [
		str(_context.get("title", "")) + " / " + str(_context.get("threat", "")),
		str(_context.get("brief", "")),
		"Tasks\n" + _work_order_text(),
	]
	if not is_ready():
		paragraphs.append(str(_texts.get("waiting_body", "")))
	elif demo_mode:
		paragraphs.append("Practice scenario. Response results are simulated.")
	var actions: Array[Dictionary] = [
		{"id": "close", "label": "Back to work", "callback": close_dialog},
		{"id": "findings", "label": "Findings", "callback": _show_findings},
		{"id": "credits", "label": "Art credits", "callback": _show_credits},
	]
	if demo_mode:
		actions.append({"id": "lab", "label": "Practice menu", "callback": _return_to_lab})
	_show_dialog(str(_texts.get("work_order" if is_ready() else "waiting", "")), paragraphs, actions)

func _show_findings() -> void:
	close_dialog()
	var paragraphs: Array[String] = [
		"Investigation\n" + ("\n".join(_context.get("evidence", [])) if not _context.get("evidence", []).is_empty() else "No submitted evidence is available."),
		"Monitoring reports\n" + ("\n".join(_context.get("reports", [])) if not _context.get("reports", []).is_empty() else "No monitoring reports are available."),
		"Hardening\n" + str(_outcome.get("hardening_summary", _context.get("hardening", ""))),
		"Response\n" + (str(_outcome.get("summary", "Containment confirmed.")) if is_ready() else str(_texts.get("waiting_body", ""))),
	]
	_show_dialog("Earlier findings", paragraphs, [{"id": "back", "label": "Back to work order", "callback": _back_to_briefing}])

func _show_credits() -> void:
	close_dialog()
	_show_dialog("Art credits", RecoveryData.credits(_data), [{"id": "back", "label": "Back to work order", "callback": _back_to_briefing}])

func _back_to_briefing() -> void:
	close_dialog()
	open_briefing()

func _work_order_text() -> String:
	var lines: Array[String] = []
	for id in _required:
		var marker := "[OK]" if completed_components().has(id) else "[ ]"
		var station := get_interactable(id)
		var equipment := station.title + ": " if station != null else ""
		lines.append(marker + " " + equipment + str(_data.get("components", {}).get(id, {}).get("title", id)))
	if not _damage().has("backup_database"):
		lines.append("No backup restoration is required for this work order.")
	return "\n".join(lines)

func show_summary() -> void:
	var terminal := get_interactable("work_order")
	if terminal == null or not terminal.is_in_reach(player) or not can_finish():
		return
	if is_instance_valid(dialog) or is_instance_valid(active_task):
		return
	var lesson := str(_data.get("practice" if _context.get("profile", "") == "backup" else "case", {}).get("lesson", ""))
	lesson = str(_context.get("lesson", lesson))
	var paragraphs: Array[String] = [
		str(_context.get("title", "")),
		str(_texts.get("summary_body", "")),
		_work_order_text(),
		"What you checked\n" + lesson,
		str(_texts.get("summary_lesson", "")),
	]
	var actions: Array[Dictionary] = [
		{"id": "return", "label": str(_texts.get("return", "")), "callback": _finish_shift},
		{"id": "close", "label": "Back to room", "callback": close_dialog},
	]
	if demo_mode:
		actions.append({"id": "lab", "label": "Practice menu", "callback": _return_to_lab})
	_show_dialog(str(_texts.get("summary_title", "")), paragraphs, actions)
	summary = dialog

func get_interactable(target: String) -> RecoveryInteractable:
	var selected := str(equipment_assignments().get(target, ""))
	if _equipment_by_id.has(selected):
		return _equipment_by_id[selected]
	for item in interactables:
		if item.target == target:
			return item
	return null

func get_equipment(equipment_id: String) -> RecoveryInteractable:
	return _equipment_by_id.get(equipment_id) as RecoveryInteractable

func _return_to_lab() -> void:
	return_to_demo.emit()

## Shows the results and pays the Security Points (FinishScreen saves and marks Recovery complete).
## CONTINUE then returns to Stage Select; in practice nothing is paid and CONTINUE goes back to the lab.
func _finish_shift() -> void:
	if _finishing or not can_finish() or (not demo_mode and not GameState.can_finish_recovery()):
		return
	close_dialog()
	_finishing = true
	_update_controls()
	var summary_data := results()
	summary_data["practice"] = demo_mode
	if demo_mode and not finish_screen.continue_requested.is_connected(_on_practice_continue):
		finish_screen.continue_requested.connect(_on_practice_continue)
	finish_screen.show_results(summary_data)

func _on_practice_continue() -> void:
	finish_screen.hide()
	_finishing = false
	if return_to_demo.get_connections().is_empty():
		SceneManager.load_stage_select()
	else:
		_return_to_lab()


func _on_pause_visibility_changed() -> void:
	if PauseMenu.visible:
		_focus_before_pause = get_viewport().gui_get_focus_owner()
	elif is_instance_valid(_focus_before_pause) and _focus_before_pause.is_visible_in_tree():
		_focus_before_pause.grab_focus.call_deferred()
