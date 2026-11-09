extends Node

## Autoload holding the state of the current run: which day is being played, the clues the
## player found, and what each phase hands to the next one.
##
## The days themselves are listed in data/days.json (the case files, and for each phase of the day
## the dialogue that opens it and the scene that follows). Add a day there and every scene that
## asks day_info() follows it.

signal clues_changed
signal recovery_changed

const DAYS_PATH := "res://data/days.json"
## The phases of a day, in play order. These are the keys of "phases" in days.json.
const PHASES: Array[String] = ["investigation", "monitoring", "hardening", "response", "recovery"]

## The day being played. Chosen on the stage select. reset_progress() keeps it.
var current_day: int = 1
## The phase being played (one of PHASES). The Dialogue scene plays this phase's dialogue.
## reset_progress() sets it back to the first phase.
var current_phase: String = PHASES[0]

## The data file of the current phase (the "data" of the phase in days.json), loaded by set_day()
## and set_phase(). For the investigation phase these are the tables of every app.
## The AI-generated Investigation reads its own case file, named in days.json.
var scenario: Dictionary = {}
## Entry id -> true for every real clue the player has found (an investigated entry whose
## "is_clue" is true).
var marked_clues: Dictionary = {}
## Entry id -> true for every entry the player has investigated, clue or not.
var investigated: Dictionary = {}

# Handed from phase to phase.
## Ids of the entries that were marked when the report was accepted.
var investigation_evidence: Array = []
var identified_threat: String = ""
var security_points: int = 0
var reported_anomalies: Array = []
## Story log id -> true for the Monitoring story logs the player has solved. They never come back.
## Not saved to the save slot yet.
var completed_story_logs: Dictionary = {}

## Response supplies component IDs through begin_recovery(). An empty list means no damage.
var response_damage: Array[String] = []
var recovery_completed_components: Array[String] = []
## An empty outcome means Response has not supplied clearance. Zero damage is separate.
var response_outcome: Dictionary = {}
var recovery_verification_passed: bool = false
## Component -> equipment instance ID. Chosen once by Recovery, retained on re-entry.
var recovery_equipment_assignments: Dictionary = {}
## Component -> wrong moves made while repairing it. Feeds the Recovery points (clean bonus).
var recovery_mistakes: Dictionary = {}
## Component -> what that finished repair left for later tasks (RecoveryTask.report).
var recovery_reports: Dictionary = {}

## Submitted findings for Recovery; generated Monitoring logs cannot be rebuilt from IDs.
var phase_findings: Dictionary = {}

var _days: Dictionary = {} # day number as text -> that day's entry in days.json

# Built once per scenario, from the entries' "entities" lists only.
var _entry_order: Array[String] = []       # entry ids in scenario order
var _entries_by_id: Dictionary = {}         # id -> {"id", "app_id", "entry"}
var _entity_index: Dictionary = {}          # entity string -> Array of entry ids


func _ready() -> void:
	_days = _load_json(DAYS_PATH)
	set_day(current_day)


## What days.json says about a day (case, phases), or an empty Dictionary for a day
## that is not built yet.
func day_info(day: int = current_day) -> Dictionary:
	var info: Dictionary = _days.get(str(day), {})
	return info


func has_day(day: int = current_day) -> bool:
	return not day_info(day).is_empty()


## The "dialogue" file, "scene" and "data" file of one phase of a day, or an empty Dictionary when that
## phase is not built yet.
func phase_info(phase: String = current_phase, day: int = current_day) -> Dictionary:
	var phases: Dictionary = day_info(day).get("phases", {})
	var info: Dictionary = phases.get(phase, {})
	return info


## True when the phase has a dialogue or a scene to open (see SceneManager.open_current_phase).
func is_phase_built(phase: String, day: int = current_day) -> bool:
	var info := phase_info(phase, day)
	return not str(info.get("dialogue", "")).is_empty() or not str(info.get("scene", "")).is_empty()


## Chooses the day to play and loads the data of the current phase.
func set_day(day: int) -> void:
	current_day = day
	_load_phase_data()
	_restore_day_progress()


## Chooses the phase to play and loads its data.
func set_phase(phase: String) -> void:
	current_phase = phase
	_load_phase_data()


## Returns the data for one investigation app ("email", "logs", ...), or an empty
## Dictionary when the scenario has no such app.
func get_app(app_id: String) -> Dictionary:
	var investigation: Dictionary = scenario.get("investigation", {})
	var app: Dictionary = investigation.get(app_id, {})
	return app


## The ids of the clues found so far in this run.
func found_clue_ids() -> Array:
	return marked_clues.keys().filter(func(id: String) -> bool: return marked_clues[id])


func is_marked(id: String) -> bool:
	return marked_clues.get(id, false)


func set_marked(id: String, value: bool) -> void:
	marked_clues[id] = value
	clues_changed.emit()


## Number of real clues the player has found so far.
func marked_count() -> int:
	return marked_clues.values().count(true)


