extends Node

## Autoload (Assessment): the pre-game and the post-game assessment of the study.
##
## The same scenario questions (data/assessment.json) are asked before the first day (the pre-test, which also asks
## for an alias) and again after the last day (the post-test). The scene is scenes/menus/Assessment.tscn. This autoload
## keeps the answers in the save slot (SaveManager.data["assessment"]), writes a copy of each result to a file in
## user://assessment/, and sends it to a Google Sheet through an Apps Script web app (see docs/assessment_setup.md).
##
## A result that could not be sent (no connection, or the sheet's address is not set yet) stays in the slot's "outbox"
## and is sent again later: flush() is called when the day select opens and every `retry_seconds` while something is
## waiting. The Apps Script ignores a result it already has (same session id), so a repeat is harmless.
##
## The game does not wait for the sending: the assessment is complete when the answers are saved in the slot.
##
## A test is answered once per person, not once per save slot. This computer remembers who answered what in a small file
## outside the save slots (user://study_profiles.dat, one profile per alias, with the pre-test, the post-test and the
## feedback form that alias has done). A new save slot asks "who is playing?": the player picks their alias and the slot
## takes over what was done (nothing is asked or sent again), or says they are someone new and takes the pre-test.
## Several people can share one computer, and an alias can be used by only one of them there.

signal status_changed

const QUESTIONS_PATH := "res://data/assessment.json"
const FEEDBACK_PATH := "res://data/feedback.json"
const CONFIG_PATH := "res://data/assessment_config.json"
const SCENE_PATH := "res://scenes/menus/Assessment.tscn"
const BACKUP_DIR := "user://assessment"
const ALIAS_MIN := 2
const ALIAS_MAX := 24
const COMMENT_MAX := 300
const PROFILES_PATH := "user://study_profiles.dat"
const PROFILES_KEY := "NetWars/study/v1/9d41c7e2b0a35f68"
const PROFILES_SHOWN := 6 # the most recent aliases offered to a new slot

enum Phase { PRE, POST }
## What the last attempt to send said: "" nothing sent yet, "sending", "sent", "waiting" (no connection or the sheet said
## no), "off" (no address set: the results stay on this computer).
var status := ""
## Why the last sending failed, when the script said (its "error": "key" is a key that is not the one of the script), or what went
## wrong on the way ("connection", "answer"). Empty when nothing failed.
var last_error := ""

var title := "SECURITY CHECK"
var questions: Array = []
## The feedback form: the title, the labels of the 1 to 5 scale, the prompt of the comment and the items [{"id", "characteristic", "text"}].
var feedback_title := "FEEDBACK"
var scale: Array = []
var comment_prompt := ""
var feedback_items: Array = []
var _config: Dictionary = {}
var _http: HTTPRequest
var _retry: Timer
var _sending_slot := -1
var _sending_session := ""
var _redirects := 0
var _endpoint := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_http = HTTPRequest.new()
	_http.timeout = float(_config.get("timeout_seconds", 15))
	_http.max_redirects = 0 # Apps Script answers a POST with a redirect to its answer: it is followed by hand, as a GET
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	_retry = Timer.new()
	_retry.one_shot = true
	_retry.timeout.connect(flush)
	add_child(_retry)


func _load() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(QUESTIONS_PATH))
	if parsed is Dictionary:
		title = str(parsed.get("title", title))
		questions = parsed.get("questions", [])
	var form: Variant = JSON.parse_string(FileAccess.get_file_as_string(FEEDBACK_PATH))
	if form is Dictionary:
		feedback_title = str(form.get("title", feedback_title))
		scale = form.get("scale", [])
		comment_prompt = str(form.get("comment_prompt", ""))
		feedback_items = form.get("items", [])
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	_config = config if config is Dictionary else {}


# --- where the player is in the study ---

## The assessment part of the slot being played ({} with no slot).
func record() -> Dictionary:
	if SaveManager.current_slot < 0:
		return {}
	return SaveManager.data["assessment"]


## The pre-test has not been taken in this slot: it comes before everything else.
func needs_pre() -> bool:
	return SaveManager.current_slot >= 0 and record().get("pre", {}).is_empty()


