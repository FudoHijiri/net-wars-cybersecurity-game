extends Node

## Autoload holding the active scenario and, later, the player's marked clues.
##
## Phase 1 only loads the scenario data. The clue functions are stubs so the UI can
## already be wired to them.

signal clues_changed

const SCENARIO_PATH := "res://data/scenarios/day1_credential_abuse.json"

var scenario: Dictionary = {}
## Entry id -> true for every entry the player marked as a clue.
var marked_clues: Dictionary = {}

# Filled in by the Report and Monitoring phases.
## Ids of the marked entries, saved when the report is accepted.
var investigation_evidence: Array = []
var identified_threat: String = ""
var security_points: int = 0
var reported_anomalies: Array = []

# Built once when the scenario loads, from the entries' "entities" lists only.
var _entry_order: Array[String] = []       # entry ids in scenario order
var _entries_by_id: Dictionary = {}         # id -> {"id", "app_id", "entry"}
var _entity_index: Dictionary = {}          # entity string -> Array of entry ids


func _ready() -> void:
	scenario = _load_scenario(SCENARIO_PATH)
	_build_entity_index()


## Returns the data for one investigation app ("email", "logs", ...), or an empty
## Dictionary when the scenario has no such app.
func get_app(app_id: String) -> Dictionary:
	var investigation: Dictionary = scenario.get("investigation", {})
	var app: Dictionary = investigation.get(app_id, {})
	return app


func is_marked(id: String) -> bool:
	return marked_clues.get(id, false)


func set_marked(id: String, value: bool) -> void:
	marked_clues[id] = value
	clues_changed.emit()


func _load_scenario(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("GameState: cannot open scenario %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("GameState: scenario %s is not a valid JSON object" % path)
		return {}
	return parsed


## Number of entries the player currently has marked as clues.
func marked_count() -> int:
	var count := 0
	for id: String in marked_clues:
		if marked_clues[id]:
			count += 1
	return count


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


## Clears everything the player has done so far. Used when a new game starts.
func reset_progress() -> void:
	marked_clues.clear()
	investigation_evidence = []
	identified_threat = ""
	security_points = 0
	reported_anomalies = []
	clues_changed.emit()