## How many clues the day needs before the report: "clues_required" in the scenario.
func clues_required() -> int:
	return int(scenario.get("clues_required", 4))


func is_investigated(id: String) -> bool:
	return investigated.get(id, false)


func set_investigated(id: String) -> void:
	investigated[id] = true


## The OTHER entries (in any app) that share at least one entity with `entry_id`, each
## as {id, app_id, entry}. The ones sharing the most entities come first, then scenario
## order. Computed from the "entities" lists alone; it never looks at is_clue.
func related_entries(entry_id: String) -> Array:
	var source: Dictionary = _entries_by_id.get(entry_id, {})
	if source.is_empty():
		return []
	var shared: Dictionary = {} # other id -> number of shared entities
	for entity: String in source["entry"].get("entities", []):
		for other_id: String in _entity_index.get(entity, []):
			if other_id != entry_id:
				shared[other_id] = int(shared.get(other_id, 0)) + 1
	var related: Array = []
	for other_id: String in _entry_order:
		if shared.has(other_id):
			related.append(_entries_by_id[other_id])
	related.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if shared[a["id"]] != shared[b["id"]]:
			return shared[a["id"]] > shared[b["id"]]
		return _entry_order.find(a["id"]) < _entry_order.find(b["id"]))
	return related


## What the player has in the Security Points wallet: the loaded save slot's, or the run's own counter
## when no slot is loaded (a scene run alone).
func wallet() -> int:
	if SaveManager.current_slot >= 0:
		return int(SaveManager.data["security_points"])
	return security_points


## Takes points out of the wallet. False, and nothing taken, when the wallet holds less than `amount`.
## It does not save: the phase that spends calls SaveManager.save() when it ends.
func spend_points(amount: int) -> bool:
	if amount < 0 or wallet() < amount:
		return false
	add_points(-amount)
	return true


## Puts points into the wallet (or takes them out, with a negative amount). It does not save.
func add_points(amount: int) -> void:
	if SaveManager.current_slot >= 0:
		SaveManager.data["security_points"] = int(SaveManager.data["security_points"]) + amount
	else:
		security_points += amount


## Called by the existing results screen before its normal phase-completion save.
func capture_phase_findings(phase: String, monitoring_answers: Array = []) -> void:
	if phase == "investigation":
		investigation_evidence = marked_clues.keys().filter(func(id: String) -> bool: return is_marked(id))
		identified_threat = str(scenario.get("threat_name", ""))
		var findings: Array[String] = []
		for app: Dictionary in scenario.get("investigation", {}).values():
			for entry: Dictionary in app.get("entries", []):
				if investigation_evidence.has(str(entry.get("id", ""))):
					findings.append(str(entry.get("summary", entry.get("title", ""))))
		phase_findings[phase] = {"evidence": investigation_evidence.duplicate(), "threat": identified_threat, "findings": findings}
	elif phase == "monitoring":
		var reports: Array[Dictionary] = []
		for answer: Dictionary in monitoring_answers:
			if answer.get("reported", false):
				# A reported log judged wrong was normal: do not present it as a confirmed threat.
				reports.append({"id": str(answer.get("id", "")), "suspicious": answer.get("right", false) == true, "reason": str(answer.get("reason", ""))})
		phase_findings[phase] = {"reported_ids": reported_anomalies.duplicate(), "reports": reports}
	else:
		return
	if SaveManager.current_slot >= 0:
		SaveManager.data["phase_findings"][str(current_day)] = phase_findings.duplicate(true)


func _clear_recovery_progress() -> void:
	response_damage.clear()
	recovery_completed_components.clear()
	response_outcome.clear()
	recovery_verification_passed = false
	recovery_equipment_assignments.clear()
	recovery_mistakes.clear()
	recovery_reports.clear()
	recovery_changed.emit()


## Stage Select already calls set_day() after loading a slot; recover that day's context here.
func _restore_day_progress() -> void:
	phase_findings.clear()
	investigation_evidence = []
	identified_threat = ""
	reported_anomalies = []
	_clear_recovery_progress()
	if not is_instance_valid(SaveManager) or SaveManager.current_slot < 0:
		return
	phase_findings = SaveManager.data.get("phase_findings", {}).get(str(current_day), {}).duplicate(true)
	var investigation: Dictionary = phase_findings.get("investigation", {})
	investigation_evidence = investigation.get("evidence", []).duplicate()
	identified_threat = str(investigation.get("threat", ""))
	reported_anomalies = phase_findings.get("monitoring", {}).get("reported_ids", []).duplicate()
	var recovery: Dictionary = SaveManager.data.get("recovery_runs", {}).get(str(current_day), {})
	response_damage.assign(recovery.get("damage", []))
	recovery_completed_components.assign(recovery.get("completed", []))
	response_outcome = recovery.get("outcome", {}).duplicate(true)
	recovery_verification_passed = recovery.get("verified", false) == true
	recovery_equipment_assignments = recovery.get("equipment", {}).duplicate()
	recovery_mistakes = recovery.get("mistakes", {}).duplicate()
	recovery_reports = recovery.get("reports", {}).duplicate(true)
	recovery_changed.emit()


