class_name CaseData
extends RefCounted

## Reads the case file (data/day1_investigation.json) for the new Investigation. Static helpers
## only: no state, no UI. Every word the player sees comes from that file; this script only
## looks things up. Another day is another file: pass its path to load_case().

const CASE_PATH := "res://AI generated/data/day1_investigation.json"

static var _cache: Dictionary = {} # path -> parsed case


static func load_case(path: String = CASE_PATH) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("CaseData: cannot open %s (error %d)" % [path, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("CaseData: %s is not a valid JSON object" % path)
		return {}
	_cache[path] = parsed
	return parsed


## A text from the case's "ui" section. A missing key is shown as the key itself, so a gap in
## the data is easy to spot.
static func ui(case_data: Dictionary, key: String) -> String:
	var texts: Dictionary = case_data.get("ui", {})
	if not texts.has(key):
		push_warning("CaseData: no ui text '%s'" % key)
		return key
	return str(texts[key])


static func message(case_data: Dictionary, key: String) -> String:
	var texts: Dictionary = case_data.get("messages", {})
	if not texts.has(key):
		push_warning("CaseData: no message '%s'" % key)
		return key
	return str(texts[key])


## Ids of the evidence sources in tab order.
static func source_ids(case_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var sources: Dictionary = case_data.get("sources", {})
	for id: String in case_data.get("source_order", sources.keys()):
		if sources.has(id):
			ids.append(id)
	return ids


static func get_source(case_data: Dictionary, source_id: String) -> Dictionary:
	var sources: Dictionary = case_data.get("sources", {})
	return sources.get(source_id, {})


## {entry, source_id} for an entry id, or an empty Dictionary.
static func find_entry(case_data: Dictionary, entry_id: String) -> Dictionary:
	for source_id in source_ids(case_data):
		for entry: Dictionary in get_source(case_data, source_id).get("entries", []):
			if entry.get("id", "") == entry_id:
				return {"entry": entry, "source_id": source_id}
	return {}


## Every entry that is one of the real clues, in the order of the tabs.
static func clue_entries(case_data: Dictionary) -> Array[Dictionary]:
	var clues: Array[Dictionary] = []
	for source_id in source_ids(case_data):
		for entry: Dictionary in get_source(case_data, source_id).get("entries", []):
			if entry.get("is_clue", false):
				clues.append(entry)
	return clues


## The dictionary PhaseTransition.setup() expects, for the phase that follows the report.
static func transition_data(case_data: Dictionary, found_clues: int) -> Dictionary:
	var next: Dictionary = case_data.get("next", {})
	var required: int = case_data.get("clues_required", 0)
	var threat := str(case_data.get("threat_name", ""))
	return {
		"day_title": "DAY %d - %s" % [int(case_data.get("day", 1)), str(case_data.get("day_title", ""))],
		"headline": "OBJECTIVE COMPLETE",
		"phase_index": next.get("phase_index", 1),
		"carried": [
			"Threat: %s" % threat,
			"Evidence: %d of %d clues" % [mini(found_clues, required), required],
		],
		"next_title": next.get("title", ""),
		"next_description": next.get("description", ""),
		"button_text": next.get("button", "CONTINUE >"),
		"next_scene": next.get("scene", ""),
	}
