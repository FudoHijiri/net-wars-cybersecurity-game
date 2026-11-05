class_name LogGenerator
extends RefCounted

## Builds the logs of a Monitoring shift from the shift's data file (data/scenarios/day N/monitoring.json).
##
## A log is {id, number, title, parts, truth, story_id}. Each part is {key, label, value, state, hint,
## entity} with state "ok", "odd" or "bad". The parts and the truth come from the same rules, so the
## right answer is never written by hand: truth is {kind, suspicious, violations, reason}.
##
## Kinds: normal (follows every rule), bad (breaks 1 or 2 rules), decoy (looks odd, follows the rules).
## The first logs follow "guided_kinds"; after that a shuffle bag ("mix") sets the kind of each log.
##
## Random people are a first name and a last name, each drawn from its own shuffled bag, so the names
## stay different for a long time. Their computer is named after them, which the computer rule accepts.
##
## Story logs ("story_logs") are written out in the data and are about the case's victim. They are
## the same every time and each one shows up at most once per shift, with a chance that grows with
## the number of logs the player has solved. A story log in `story_done` (log ids kept by the caller,
## for example GameState) never shows up again. They still go through the rules like every other log.

const STATE_OK := "ok"
const STATE_ODD := "odd"
const STATE_BAD := "bad"

var _data: Dictionary
var _rng := RandomNumberGenerator.new()
var _rules_by_part: Dictionary = {}
var _regexes: Dictionary = {} # rule id -> RegEx for the "pattern" rules
var _bag: Array[String] = []
var _count := 0
var _last_variant: Dictionary = {} # "key.hint" -> index of the last hint line used
var _first_names: Array = [] # names not drawn yet in this round (shuffled bags)
var _last_names: Array = []
var _story_done: Dictionary # story log id -> true. Shared with the caller, not copied.
var _story_seen: Dictionary = {} # story logs already shown in this shift


## `rng_seed` 0 gives a different shift every time; any other number repeats the same shift.
func _init(data: Dictionary, rng_seed: int = 0, story_done: Dictionary = {}) -> void:
	_data = data
	_story_done = story_done
	if rng_seed == 0:
		_rng.randomize()
	else:
		_rng.seed = rng_seed
	for rule: Dictionary in data.get("rules", []):
		_rules_by_part[rule["part"]] = rule
		if rule["check"] == "pattern":
			_regexes[rule["id"]] = RegEx.create_from_string(rule["pattern"])


## 24-hour clock like the Investigation's, from minutes after midnight (14 * 60 + 5 is "14:05").
static func format_clock(minutes: int) -> String:
	return "%02d:%02d" % [floori(minutes / 60.0) % 24, minutes % 60]


## How many logs at the start of the shift are guided (the clocks stay frozen for them).
func guided_count() -> int:
	return _data.get("guided_kinds", []).size()


## The chance, at one NEXT LOG, that a story log comes next, after `solved` logs solved.
func story_chance(solved: int) -> float:
	var odds: Dictionary = _data["story_odds"]
	return minf(float(odds["max"]), float(odds["base"]) + float(odds["per_solved"]) * solved)


## The next log. `solved` is the number of logs the player has solved so far in this shift.
func next_log(solved: int = 0) -> Dictionary:
	_count += 1
	var guided: Array = _data.get("guided_kinds", [])
	if _count <= guided.size():
		return _build(_plan(guided[_count - 1]))
	var story := _maybe_story(solved)
	return _build(_plan_story(story) if not story.is_empty() else _plan(_draw_kind()))


# --- Planning: what the sign-in is, before it is turned into parts. ---

## A story log, or an empty Dictionary. Never one that is done or has already been shown this shift.
func _maybe_story(solved: int) -> Dictionary:
	var open: Array = _data.get("story_logs", []).filter(func(entry: Dictionary) -> bool:
		return not _story_done.has(entry["id"]) and not _story_seen.has(entry["id"]))
	if open.is_empty() or _rng.randf() >= story_chance(solved):
		return {}
	var entry: Dictionary = open[_rng.randi() % open.size()]
	_story_seen[entry["id"]] = true
	return entry


## A log written out in the data: {id, kind, user, time "HH:MM", computer, where, result}, and for a
## decoy the "reason" it is fine.
func _plan_story(entry: Dictionary) -> Dictionary:
	var clock := str(entry["time"]).split(":")
	return {
		"kind": entry["kind"], "decoy": entry, "person": _story_person(entry["user"]), "story_id": entry["id"],
		"time": int(clock[0]) * 60 + int(clock[1]), "computer": entry["computer"],
		"where": entry["where"], "result": entry["result"],
	}


