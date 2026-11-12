extends SceneTree

## Checks the content of every day in data/days.json against the rules the game relies on, without playing it.
## Run: godot --headless --path . --script tests/content/validate_days.gd
## Exits 1 when a check fails. Classes are looked up by path, so the script compiles before the autoloads exist.

const VERDICT_WORDS := ["suspicious", "normal", "allowed", "rule", "report", "bad"]

var fails := 0
var checks := 0


func ok(cond: bool, label: String) -> void:
	checks += 1
	if not cond:
		fails += 1
		print("FAIL ", label)


func read(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _init() -> void:
	var days := read("res://data/days.json")
	var upgrades := read("res://data/upgrades.json")
	ok(not days.is_empty() and not upgrades.is_empty(), "days.json and upgrades.json load")
	var recovery_ids: Array = load("res://scripts/gameplay/recovery/recovery_data.gd").COMPONENT_IDS
	var recovery_scenes: Dictionary = load("res://scripts/gameplay/recovery/recovery_data.gd").COMPONENTS
	_check_cards(read("res://data/cards.json"), read("res://data/shop_dialogue.json"))
	for day: String in days:
		_check_day(day, days[day], upgrades, recovery_ids, recovery_scenes)
	_check_music(read("res://data/music.json"))
	_check_assessment(read("res://data/assessment.json"))
	_check_feedback(read("res://data/feedback.json"))
	print("checks: %d   fails: %d" % [checks, fails])
	quit(1 if fails > 0 else 0)


## The assessment: ids are unique and q01, q02..., every question has a scenario, four different options and an answer in range.
func _check_assessment(data: Dictionary) -> void:
	var questions: Array = data.get("questions", [])
	ok(questions.size() >= 10, "assessment has questions")
	var seen := {}
	for i in questions.size():
		var q: Dictionary = questions[i]
		var id := str(q.get("id", ""))
		ok(id == "q%02d" % (i + 1), "assessment question %d has the id q%02d (%s)" % [i + 1, i + 1, id])
		ok(not seen.has(id), "assessment id %s is not used twice" % id)
		seen[id] = true
		ok(str(q.get("scenario", "")).length() > 20, "assessment %s has a scenario" % id)
		var options: Array = q.get("options", [])
		ok(options.size() == 4, "assessment %s has 4 options" % id)
		var unique := {}
		for option in options:
			unique[str(option)] = true
		ok(unique.size() == options.size(), "assessment %s has different options" % id)
		ok(int(q.get("answer", -1)) >= 0 and int(q.get("answer", -1)) < options.size(), "assessment %s has an answer in range" % id)


## The feedback form: a scale of 5 labels, ids f01, f02... without gaps, a characteristic and a text for each item.
func _check_feedback(data: Dictionary) -> void:
	ok(data.get("scale", []).size() == 5, "feedback has a scale of 5 labels")
	var items: Array = data.get("items", [])
	ok(items.size() >= 8, "feedback has items")
	for i in items.size():
		var item: Dictionary = items[i]
		ok(str(item.get("id", "")) == "f%02d" % (i + 1), "feedback item %d has the id f%02d" % [i + 1, i + 1])
		ok(not str(item.get("characteristic", "")).is_empty() and str(item.get("text", "")).length() > 10, "feedback f%02d has a characteristic and a text" % (i + 1))


## Every track of data/music.json exists, a track in stages has one threshold fewer than files, and the scenes it
## names exist and play a known track.
func _check_music(music: Dictionary) -> void:
	var tracks: Dictionary = music.get("tracks", {})
	ok(not tracks.is_empty(), "music.json has tracks")
	for key: String in tracks:
		var files: Array = tracks[key].get("files", [])
		ok(not files.is_empty(), "music %s has files" % key)
		for file: String in files:
			ok(FileAccess.file_exists("res://assets/audio/music/" + file), "music %s: %s exists" % [key, file])
		if files.size() > 1:
			ok(tracks[key].get("thresholds", []).size() == files.size() - 1, "music %s has a threshold per stage" % key)
	var scenes: Dictionary = music.get("scenes", {})
	for path: String in scenes:
		ok(FileAccess.file_exists(path), "music scene %s exists" % path)
		ok(tracks.has(scenes[path]), "music scene %s plays a known track" % path)
	for key in ["stage_select", "archive", "hope", "defeat", "response_doom"]: # the tracks scripts ask for by name
		ok(tracks.has(key), "music has the track %s that a script plays" % key)


## Every card has its art, a known type and effects, a price in the shop, and a line from Carla; the shop
## lists no card twice, and every day has at most 10 new cards.
func _check_cards(data: Dictionary, shop_lines: Dictionary) -> void:
	var cards: Dictionary = data.get("cards", {})
	var shop: Array = data.get("shop", [])
	var per_day := {}
	for id: String in cards:
		var card: Dictionary = cards[id]
		var tag := "Card %s: " % id
		ok(FileAccess.file_exists("res://assets/cards/art/art_%s.png" % id), tag + "has art")
		ok(["offensive", "defensive", "utility"].has(str(card.get("type", ""))), tag + "has a known type")
		ok(int(card.get("cost", -1)) >= 0 and int(card.get("cost", 9)) <= 4, tag + "costs 0 to 4")
		var effects: Dictionary = card.get("effects", {})
		ok(not effects.is_empty(), tag + "has effects")
		for key: String in effects:
			ok(["damage", "block", "draw", "heal", "energy", "dodge", "expose", "charge", "cap", "reflect", "exploit"].has(key), tag + "effect %s is known" % key)
		ok(not str(card.get("text", "")).is_empty() and str(card.get("text", "")).length() <= 30, tag + "has a short text")
		if int(card.get("day", 1)) > 1 or shop.has(id): # Day 1's "contain" is in neither the starter deck nor the shop (it is unused)
			ok(shop.has(id) and int(card.get("price", 0)) > 0, tag + "is in the shop with a price")
			ok(shop_lines.get("cards", {}).has(id), tag + "has a line from Carla")
		var type: String = str(card.get("type", ""))
		var main: String = {"offensive": "damage", "defensive": "block"}.get(type, "")
		ok(main.is_empty() or effects.has(main), tag + "its main effect fits its type")
		per_day[int(card.get("day", 1))] = int(per_day.get(int(card.get("day", 1)), 0)) + 1
	for id: String in shop:
		ok(cards.has(id) and shop.count(id) == 1, "Shop card %s exists once" % id)
	for day: int in per_day:
		if day > 1:
			ok(per_day[day] == 10, "Day %d adds 10 cards (%d)" % [day, per_day[day]])
	for id: String in data.get("starter_deck", []):
		ok(cards.has(id), "Starter card %s exists" % id)


func _check_day(day: String, info: Dictionary, upgrades: Dictionary, recovery_ids: Array, recovery_scenes: Dictionary) -> void:
	var tag := "Day %s: " % day
	var phases: Dictionary = info["phases"]
	for phase: String in ["investigation", "monitoring", "hardening", "response", "recovery"]:
		ok(phases.has(phase), tag + "has the phase " + phase)
		var entry: Dictionary = phases.get(phase, {})
		# every phase tells the player what to do (the OBJECTIVE of its top bar): short enough for the bar
		var objective := str(entry.get("objective", ""))
		var longest := 29 if phase == "hardening" else 80 # the Hardening bar leaves room for 41 letters with "OBJECTIVE - "
		ok(not objective.is_empty() and objective.length() <= longest, tag + "%s has an objective of at most %d letters" % [phase, longest])
		for key: String in ["dialogue", "scene", "data"]:
			if entry.has(key):
				ok(FileAccess.file_exists(str(entry[key])), tag + "%s %s exists" % [phase, key])
		if entry.has("dialogue"):
			_check_dialogue(tag + phase + " dialogue: ", read(str(entry["dialogue"])))
	if info.has("ending"): # the last day closes with a short scene
		ok(FileAccess.file_exists(str(info["ending"])), tag + "the ending exists")
		_check_dialogue(tag + "ending: ", read(str(info["ending"])))
	var investigation := read(str(phases["investigation"].get("data", "")))
	var monitoring := read(str(phases["monitoring"].get("data", "")))
	var response := read(str(phases["response"].get("data", "res://AI generated/data/response_day1.json")))
	var recovery := read(str(phases["recovery"].get("data", "")))
	for part: Array in [["investigation", investigation], ["monitoring", monitoring], ["response", response], ["recovery", recovery]]:
		_check_24_hour(tag + str(part[0]) + " data ", part[1])
	var entries := _entries(investigation)
	_check_investigation(tag, investigation, entries)
	_check_upgrades(tag, int(day), upgrades, entries, response)
	_check_response_and_recovery(tag, response, recovery, upgrades, recovery_ids, recovery_scenes)
	_check_monitoring(tag, monitoring)


## Every entry of every app, by id.
func _entries(investigation: Dictionary) -> Dictionary:
	var all := {}
	for app: Dictionary in investigation.get("investigation", {}).values():
		for entry: Dictionary in app.get("entries", []):
			all[str(entry["id"])] = entry
	return all


## Times are 24-hour in the whole game: no "2 AM" or "3:40 PM" in any text of the day's data.
func _check_24_hour(tag: String, data: Variant) -> void:
	var regex := RegEx.create_from_string("\\b\\d{1,2}(:\\d{2})? ?(AM|PM|am|pm)\\b")
	var found := _strings(data).filter(func(text: String) -> bool: return regex.search(text) != null)
	ok(found.is_empty(), tag + "has no AM or PM (%s)" % (str(found[0]).left(50) if not found.is_empty() else ""))


func _strings(data: Variant) -> Array:
	var out: Array = []
	if data is String:
		out.append(data)
	elif data is Dictionary:
		for value: Variant in data.values():
			out.append_array(_strings(value))
	elif data is Array:
		for value: Variant in data:
			out.append_array(_strings(value))
	return out


func _check_dialogue(tag: String, scene: Dictionary) -> void:
	_check_24_hour(tag, scene)
	ok(scene.has("start"), tag + "has a start")
	var ends := false
	for id: String in scene:
		var block: Dictionary = scene[id]
		if block.has("trigger"):
			ends = true
		if block.has("next"):
			ok(scene.has(str(block["next"])), tag + "%s -> %s exists" % [id, block["next"]])
		for target: Variant in block.get("choices", {}).values():
			ok(scene.has(str(target)), tag + "%s choice -> %s exists" % [id, target])
		if not block.has("trigger"):
			ok(block.has("next") or block.has("choices"), tag + id + " leads somewhere")
			ok(not str(block.get("text", "")).is_empty(), tag + id + " has text")
	ok(ends, tag + "ends with a trigger")


func _check_investigation(tag: String, investigation: Dictionary, entries: Dictionary) -> void:
	ok(not entries.is_empty(), tag + "has entries")
	var clues := 0
	var by_entity := {}
	for id: String in entries:
		var entry: Dictionary = entries[id]
		clues += 1 if entry.get("is_clue", false) else 0
		for key: String in ["cells", "title", "detail", "entities", "monologue", "summary"]:
			ok(entry.has(key), tag + id + " has " + key)
		for entity: String in entry.get("entities", []):
			by_entity[entity] = by_entity.get(entity, 0) + 1
	ok(clues == int(investigation.get("clues_required", -1)), tag + "has exactly the clues it requires (%d)" % clues)
	# A clue must be linkable: another entry (any app) shares at least one of its entities.
	for id: String in entries:
		if entries[id].get("is_clue", false):
			var linked := false
			for entity: String in entries[id].get("entities", []):
				linked = linked or by_entity[entity] > 1
			ok(linked, tag + "clue " + id + " shares an entity with another entry")
	# The report: every blank has an answer chip, every chip is unique, wrong chips explain themselves.
	var report: Dictionary = investigation.get("report", {})
	var chips := {}
	for chip: Dictionary in report.get("chips", []):
		ok(not chips.has(chip["id"]), tag + "chip " + str(chip["id"]) + " is unique")
		chips[chip["id"]] = chip
	var answers: Dictionary = report.get("answers", {})
	var text := str(report.get("text", ""))
	var right_ids: Array = []
	for slot: String in answers:
		ok(text.contains("{%s}" % slot), tag + "the report text has the blank {%s}" % slot)
		var wanted: Array = answers[slot] if answers[slot] is Array else [answers[slot]]
		for chip_id: String in wanted:
			ok(chips.has(chip_id), tag + "the answer %s of blank %s exists" % [chip_id, slot])
			right_ids.append(chip_id)
	for id: String in chips:
		if not right_ids.has(id):
			ok(not str(chips[id].get("reason", "")).is_empty(), tag + "the wrong chip " + id + " has a reason")
	# An entry that waits for another one (a reply to a question) waits for one that exists, in the same app.
	for id: String in entries:
		var waits_for := str(entries[id].get("after", ""))
		if not waits_for.is_empty():
			ok(entries.has(waits_for), tag + "entry " + id + " waits for an entry that exists")
	# The tabs it renames are the ones the scene has.
	for app: String in investigation.get("tabs", {}):
		ok(["email", "logs", "computers", "login", "files", "network", "servers"].has(app), tag + "tab " + app + " exists")
	# Echo entries: both versions of the day give the same number of entries.
	var sizes := {}
	for worn: Array in [[], ["twostep", "alerts", "unique", "lockout", "allowlist", "updates", "antivirus", "attachments", "filter", "folders", "offline", "encrypt"]]:
		var count := 0
		for app: Dictionary in investigation.get("investigation", {}).values():
			for entry: Dictionary in app.get("entries", []):
				var needs: Array = entry.get("if_equipped", [])
				var without: Array = entry.get("unless_equipped", [])
				if needs.all(func(u: String) -> bool: return worn.has(u)) and not without.any(func(u: String) -> bool: return worn.has(u)):
					count += 1
		sizes[str(worn.size())] = count
	ok(sizes.values()[0] == sizes.values()[1], tag + "the echoes keep the entry count (%s)" % str(sizes))


func _check_upgrades(tag: String, day: int, upgrades: Dictionary, entries: Dictionary, response: Dictionary) -> void:
	var by_id: Dictionary = upgrades.get("upgrades", {})
	var own := 0
	for id: String in by_id:
		var upgrade: Dictionary = by_id[id]
		if int(upgrade.get("day", 1)) != day:
			continue
		own += 1
		ok(upgrade.has("passive") and not str(upgrade.get("against", "")).is_empty(), tag + id + " has a passive and a counter")
		ok(str(upgrade.get("text", "")).contains("ALWAYS") and str(upgrade.get("text", "")).contains("AGAINST"), tag + id + " text has both lines")
		for clue: String in upgrade.get("clues", []):
			ok(entries.has(clue) and entries[clue].get("is_clue", false), tag + id + " recommends from a real clue " + clue)
	ok(own == 4, tag + "has its own four upgrades (%d)" % own)
	for pattern: Dictionary in response.get("patterns", []):
		var counter := str(pattern.get("counter", ""))
		ok(by_id.has(counter), tag + "the counter " + counter + " of " + str(pattern["id"]) + " is an upgrade")
		ok(int(by_id.get(counter, {}).get("day", 0)) == day, tag + "the counter of " + str(pattern["id"]) + " belongs to this day")
		var defense_known := false
		for defense: Dictionary in response.get("defenses", []):
			defense_known = defense_known or str(defense["id"]) == counter
		ok(defense_known, tag + "the counter of " + str(pattern["id"]) + " has a defense text")
		ok(pattern.has("harsh"), tag + str(pattern["id"]) + " has a harder version")
	# The upgrade the threat cannot be beaten without: one of the day's own, with the words the fight and the loss need.
	var doom: Dictionary = response.get("doom", {})
	ok(not doom.is_empty(), tag + "has a doom (the upgrade the threat cannot be beaten without)")
	ok(by_id.has(str(doom.get("counter", ""))) and int(by_id.get(str(doom.get("counter", "")), {}).get("day", 0)) == day, tag + "the doom upgrade is one of the day's upgrades")
	for key: String in ["name", "warn", "strike", "lost"]:
		ok(not str(doom.get(key, "")).is_empty(), tag + "the doom has a " + key)
	ok(float(doom.get("percent", 0)) >= 25.0, tag + "a hit of the doom takes at least a quarter of the HP")


func _check_response_and_recovery(tag: String, response: Dictionary, recovery: Dictionary, upgrades: Dictionary, recovery_ids: Array, recovery_scenes: Dictionary) -> void:
	var attacks: Array = recovery.get("attacks", [])
	var components: Dictionary = recovery.get("components", {})
	for pattern: Dictionary in response.get("patterns", []):
		var found := false
		for attack: Dictionary in attacks:
			found = found or str(attack["id"]) == str(pattern["id"])
		ok(found, tag + "pattern " + str(pattern["id"]) + " has a repair in the work order")
	var registry := load("res://scripts/gameplay/recovery/recovery_data.gd")
	for attack: Dictionary in attacks:
		for component: String in registry.components_of(attack):
			ok(recovery_ids.has(component) and recovery_scenes.has(component), tag + "repair " + component + " is a registered task")
			ok(components.has(component) and not str(components[component].get("instruction", "")).is_empty(), tag + "repair " + component + " has content")
			ok(recovery.get("equipment_selection", {}).has(component), tag + "repair " + component + " has a place in the office")
	ok(components.has("file_server"), tag + "has the final check content")
	for scene_path: String in recovery_scenes.values():
		ok(FileAccess.file_exists(scene_path), tag + "task scene " + scene_path.get_file() + " exists")
	var checks_list: Array = components.get("file_server", {}).get("checks", [])
	for check: Dictionary in checks_list:
		ok(recovery.get("response_outcome", {}).get("verification", {}).has(str(check["id"])), tag + "final check " + str(check["id"]) + " is in the outcome")


func _check_monitoring(tag: String, monitoring: Dictionary) -> void:
	ok(not monitoring.is_empty(), tag + "has a Monitoring shift")
	if monitoring.is_empty():
		return
	for part: String in monitoring.get("hints", {}):
		for group: String in monitoring["hints"][part]:
			for line: String in monitoring["hints"][part][group]:
				var lower := line.to_lower()
				for word: String in VERDICT_WORDS:
					ok(not _has_word(lower, word), tag + "hint '%s' avoids the word '%s'" % [line, word])
	# The shift is generated: no log may call a rule break normal or the other way round.
	var generator := load("res://scripts/gameplay/monitoring/log_generator.gd")
	var gen: RefCounted = generator.new(monitoring, 11)
	var mismatches := 0
	var kinds := {}
	for i in 300:
		var log: Dictionary = gen.next_log(i % 10)
		var truth: Dictionary = log["truth"]
		kinds[truth["kind"]] = int(kinds.get(truth["kind"], 0)) + 1
		if (truth["kind"] == "bad") != truth["suspicious"]:
			mismatches += 1
	ok(mismatches == 0, tag + "generated logs agree with their kind (%d wrong)" % mismatches)
	ok(kinds.has("normal") and kinds.has("bad") and kinds.has("decoy"), tag + "the shift has all three kinds " + str(kinds))


func _has_word(text: String, word: String) -> bool:
	var regex := RegEx.create_from_string("(^|[^a-z])" + word + "([^a-z]|$)")
	return regex.search(text) != null