## The pre-test is done and the post-test is not: it is offered at the end of the last day, and from the day select.
func needs_post() -> bool:
	return SaveManager.current_slot >= 0 and not record().get("pre", {}).is_empty() and record().get("post", {}).is_empty()


## The post-test is done and the feedback form is not: it comes right after the post-test.
func needs_feedback() -> bool:
	return SaveManager.current_slot >= 0 and not record().get("post", {}).is_empty() and record().get("feedback", {}).is_empty()


## True while something of the study is still to be done in this slot (the post-test or the feedback form).
func needs_more() -> bool:
	return needs_post() or needs_feedback()


func alias() -> String:
	return str(record().get("alias", ""))


## Opens the assessment the slot is due for, if any. Returns true when it did (the caller stops there).
## `post_too` also opens the post-test (at the end of the last day), not only the pre-test.
func open_if_due(post_too: bool = false) -> bool:
	sync_with_computer()
	if needs_pre():
		SceneManager.load_scene(SCENE_PATH)
		return true
	if post_too and needs_more():
		SceneManager.load_scene(SCENE_PATH)
		return true
	return false


## "pre", "post" or "feedback": the one the scene asks now.
func current_phase() -> String:
	if needs_pre():
		return "pre"
	return "post" if needs_post() else "feedback"


# --- who has done what on this computer ---

## {alias in lower case: {"alias", "pre", "post", "feedback"}}; each test is the short summary of its result
## ({"session", "phase", "score", "total", "time"}), or missing when it is not done.
func profiles() -> Dictionary:
	var file := FileAccess.open_encrypted_with_pass(PROFILES_PATH, FileAccess.READ, PROFILES_KEY)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _save_profiles(all: Dictionary) -> void:
	var file := FileAccess.open_encrypted_with_pass(PROFILES_PATH, FileAccess.WRITE, PROFILES_KEY)
	if file != null:
		file.store_string(JSON.stringify(all))


## The aliases of this computer, the most recent first (at most PROFILES_SHOWN).
func profile_list() -> Array:
	var list: Array = profiles().values()
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a.get("seen", "")) > str(b.get("seen", "")))
	return list.slice(0, PROFILES_SHOWN)


## True when somebody on this computer already uses the alias (capitals do not matter).
func alias_taken(text: String) -> bool:
	return profiles().has(clean_alias(text).to_lower())


## The slot takes over what the alias has done on this computer (the answers are not asked and not sent again).
func adopt(chosen_alias: String) -> void:
	var profile: Dictionary = profiles().get(chosen_alias.to_lower(), {})
	if profile.is_empty() or SaveManager.current_slot < 0:
		return
	var slot_record: Dictionary = SaveManager.data["assessment"]
	slot_record["alias"] = str(profile["alias"])
	_import_missing(slot_record, profile)
	SaveManager.save()


func _import_missing(slot_record: Dictionary, profile: Dictionary) -> void:
	for phase in ["pre", "post", "feedback"]:
		if slot_record[phase].is_empty() and profile.has(phase):
			var summary: Dictionary = (profile[phase] as Dictionary).duplicate(true)
			summary["imported"] = true
			slot_record[phase] = summary


## The slot and this computer agree: what the slot did is remembered here (a slot from before the profiles existed),
## and what the alias did in another slot is taken over (a slot that was left at the pre-test).
func sync_with_computer() -> void:
	if SaveManager.current_slot < 0:
		return
	var slot_record: Dictionary = SaveManager.data["assessment"]
	var chosen := str(slot_record.get("alias", ""))
	if chosen.is_empty():
		return
	var all := profiles()
	var profile: Dictionary = all.get(chosen.to_lower(), {"alias": chosen})
	var changed_computer := not all.has(chosen.to_lower())
	for phase in ["pre", "post", "feedback"]:
		if not slot_record[phase].is_empty() and not profile.has(phase) and not slot_record[phase].get("imported", false):
			profile[phase] = _summary(slot_record[phase])
			changed_computer = true
	if changed_computer:
		profile["seen"] = Time.get_datetime_string_from_system(true)
		all[chosen.to_lower()] = profile
		_save_profiles(all)
	var before := str(slot_record)
	_import_missing(slot_record, profile)
	if str(slot_record) != before:
		SaveManager.save()