func _plan(kind: String) -> Dictionary:
	var plan := {
		"kind": kind, "decoy": {}, "person": {}, "time": 0,
		"computer": "", "where": "Office", "result": "Signed in",
	}
	match kind:
		"bad":
			_plan_bad(plan)
		"decoy":
			_plan_decoy(plan)
		_:
			plan["time"] = _safe_time()
	if plan["person"].is_empty(): # a decoy about the person on call has one already
		plan["person"] = _random_person()
	if str(plan["computer"]).is_empty():
		plan["computer"] = plan["person"]["computer"]
	return plan


func _plan_bad(plan: Dictionary) -> void:
	plan["time"] = _safe_time()
	var rules: Array = _data["rules"].duplicate()
	_shuffle(rules)
	# A stolen password is used from the thief's own computer, so most bad logs break the computer rule.
	if _rng.randf() < float(_data["threat"]["computer_rule_chance"]):
		var computer_rule: Dictionary = _rules_by_part["computer"]
		rules.erase(computer_rule)
		rules.push_front(computer_rule)
	var wanted := 2 if _rng.randf() < 0.4 else 1
	for rule: Dictionary in rules.slice(0, wanted):
		match rule["part"]:
			"time":
				plan["time"] = _unsafe_time(rule)
			"computer":
				plan["computer"] = _suspect_computer()
			"where":
				# A thief hides behind a VPN, so the country is different almost every time.
				var countries: Array = _data["outside_locations"]
				plan["where"] = countries[_rng.randi() % countries.size()]


func _plan_decoy(plan: Dictionary) -> void:
	var decoys: Array = _data["decoys"]
	var decoy: Dictionary = decoys[_rng.randi() % decoys.size()]
	plan["decoy"] = decoy
	plan["time"] = _safe_time()
	if decoy.get("user", "") == "@on_call":
		plan["person"] = _story_person(_data["on_call"])
	if decoy.has("time_range"):
		plan["time"] = _rng.randi_range(decoy["time_range"][0], decoy["time_range"][1])
	if decoy.has("result"):
		plan["result"] = decoy["result"]


## A made-up member of staff: a first name and a last name from their own bags, and a computer named
## after them. Story people (the victim, the person on call) are never made up, so their names are
## not in the pools.
func _random_person() -> Dictionary:
	var first := _draw_name(_first_names, _data["first_names"])
	var last := _draw_name(_last_names, _data["last_names"])
	var kind := "computer" if _rng.randf() < 0.7 else "laptop"
	return {"name": "%s %s" % [first, last], "computer": "%s's %s" % [first, kind]}


## The next name of a bag, which is refilled and reshuffled from `source` when it is empty.
func _draw_name(bag: Array, source: Array) -> String:
	if bag.is_empty():
		bag.append_array(source)
		_shuffle(bag)
	return bag.pop_back()


func _story_person(person_name: String) -> Dictionary:
	for person: Dictionary in _data["story_people"]:
		if person["name"] == person_name:
			return person
	push_error("LogGenerator: %s is not in story_people" % person_name)
	return _random_person()


## A time clearly inside the office hours, away from both edges.
func _safe_time() -> int:
	var rule: Dictionary = _rules_by_part["time"]
	var margin: int = rule.get("odd_margin", 0)
	return _rng.randi_range(int(rule["min"]) + margin, int(rule["max"]) - margin)


## A time clearly outside the office hours: at night, or well after closing.
func _unsafe_time(rule: Dictionary) -> int:
	var margin: int = rule.get("odd_margin", 0)
	var early_end: int = int(rule["min"]) - margin - 1
	var late_start: int = int(rule["max"]) + margin + 1
	if _rng.randf() < 0.5:
		return _rng.randi_range(0, early_end)
	return _rng.randi_range(late_start, 23 * 60 + 59)


## Most bad logs come from the same unknown computer (the suspect), so a pattern can be found.
func _suspect_computer() -> String:
	var threat: Dictionary = _data["threat"]
	if _rng.randf() < float(threat["chance"]):
		return threat["computer"]
	var others: Array = _data["unknown_computers"]
	return others[_rng.randi() % others.size()]


## One kind per log from a bag holding the shift's mix, refilled and reshuffled when empty.
func _draw_kind() -> String:
	if _bag.is_empty():
		var mix: Dictionary = _data["mix"]
		for kind: String in mix:
			for _i in int(mix[kind]):
				_bag.append(kind)
		_shuffle(_bag)
	return _bag.pop_back()


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap


