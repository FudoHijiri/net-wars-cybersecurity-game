class_name MonitoringData
extends RefCounted

## Loading and scoring helpers for the Monitoring objective. Static, no state.
##
## A run's events are Dictionaries copied from the data file plus these flags set while
## playing: `seen` (bool), `reported` (bool), `result` ("correct", "important" or
## "false_alarm") and `points` (int).

const DATA_PATH := "res://AI generated/data/day1_monitoring.json"

const RESULT_TAGS := {"important": "IMPORTANT", "correct": "CORRECT", "false_alarm": "FALSE ALARM"}


static func load_data() -> Dictionary:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("MonitoringData: cannot open %s (error %d)" % [DATA_PATH, FileAccess.get_open_error()])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("MonitoringData: %s is not a valid JSON object" % DATA_PATH)
		return {}
	return parsed


## "02:43" -> 163 (minutes since midnight).
static func clock_to_minutes(clock: String) -> int:
	var parts := clock.split(":")
	return int(parts[0]) * 60 + int(parts[1]) if parts.size() == 2 else 0


## Minutes since midnight -> "02:43".
static func minutes_to_clock(minutes: int) -> String:
	return "%02d:%02d" % [floori(minutes / 60.0) % 24, minutes % 60]


## Points for reporting `event`: the anomaly rewards, or the false-alarm penalty.
static func points_for(event: Dictionary, points: Dictionary) -> int:
	if event.get("kind", "") != "anomaly":
		return int(points.get("false_alarm", 0))
	return int(points.get("important" if event.get("important", false) else "correct", 0))


static func result_for(event: Dictionary) -> String:
	if event.get("kind", "") != "anomaly":
		return "false_alarm"
	return "important" if event.get("important", false) else "correct"


## The dictionary MonitoringResults.show_results() expects, built from a finished run.
static func build_results(events: Array, data: Dictionary, score: int) -> Dictionary:
	var lines: Array[Dictionary] = []
	var first_false_alarm := ""
	var first_missed := ""
	var ordered := events.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["time"]) < str(b["time"]))
	for event: Dictionary in ordered:
		if event.get("reported", false):
			var result := str(event.get("result", ""))
			lines.append({"label": event["title"], "tag": RESULT_TAGS.get(result, ""),
				"points": event.get("points", 0), "reported": true})
			if result == "false_alarm" and first_false_alarm.is_empty():
				first_false_alarm = str(event.get("explain", ""))
		elif event.get("kind", "") == "anomaly":
			lines.append({"label": event["title"], "tag": "MISSED", "points": 0, "reported": false})
			if first_missed.is_empty():
				first_missed = str(event.get("explain", ""))
	var learned: Array[String] = []
	for text in [first_false_alarm, first_missed]:
		if not text.is_empty():
			learned.append(text)
	if learned.is_empty():
		learned.append(str(data.get("results", {}).get("perfect", "")))
	return {"lines": lines, "points": score, "learned": "\n\n".join(learned)}