func _remember(result: Dictionary) -> void:
	var all := profiles()
	var key := str(result["alias"]).to_lower()
	var profile: Dictionary = all.get(key, {"alias": str(result["alias"])})
	profile[str(result["phase"])] = _summary(result)
	profile["seen"] = Time.get_datetime_string_from_system(true)
	all[key] = profile
	_save_profiles(all)


static func _summary(result: Dictionary) -> Dictionary:
	var summary := {"session": str(result.get("session", "")), "phase": str(result.get("phase", "")), "time": str(result.get("time", ""))}
	if result.has("score"):
		summary["score"] = int(result["score"])
		summary["total"] = int(result["total"])
	return summary


## Forgets everyone of this computer (a new group of participants; the debug panel has a button for it).
func forget_everyone() -> void:
	if FileAccess.file_exists(PROFILES_PATH):
		DirAccess.remove_absolute(PROFILES_PATH)


# --- the alias ---

## An alias is 2 to 24 letters, digits, spaces, dots, dashes or underscores.
func clean_alias(text: String) -> String:
	var out := ""
	for letter in text.strip_edges():
		var ok := (letter >= "a" and letter <= "z") or (letter >= "A" and letter <= "Z") or (letter >= "0" and letter <= "9") or letter in " ._-"
		if ok:
			out += letter
	return out.left(ALIAS_MAX).strip_edges()


func alias_ok(text: String) -> bool:
	var cleaned := clean_alias(text)
	return cleaned.length() >= ALIAS_MIN and cleaned == text.strip_edges()


# --- a run of the questions ---

## The questions in a new random order, each with its options in a new random order:
## [{"id", "scenario", "options": [{"text", "index"}]}] (index is the place of the option in the data file).
func new_run() -> Array[Dictionary]:
	var order := questions.duplicate()
	order.shuffle()
	var run: Array[Dictionary] = []
	for question: Dictionary in order:
		var options: Array = []
		for i in question["options"].size():
			options.append({"text": str(question["options"][i]), "index": i})
		options.shuffle()
		run.append({"id": str(question["id"]), "scenario": str(question["scenario"]), "options": options})
	return run


func is_correct(question_id: String, option_index: int) -> bool:
	for question: Dictionary in questions:
		if str(question["id"]) == question_id:
			return int(question["answer"]) == option_index
	return false


## Keeps the answers of the run: in the slot, in a file, and in the outbox to be sent.
## answers: [{"q": id, "choice": index in the data file, "ms": milliseconds spent}], in the order they were asked.
## Returns the saved result.
func submit(phase: String, chosen_alias: String, answers: Array) -> Dictionary:
	var graded: Array = []
	var score := 0
	var total_ms := 0
	for answer: Dictionary in answers:
		var right := is_correct(str(answer["q"]), int(answer["choice"]))
		score += 1 if right else 0
		total_ms += int(answer.get("ms", 0))
		graded.append({"q": str(answer["q"]), "choice": int(answer["choice"]), "correct": right, "ms": int(answer.get("ms", 0))})
	var done: Dictionary = SaveManager.data["completed"]
	var phases_done := 0
	var day_reached := 0
	for day: String in done:
		phases_done += done[day].size()
		if not done[day].is_empty():
			day_reached = maxi(day_reached, int(day))
	var result := {
		"session": "%08x%08x" % [randi(), randi()],
		"phase": phase,
		"alias": chosen_alias,
		"score": score,
		"total": questions.size(),
		"answers": graded,
		"total_ms": total_ms,
		"day_reached": day_reached,
		"phases_done": phases_done,
		"version": str(ProjectSettings.get_setting("application/config/version", "dev")),
		"time": Time.get_datetime_string_from_system(true),
	}
	var slot_record: Dictionary = SaveManager.data["assessment"]
	slot_record["alias"] = chosen_alias
	slot_record[phase] = result
	slot_record["outbox"].append(result)
	SaveManager.save()
	_remember(result)
	_write_backup(result)
	status = ""
	flush()
	return result