# --- Building: parts, hints and the truth, all from the rules. ---

func _build(plan: Dictionary) -> Dictionary:
	var event: Dictionary = _data["events"]["sign_in"]
	var person: Dictionary = plan["person"]
	var values := {
		"user": person["name"], "time": format_clock(int(plan["time"])),
		"computer": plan["computer"], "where": plan["where"], "result": plan["result"],
	}
	var parts: Array = []
	var violations: Array = []
	for spec: Dictionary in event["parts"]:
		var key: String = spec["key"]
		var verdict := _evaluate(key, values, int(plan["time"]))
		if verdict["state"] == STATE_BAD:
			violations.append(verdict["rule"])
		parts.append({
			"key": key, "label": spec["label"], "value": values[key], "state": verdict["state"],
			"hint": _hint(key, verdict["hint"], values), "entity": spec.get("entity", ""),
		})
	var truth := {
		"kind": plan["kind"], "suspicious": not violations.is_empty(),
		"violations": violations, "reason": _reason(plan, violations, values),
	}
	return {
		"id": "log_%03d" % _count, "number": _count, "title": event["title"],
		"parts": parts, "truth": truth, "story_id": plan.get("story_id", ""),
	}


## State of one part by its rule. Returns {state, hint, rule}; "hint" names the line group to use.
func _evaluate(key: String, values: Dictionary, minutes: int) -> Dictionary:
	var rule: Dictionary = _rules_by_part.get(key, {})
	if rule.is_empty():
		var odd: bool = key == "result" and values["result"] != "Signed in"
		return {"state": STATE_ODD if odd else STATE_OK, "hint": STATE_ODD if odd else STATE_OK, "rule": ""}
	if rule["check"] == "range":
		return _check_range(rule, values, minutes)
	var allowed := false
	if rule["check"] == "pattern": # a name that fits the pattern, or one of the extra allowed names
		allowed = values[key] in rule.get("allowed_extra", []) or _regexes[rule["id"]].search(values[key]) != null
	else:
		allowed = values[key] in rule["allowed"]
	var state := STATE_OK if allowed else STATE_BAD
	return {"state": state, "hint": state, "rule": rule["id"]}


func _check_range(rule: Dictionary, values: Dictionary, minutes: int) -> Dictionary:
	var low: int = rule["min"]
	var high: int = rule["max"]
	if minutes < low or minutes > high:
		if rule.get("exception", "") == "on_call" and values["user"] == _data["on_call"]:
			return {"state": STATE_ODD, "hint": "oncall", "rule": rule["id"]}
		return {"state": STATE_BAD, "hint": STATE_BAD, "rule": rule["id"]}
	var margin: int = rule.get("odd_margin", 0)
	if minutes - low < margin or high - minutes < margin:
		return {"state": STATE_ODD, "hint": STATE_ODD, "rule": rule["id"]}
	return {"state": STATE_OK, "hint": STATE_OK, "rule": rule["id"]}


## One of the 2 or 3 lines for this part and state, never the one used last time.
func _hint(key: String, group: String, values: Dictionary) -> String:
	var table: Dictionary = _data["hints"].get(key, {})
	var lines: Array = table.get(group, table.get(STATE_OK, []))
	if lines.is_empty():
		return ""
	var tag := "%s.%s" % [key, group]
	var index := _rng.randi() % lines.size()
	if lines.size() > 1 and index == _last_variant.get(tag, -1):
		index = (index + 1) % lines.size()
	_last_variant[tag] = index
	return _fill(lines[index], values)


func _reason(plan: Dictionary, violations: Array, values: Dictionary) -> String:
	if not violations.is_empty():
		var phrases: Array[String] = []
		for rule: Dictionary in _data["rules"]:
			if rule["id"] in violations:
				phrases.append(rule["broken"])
		var joined := phrases[0] if phrases.size() == 1 else "%s and %s" % [", ".join(phrases.slice(0, -1)), phrases[-1]]
		return "This sign-in %s." % joined
	if plan["kind"] == "decoy":
		return _fill(plan["decoy"]["reason"], values)
	return _data["messages"]["normal_reason"]


func _fill(text: String, values: Dictionary) -> String:
	var person_name: String = values["user"]
	return text.replace("{user}", person_name).replace("{first}", person_name.get_slice(" ", 0)) \
			.replace("{time}", values["time"]).replace("{computer}", values["computer"]) \
			.replace("{where}", values["where"]).replace("{result}", values["result"])