func _store_recovery_progress() -> void:
	if SaveManager.current_slot < 0:
		return
	SaveManager.data["recovery_runs"][str(current_day)] = {
		"damage": response_damage.duplicate(), "completed": recovery_completed_components.duplicate(),
		"outcome": response_outcome.duplicate(true), "verified": recovery_verification_passed,
		"equipment": recovery_equipment_assignments.duplicate(), "mistakes": recovery_mistakes.duplicate(), "reports": recovery_reports.duplicate(true),
	}
	SaveManager.save()


## True when the live work order is done: Response cleared the incident, every repair and the final check passed.
func can_finish_recovery() -> bool:
	if not recovery_verification_passed or response_outcome.get("contained", false) != true or response_outcome.get("received", false) != true:
		return false
	for component in response_damage:
		if not recovery_completed_components.has(component):
			return false
	return true


## Only the completed live work order may mark Recovery finished in the existing save slot.
func finish_recovery() -> bool:
	if not recovery_verification_passed or response_outcome.get("contained", false) != true or response_outcome.get("received", false) != true:
		return false
	for component in response_damage:
		if not recovery_completed_components.has(component):
			return false
	if SaveManager.current_slot >= 0:
		SaveManager.complete_phase(current_day, "recovery")
		return SaveManager.save()
	return true


## Clears everything the player has done so far. Used when a new game starts.
func reset_progress() -> void:
	set_phase(PHASES[0])
	marked_clues.clear()
	investigated.clear()
	investigation_evidence = []
	identified_threat = ""
	security_points = 0
	reported_anomalies = []
	completed_story_logs.clear() # clear, not replace: the Monitoring generator holds this Dictionary
	phase_findings.clear()
	_clear_recovery_progress()
	clues_changed.emit()


## Start Recovery after a battle. Re-entering the room must NOT call this again.
func begin_recovery(damaged_components: Array[String], outcome: Dictionary = {}) -> void:
	response_damage.clear()
	for component in damaged_components:
		if not response_damage.has(component):
			response_damage.append(component)
	recovery_completed_components.clear()
	response_outcome = outcome.duplicate(true)
	response_outcome["received"] = true
	recovery_verification_passed = false
	recovery_equipment_assignments.clear()
	recovery_mistakes.clear()
	recovery_reports.clear()
	_store_recovery_progress()
	recovery_changed.emit()

func assign_recovery_equipment(component_id: String, equipment_id: String) -> String:
	if response_outcome.get("received", false) != true or response_outcome.get("contained", false) != true:
		return ""
	if not RecoveryData.COMPONENT_IDS.has(component_id) or (component_id != RecoveryData.FINAL_CHECK and not response_damage.has(component_id)):
		return ""
	if not recovery_equipment_assignments.has(component_id):
		recovery_equipment_assignments[component_id] = equipment_id
		_store_recovery_progress()
	return str(recovery_equipment_assignments[component_id])


## Damage determines repairs; file_server records the required final verification even
## with zero damage. Each component can count only once per battle.
func complete_recovery_component(component_id: String, mistakes: int = 0, report: Dictionary = {}) -> bool:
	if response_outcome.get("received", false) != true or response_outcome.get("contained", false) != true:
		return false
	if not RecoveryData.COMPONENT_IDS.has(component_id) or recovery_completed_components.has(component_id):
		return false
	if component_id == RecoveryData.FINAL_CHECK:
		for damaged_id in response_damage:
			if damaged_id != RecoveryData.FINAL_CHECK and not recovery_completed_components.has(damaged_id):
				return false
		recovery_verification_passed = true
	elif not response_damage.has(component_id):
		return false
	recovery_completed_components.append(component_id)
	recovery_mistakes[component_id] = maxi(mistakes, 0)
	if not report.is_empty():
		recovery_reports[component_id] = report.duplicate(true)
	_store_recovery_progress()
	recovery_changed.emit()
	return true


## Reads a JSON file that holds one object. An empty path gives an empty Dictionary (a day with
## no file of that kind); a missing or broken file is reported.
func _load_json(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameState: cannot open %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("GameState: %s is not a valid JSON object" % path)
		return {}
	return parsed


func _load_phase_data() -> void:
	scenario = _load_json(str(phase_info().get("data", "")))
	_build_entity_index()


func _build_entity_index() -> void:
	_entry_order.clear()
	_entries_by_id.clear()
	_entity_index.clear()
	var investigation: Dictionary = scenario.get("investigation", {})
	for app_id: String in investigation:
		var app: Dictionary = investigation[app_id]
		for entry: Dictionary in app.get("entries", []):
			var id := str(entry.get("id", ""))
			_entry_order.append(id)
			_entries_by_id[id] = {"id": id, "app_id": app_id, "entry": entry}
			for entity: String in entry.get("entities", []):
				if not _entity_index.has(entity):
					_entity_index[entity] = []
				_entity_index[entity].append(id)