## Keeps the feedback form: ratings [{"q": id, "value": 1 to 5}] and a comment (can be empty). Same way as submit().
func submit_feedback(ratings: Array, comment: String) -> Dictionary:
	var clean: Array = []
	for rating: Dictionary in ratings:
		clean.append({"q": str(rating["q"]), "value": clampi(int(rating["value"]), 1, 5)})
	var result := {
		"session": "%08x%08x" % [randi(), randi()],
		"phase": "feedback",
		"alias": alias(),
		"ratings": clean,
		"comment": comment.strip_edges().left(COMMENT_MAX),
		"version": str(ProjectSettings.get_setting("application/config/version", "dev")),
		"time": Time.get_datetime_string_from_system(true),
	}
	var slot_record: Dictionary = SaveManager.data["assessment"]
	slot_record["feedback"] = result
	slot_record["outbox"].append(result)
	SaveManager.save()
	_remember(result)
	_write_backup(result)
	status = ""
	flush()
	return result


func _write_backup(result: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(BACKUP_DIR)
	var file := FileAccess.open("%s/%s_%s_%s.json" % [BACKUP_DIR, str(result["alias"]).replace(" ", "_"), result["phase"], result["session"]], FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))


# --- sending ---

## Sends the first result of the outbox. When it is sent, the next one goes. Does nothing while a send is going on, when
## the slot has nothing waiting, or when no address is set.
func flush() -> void:
	if _http == null or SaveManager.current_slot < 0:
		return
	var outbox: Array = SaveManager.data["assessment"]["outbox"]
	if outbox.is_empty() or _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var endpoint := str(_config.get("endpoint", "")).strip_edges()
	if endpoint.is_empty():
		_set_status("off")
		return
	var payload: Dictionary = (outbox[0] as Dictionary).duplicate()
	_endpoint = endpoint
	_redirects = 0
	_sending_slot = SaveManager.current_slot
	_sending_session = str(payload["session"])
	payload["key"] = str(_config.get("key", ""))
	_set_status("sending")
	# text/plain: the Apps Script web app reads the body as it comes, and no preflight is asked for.
	var error := _http.request(endpoint, ["Content-Type: text/plain;charset=utf-8"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_failed()


func _on_request_completed(result: int, code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if (result == HTTPRequest.RESULT_SUCCESS or result == HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED) and code in [301, 302, 303, 307, 308] and _redirects < 3:
		# The script has the result by now; the redirect leads to its answer, which is a GET.
		var location := _location_of(headers)
		if not location.is_empty():
			_redirects += 1
			_follow.call_deferred(location)
			return
	var reply: Variant = JSON.parse_string(body.get_string_from_utf8()) if code == 200 else null
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and reply is Dictionary and reply.get("ok", false) == true:
		last_error = ""
		_sent()
		return
	if reply is Dictionary:
		last_error = str(reply.get("error", "answer"))
	elif result != HTTPRequest.RESULT_SUCCESS:
		last_error = "connection"
	else:
		last_error = "answer" # not what the script sends (for example a Google page: the web app is not shared with Anyone)
	push_warning("Assessment: the result was not sent (result %d, code %d, %s). It stays in the outbox and is tried again." % [result, code, last_error])
	_failed()


func _follow(location: String) -> void:
	if _http.request(location) != OK:
		_failed()


func _location_of(headers: PackedStringArray) -> String:
	for line in headers:
		if line.to_lower().begins_with("location:"):
			var location := line.substr(9).strip_edges()
			if location.begins_with("/"): # a path on the same server
				var scheme_end := _endpoint.find("://") + 3
				var host_end := _endpoint.find("/", scheme_end)
				location = (_endpoint.substr(0, host_end) if host_end != -1 else _endpoint) + location
			return location
	return ""


func _sent() -> void:
	if SaveManager.current_slot == _sending_slot: # the player may have gone to another slot meanwhile: it is sent again later
		var outbox: Array = SaveManager.data["assessment"]["outbox"]
		for i in outbox.size():
			if str(outbox[i]["session"]) == _sending_session:
				outbox.remove_at(i)
				break
		SaveManager.save()
	_set_status("sent")
	flush.call_deferred() # the next one, when there is one


func _failed() -> void:
	_set_status("waiting")
	_retry.start(float(_config.get("retry_seconds", 30)))


func _set_status(value: String) -> void:
	status = value
	status_changed.emit()


## How many results of the slot are not sent yet.
func waiting() -> int:
	return 0 if SaveManager.current_slot < 0 else SaveManager.data["assessment"]["outbox"].size()
