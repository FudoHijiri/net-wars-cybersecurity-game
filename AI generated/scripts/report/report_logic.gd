class_name ReportLogic
extends RefCounted

## Rules of the Investigation report. Static helpers only: no state, no UI.

const REPORT_PATH := "res://AI generated/data/day1_report.json"


static func load_report_data() -> Dictionary:
	var file := FileAccess.open(REPORT_PATH, FileAccess.READ)
	if file == null:
		push_error("ReportLogic: cannot open %s (error %d)" % [REPORT_PATH, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("ReportLogic: %s is not a valid JSON object" % REPORT_PATH)
		return {}
	return parsed


## Every marked entry as {id, label, source}, in the order the player marked them.
## `source` is the app it was found in, upper-case ("LOGS").
static func get_marked_evidence() -> Array[Dictionary]:
	var labels: Dictionary = load_report_data().get("clue_labels", {})
	var evidence: Array[Dictionary] = []
	for id: String in marked_ids():
		var found := find_entry(id)
		if found.is_empty():
			continue
		var entry: Dictionary = found["entry"]
		evidence.append({
			"id": id,
			"label": str(labels.get(id, entry.get("title", id))),
			"source": str(found["app_id"]).to_upper(),
		})
	return evidence


static func marked_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: String in GameState.marked_clues:
		if GameState.marked_clues[id]:
			ids.append(id)
	return ids


## How many of the marked entries are real clues. Never shown to the player directly.
static func real_clue_count() -> int:
	var count := 0
	for id in marked_ids():
		var found := find_entry(id)
		if not found.is_empty() and found["entry"].get("is_clue", false):
			count += 1
	return count


## {ok, reason}. reason is one of "no_threat", "not_enough", "mismatch", "ok".
static func evaluate(picked_threat: String) -> Dictionary:
	var required: int = load_report_data().get("required_clues", 0)
	if picked_threat.is_empty():
		return {"ok": false, "reason": "no_threat"}
	if real_clue_count() < required:
		return {"ok": false, "reason": "not_enough"}
	if picked_threat != GameState.scenario.get("threat_name", ""):
		return {"ok": false, "reason": "mismatch"}
	return {"ok": true, "reason": "ok"}


## {entry, app_id} for an entry id, or an empty Dictionary.
static func find_entry(entry_id: String) -> Dictionary:
	var investigation: Dictionary = GameState.scenario.get("investigation", {})
	for app_id: String in investigation:
		var app: Dictionary = investigation[app_id]
		for entry: Dictionary in app.get("entries", []):
			if entry.get("id", "") == entry_id:
				return {"entry": entry, "app_id": app_id}
	return {}


## "DAY 1 - AN UNUSUAL LOGIN", or just "DAY 1" when the data has no day title.
static func day_title() -> String:
	var day: int = GameState.scenario.get("day", 1)
	var title := str(load_report_data().get("day_title", ""))
	return "DAY %d - %s" % [day, title] if not title.is_empty() else "DAY %d" % day


## The dictionary PhaseTransition.setup() expects, for the phase that follows the report.
static func build_transition_data(threat: String) -> Dictionary:
	var report := load_report_data()
	var next: Dictionary = report.get("next", {})
	var required: int = report.get("required_clues", 0)
	return {
		"day_title": day_title(),
		"headline": "OBJECTIVE COMPLETE",
		"phase_index": next.get("phase_index", 1),
		"carried": [
			"Threat: %s" % threat,
			"Evidence: %d of %d clues" % [mini(real_clue_count(), required), required],
		],
		"next_title": next.get("title", ""),
		"next_description": next.get("description", ""),
		"button_text": next.get("button", "CONTINUE >"),
		"next_scene": next.get("scene", ""),
	}
