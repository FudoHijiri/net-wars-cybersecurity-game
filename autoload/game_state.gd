extends Node

## Autoload holding the state of the current run: which day is being played, the clues the
## player found, and what each phase hands to the next one.
##
## The days themselves are listed in data/days.json (the dialogue, the investigation scene, the
## case files). Add a day there and every scene that asks day_info() follows it.

signal clues_changed

const DAYS_PATH := "res://data/days.json"

## The day being played. Chosen on the stage select. reset_progress() keeps it.
var current_day: int = 1

## The table-based scenario of the current day (the first Investigation and its Report read it).
## The new Investigation reads its own case file, named in days.json.
var scenario: Dictionary = {}
## Entry id -> true for every entry the player marked as a clue.
var marked_clues: Dictionary = {}

# Handed from phase to phase.
## Ids of the entries that were marked when the report was accepted.
var investigation_evidence: Array = []
var identified_threat: String = ""
var security_points: int = 0
var reported_anomalies: Array = []

var _days: Dictionary = {} # day number as text -> that day's entry in days.json

# Built once per scenario, from the entries' "entities" lists only.
var _entry_order: Array[String] = []       # entry ids in scenario order
var _entries_by_id: Dictionary = {}         # id -> {"id", "app_id", "entry"}
var _entity_index: Dictionary = {}          # entity string -> Array of entry ids


func _ready() -> void:
	_days = _load_json(DAYS_PATH)
	set_day(current_day)


## What days.json says about a day (dialogue, investigation_scene, case, scenario), or an empty
## Dictionary for a day that is not built yet.
func day_info(day: int = current_day) -> Dictionary:
	var info: Dictionary = _days.get(str(day), {})
	return info


func has_day(day: int = current_day) -> bool:
	return not day_info(day).is_empty()


## Chooses the day to play and loads its scenario.
func set_day(day: int) -> void:
	current_day = day
	scenario = _load_json(str(day_info(day).get("scenario", "")))
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


## Number of entries the player currently has marked as clues.
func marked_count() -> int:
	return marked_clues.values().count(true)


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


## Clears everything the player has done so far. Used when a new game starts.
func reset_progress() -> void:
	marked_clues.clear()
	investigation_evidence = []
	identified_threat = ""
	security_points = 0
	reported_anomalies = []
	clues_changed.emit()


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
