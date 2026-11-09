extends Control

## The Monitoring phase: sign-in logs arrive one at a time and the player decides, against the
## rulebook, whether to REPORT it or LET IT PASS. Clicking a line of the card buys a hint from
## Joshua (the notes on the right) and costs time on the log. A hint is a plain fact about that line,
## never the verdict: the player has to apply the rulebook. The NORMAL or SUSPICIOUS tag of each hint
## shows only after the call, together with the verdict bubble.
##
## The day's rules, people and tuning numbers come from the "monitoring" phase data in
## data/days.json (data/scenarios/day N/monitoring.json). LogGenerator builds the logs, and the right
## answer of every log is computed from the rules there.
##
## Timers: one shift clock, and a patience bar for each log. A log that runs out of patience passes.
## Both are frozen for the scripted first logs and while the rulebook is open.
## When the shift is over `shift_finished` is emitted, and the FinishScreen pays out and goes on.

signal shift_finished(result: Dictionary)

enum Step { ASKING, ANSWERED, OVER }
## What a note says about the player's call; RIGHT and WRONG color the whole bubble.
enum Verdict { NONE, RIGHT, WRONG }

const APP := "FramePanel/MainPanel/MainPanelAppView"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
## A part that is unusual but allowed ("odd" in the log data) is tagged NORMAL: the player's call is binary.
const TAG_STATE := {"ok": HintTag.State.OK, "odd": HintTag.State.OK, "bad": HintTag.State.BAD}
const NEXT_TEXT := "NEXT LOG >"
const RESULTS_TEXT := "SEE RESULTS >"
const BREAKS_MARK := "[X] " # text marker for the part that broke a rule, so color is never the only signal
const YELLOW := "#ffcd75"
## The verdict bubbles use the colors of the NORMAL and SUSPICIOUS tags, with the text color that reads on each.
const VERDICT_FILL := {Verdict.RIGHT: Color("38b764"), Verdict.WRONG: Color("b13e53")}
const VERDICT_TEXT := {Verdict.RIGHT: HintTag.DARK_TEXT, Verdict.WRONG: HintTag.LIGHT_TEXT}

var _data: Dictionary
var _generator: LogGenerator
var _log: Dictionary = {}
var _step := Step.ANSWERED # before the first log it waits for NEXT LOG, like between two logs
var _inspected: Dictionary = {} # part index -> true
var _patience := 0.0 # seconds left on this log
var _shift_left := 0.0
var _correct := 0
var _wrong := 0
var _reported: Array = [] # ids of the logs the player reported
var _answers: Array = [] # {id, reported, right} per log
## The card has one row for each line (Field1 to Field8 in the scene): a FieldLabel with the name of
## the line and a FieldButton with its value. The button is what the player clicks.
var _rows: Array[Control] = []
var _labels: Array[Label] = []
var _fields: Array[Button] = []
var _hint_bubbles: Array = [] # {bubble, state} for the hints of this log, whose tags show after the call
var _rulebook: Panel
var _shown_seconds := -1
var _no_time_noted := false # the "not enough time" line is said once per log
var _arriving := false # the log card is animating in: nothing is timed or clickable yet

@onready var _guide: RichTextLabel = get_node(APP + "/Panel/Guide")
@onready var _score: RichTextLabel = get_node(APP + "/Panel/NumberOfCorrects")
@onready var _time_left: RichTextLabel = get_node(APP + "/Panel/TimeLeft")
@onready var _animation: AnimationPlayer = $FinishScreen/AnimationPlayer # its root_node is this scene
@onready var _log_card: PanelContainer = get_node(APP + "/HSplitContainer/Left/Log")
@onready var _log_title: Label = get_node(APP + "/HSplitContainer/Left/Log/LogContainer/Title")
@onready var _log_box: VBoxContainer = get_node(APP + "/HSplitContainer/Left/Log/LogContainer")
@onready var _bar_label: Label = get_node(APP + "/HSplitContainer/Left/BarLabel")
@onready var _bar: ProgressBar = get_node(APP + "/HSplitContainer/Left/ProgressBar")
@onready var _scroll: ScrollContainer = get_node(APP + "/HSplitContainer/Right/NotesPanel/VScrollBar")
@onready var _notes: VBoxContainer = get_node(APP + "/HSplitContainer/Right/NotesPanel/VScrollBar/Notes")
@onready var _bubble_template: PanelContainer = _notes.get_child(0) # the ChatBubble every note is copied from
@onready var _report_button: Button = $FramePanel/ReportButton
@onready var _pass_button: Button = $FramePanel/LetPassButton
@onready var _next_button: Button = $FramePanel/NextLogButton
@onready var _rulebook_button: Button = $FramePanel/RuleBookButton
@onready var _pause_button: TextureButton = $FramePanel/MainPanel/PauseButton
@onready var _finish: FinishScreen = $FinishScreen


func _ready() -> void:
	_log_card.hide() # empty until the first log arrives
	_animation.animation_finished.connect(func(_name: StringName) -> void: _arriving = false)
	GameState.set_phase("monitoring")
	_data = GameState.scenario
	if _data.is_empty():
		push_error("Monitoring: no data for day %d (see data/days.json)" % GameState.current_day)
		set_process(false)
		return
	_generator = LogGenerator.new(_data, 0, GameState.completed_story_logs)
	_shift_left = float(_data["shift_seconds"])

	_bubble_template.hide()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	for row in _log_box.get_children():
		var field := row.get_node_or_null("FieldButton") as Button
		if field != null:
			field.toggle_mode = true # a pressed line shows the line was asked about
			field.pressed.connect(_on_field_pressed.bind(_fields.size()))
			_rows.append(row as Control)
			_labels.append(row.get_node("FieldLabel") as Label)
			_fields.append(field)

	# REPORT, LET PASS, NEXT LOG and the RULEBOOK toggle are connected in Monitoring.tscn.
	_pause_button.pressed.connect(PauseMenu.open)

	_guide.text = _guide_text()
	_build_rulebook()
	_refresh_clock()
	await get_tree().process_frame # the notes panel has its size only after the first layout pass
	_add_note(_data["messages"]["start"]) # no log yet: the first one comes with NEXT LOG
	await SceneManager.wait_for_transition()
	Tutorial.maybe_show(self, "monitoring")


func _process(delta: float) -> void:
	if _step == Step.OVER or _log.is_empty() or _arriving or _rulebook.visible or _is_guided():
		return
	_shift_left = maxf(0.0, _shift_left - delta)
	if _step == Step.ASKING:
		_patience -= delta
		if _patience <= 0.0:
			_answer(false, true) # a log nobody touched passes
	_refresh_clock()


# --- Logs ---

func _show_next_log() -> void:
	_log = _generator.next_log(_correct) # the more the player has solved, the likelier a story log
	_step = Step.ASKING
	_inspected.clear()
	_no_time_noted = false
	_patience = float(_data["log_seconds"])
	_log_title.text = "%s · LOG #%d" % [_log["title"], _log["number"]]
	var parts: Array = _log["parts"]
	for i in _fields.size():
		_rows[i].visible = i < parts.size()
		_fields[i].disabled = false
		_fields[i].set_pressed_no_signal(false)
		if i < parts.size():
			_labels[i].text = "%s:" % parts[i]["label"]
			_fields[i].text = str(parts[i]["value"])
	_set_buttons()
	_clear_notes()
	for line: String in _data["guide"].get(str(_log["number"]), []):
		_add_note(line)
	_arriving = true
	_log_card.show()
	_animation.play(&"LogAnimation")
	_animation.advance(0.0) # apply the first frame (empty card) before it is drawn
	_refresh_clock()


## A click on one line of the card: Joshua's hint, and part of the log's patience.
func _on_field_pressed(index: int) -> void:
	var already := _inspected.has(index)
	if _step != Step.ASKING or already or _rulebook.visible or _arriving:
		_fields[index].set_pressed_no_signal(already) # the toggle already flipped; put it back
		return
	# Every click costs the same share of the bar, so asking about everything is not possible. A click
	# that would empty the bar is refused instead: the player is never timed out by a question.
	var cost := 0.0 if _is_guided() else float(_data["log_seconds"]) * float(_data["inspect_percent_per_click"]) / 100.0
	if _patience - cost <= 0.0:
		_fields[index].set_pressed_no_signal(false)
		if not _no_time_noted:
			_no_time_noted = true
			_add_note(_data["messages"]["no_time"])
		return
	_inspected[index] = true
	_fields[index].set_pressed_no_signal(true)
	_patience -= cost
	var parts: Array = _log["parts"]
	var part: Dictionary = parts[index]
	# The hint has no tag yet: it comes after the call, so the player decides from the facts.
	_hint_bubbles.append({"bubble": _add_note(part["hint"]), "state": TAG_STATE[part["state"]]})
	_refresh_clock()


func _on_report_button_pressed() -> void:
	_answer(true, false)


func _on_let_pass_button_pressed() -> void:
	_answer(false, false)


func _answer(report: bool, timed_out: bool) -> void:
	if _step != Step.ASKING or _rulebook.visible or _arriving: # keys can still reach the buttons under the rulebook
		return
	var truth: Dictionary = _log["truth"]
	var right: bool = report == truth["suspicious"]
	if right:
		_correct += 1
		if not _log["story_id"].is_empty():
			GameState.completed_story_logs[_log["story_id"]] = true # solved: it never comes back
	else:
		_wrong += 1
	if report:
		_reported.append(_log["id"])
	_answers.append({"id": _log["id"], "reported": report, "right": right, "reason": truth["reason"]})

	_reveal_hint_tags()
	# The parts that broke a rule are marked in the text, whatever the player decided.
	var parts: Array = _log["parts"]
	for i in parts.size():
		if parts[i]["state"] == LogGenerator.STATE_BAD:
			_fields[i].text = BREAKS_MARK + _fields[i].text

	var messages: Dictionary = _data["messages"]
	var template: String = messages["timeout"] if timed_out else (messages["right"] if right else messages["wrong"])
	_add_note(template.replace("{reason}", truth["reason"]), Verdict.RIGHT if right else Verdict.WRONG)
	_step = Step.ANSWERED
	_set_buttons()
	_refresh_clock()


func _on_next_log_button_pressed() -> void:
	if _step != Step.ANSWERED or _rulebook.visible:
		return
	if _shift_left <= 0.0:
		_finish_shift()
	else:
		_show_next_log()


func _finish_shift() -> void:
	_step = Step.OVER
	var points := _correct * int(_data["points_correct"])
	GameState.reported_anomalies = _reported
	_log_title.text = "SHIFT OVER"
	for row in _rows:
		row.hide()
	_bar.value = 0.0
	_set_buttons()
	_clear_notes()
	_add_note(_data["messages"]["end"])
	shift_finished.emit({"correct": _correct, "wrong": _wrong, "points": points, "answers": _answers})
	_finish.show_results(_finish_summary())


## The figures of the FinishScreen: the logs, the points for the right calls and the penalty for the
## wrong ones, and Joshua's comment. A shift with no wrong call earns his bonus. Any other comment names
## the first wrong call and why it was wrong, which is the lesson.
func _finish_summary() -> Dictionary:
	var finish: Dictionary = _data["finish"]
	var judged := _correct + _wrong
	var first_reason := ""
	for answer: Dictionary in _answers:
		if not answer["right"]:
			first_reason = answer["reason"]
			break
	var key := "rough"
	if _wrong == 0:
		key = "flawless" if _correct >= int(finish["flawless_min_correct"]) else "short"
	elif float(_correct) / float(judged) >= float(finish["good_accuracy"]):
		key = "good"
	return {
		"rows": [
			{"count": judged},
			{"count": _correct, "points": _correct * int(_data["points_correct"])},
			{"count": _wrong, "points": -_wrong * int(finish["points_wrong"])},
		],
		"monitoring_answers": _answers, # retain actual generated-log verdicts for Recovery
		"comment": str(finish["comments"][key]).replace("{reason}", first_reason),
		"bonus": int(finish["bonus"]) if key == "flawless" else 0,
	}


## Report and Pass work while a log waits for an answer; Next works once it has one.
func _set_buttons() -> void:
	var asking := _step == Step.ASKING
	_report_button.disabled = not asking
	_pass_button.disabled = not asking
	_next_button.disabled = _step != Step.ANSWERED
	_next_button.text = RESULTS_TEXT if _shift_left <= 0.0 else NEXT_TEXT
	_rulebook_button.disabled = _step == Step.OVER


# --- HUD ---

## The first logs are scripted: nothing is timed until the player has seen how it works.
func _is_guided() -> bool:
	return not _log.is_empty() and _log["number"] <= _generator.guided_count()


func _refresh_clock() -> void:
	var seconds := ceili(_shift_left)
	if seconds != _shown_seconds:
		_shown_seconds = seconds
		_time_left.text = "Time Left: %d:%02d" % [floori(seconds / 60.0), seconds % 60]
		_set_buttons() # the shift may just have ended: NEXT LOG becomes SEE RESULTS
	_score.text = "Correct %d · Wrong %d" % [_correct, _wrong]
	var share := 0.0 if _step == Step.OVER else clampf(_patience / float(_data["log_seconds"]), 0.0, 1.0)
	_bar.value = share * 100.0
	# Said in words, so it is clear why the bar is not moving (the guided logs, the rulebook).
	var paused := _step == Step.ASKING and (_is_guided() or _rulebook.visible)
	var label := "TIME ON THIS LOG %d/10%s" % [ceili(share * 10.0), " - PAUSED" if paused else ""]
	if _log.is_empty():
		label = "NO LOG YET"
	if label != _bar_label.text:
		_bar_label.text = label


## What the rules point to, always on screen: the office hours and who is on call tonight.
func _guide_text() -> String:
	for rule: Dictionary in _data["rules"]:
		if rule["check"] == "range":
			return "Office hours: %s - %s    On call tonight: %s" % [
					LogGenerator.format_clock(rule["min"]), LogGenerator.format_clock(rule["max"]), _data["on_call"]]
	return ""


# --- Joshua's notes ---

## Adds one chat bubble (a copy of the first child of Notes), without a tag, and returns it.
## `verdict` colors the bubble for the result of a call.
func _add_note(text: String, verdict: Verdict = Verdict.NONE) -> PanelContainer:
	var bubble := _bubble_template.duplicate() as PanelContainer
	bubble.show()
	var content := bubble.find_child("Content", true, false) as Label
	var tag := bubble.find_child("Tag", true, false) as HintTag
	content.text = text
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if verdict != Verdict.NONE:
		var box := bubble.get_theme_stylebox("panel").duplicate() as StyleBoxFlat # not the template's own
		box.bg_color = VERDICT_FILL[verdict]
		box.border_color = box.bg_color.lightened(0.35)
		bubble.add_theme_stylebox_override("panel", box)
		content.add_theme_color_override("font_color", VERDICT_TEXT[verdict])
	tag.hide() # a hint's tag is shown by _reveal_hint_tags
	_notes.add_child(bubble)
	tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # the tag stays on the first line of a long text
	_fit_bubble(bubble, tag, content)
	_scroll_to_end()
	return bubble


## After the call, each hint shows whether its line was NORMAL or SUSPICIOUS. The bubble is fitted
## again, since the tag takes room.
func _reveal_hint_tags() -> void:
	for hint: Dictionary in _hint_bubbles:
		var bubble: PanelContainer = hint["bubble"]
		var tag := bubble.find_child("Tag", true, false) as HintTag
		tag.show()
		tag.set_state(hint["state"])
		_fit_bubble(bubble, tag, bubble.find_child("Content", true, false) as Label)


## The bubble hugs its text. Its width is the text's width, up to the room the notes panel has; past
## that the text wraps. (An autowrapping label in a shrinking container would otherwise be one word wide.)
func _fit_bubble(bubble: PanelContainer, tag: Label, content: Label) -> void:
	var font := content.get_theme_font("font")
	var wanted := ceilf(font.get_string_size(content.text, HORIZONTAL_ALIGNMENT_LEFT, -1, content.get_theme_font_size("font_size")).x) + 1.0
	var room := _scroll.size.x - _scroll.get_v_scroll_bar().get_combined_minimum_size().x
	room -= bubble.get_theme_stylebox("panel").get_minimum_size().x
	if tag.visible:
		room -= tag.get_combined_minimum_size().x + content.get_parent().get_theme_constant("separation")
	content.custom_minimum_size.x = minf(wanted, maxf(room, 40.0))


## Empties the notes (everything but the template at index 0), so each log starts clean.
func _clear_notes() -> void:
	_hint_bubbles.clear()
	for i in range(_notes.get_child_count() - 1, 0, -1):
		var note := _notes.get_child(i)
		_notes.remove_child(note)
		note.queue_free()
	_scroll.scroll_vertical = 0


func _scroll_to_end() -> void:
	await get_tree().process_frame # the new row has its size only after the layout pass
	_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


# --- Rulebook ---

## The RULEBOOK button is a toggle: down while the rulebook is open. CLOSE lets it up again.
func _on_rule_book_button_toggled(toggled_on: bool) -> void:
	_rulebook.visible = toggled_on
	_refresh_clock()
	if toggled_on:
		_rulebook.get_node("Close").grab_focus()
	else:
		_rulebook_button.grab_focus()


## The rules of the day on a card over the app. Opening it stops both clocks.
func _build_rulebook() -> void:
	_rulebook = Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color("1a1c2c")
	box.set_border_width_all(2)
	box.border_color = Color("3b5dc9")
	_rulebook.add_theme_stylebox_override("panel", box)
	# Covers the app and the buttons under it (a child of this screen, so it draws above them);
	# the RULEBOOK button stays free to close it.
	_rulebook.anchor_left = 0.02
	_rulebook.anchor_top = 0.11
	_rulebook.anchor_right = 0.98
	_rulebook.anchor_bottom = 0.88
	_rulebook.hide()
	add_child(_rulebook)

	var text := RichTextLabel.new()
	text.name = "Text"
	text.bbcode_enabled = true
	text.add_theme_font_override("normal_font", FONT)
	text.add_theme_font_size_override("normal_font_size", 6)
	text.add_theme_color_override("default_color", Color("f4f4f4"))
	text.set_anchors_preset(Control.PRESET_FULL_RECT)
	text.offset_left = 8.0
	text.offset_top = 8.0
	text.offset_right = -8.0
	text.offset_bottom = -8.0
	text.text = _rulebook_text()
	_rulebook.add_child(text)

	var close := Button.new()
	close.name = "Close"
	close.text = "CLOSE"
	close.theme = _next_button.theme
	for style_name in ["normal", "pressed", "hover"]:
		close.add_theme_stylebox_override(style_name, _next_button.get_theme_stylebox(style_name))
	# Top right, beside the heading, so the rules get the whole card (the scroll bar is further right).
	close.anchor_left = 1.0
	close.anchor_right = 1.0
	close.offset_left = -76.0
	close.offset_top = 6.0
	close.offset_right = -20.0
	close.offset_bottom = 20.0
	close.pressed.connect(func() -> void: _rulebook_button.button_pressed = false)
	_rulebook.add_child(close)


func _rulebook_text() -> String:
	var book: Dictionary = _data.get("rulebook", {}) # the two sentences around the rules, from the scenario
	var lines: Array[String] = [
		"[color=%s]RULEBOOK[/color]" % YELLOW,
		str(book.get("intro", "REPORT a sign-in that breaks a rule. LET IT PASS if it follows every rule.")),
		"",
	]
	var number := 1
	for rule: Dictionary in _data["rules"]:
		lines.append("[color=%s]%d. %s[/color]" % [YELLOW, number, rule["name"]])
		lines.append(rule["text"])
		lines.append_array(rule.get("details", []))
		if rule.has("exception_text"):
			lines.append(rule["exception_text"])
		if rule.has("odd_margin"):
			lines.append(str(book.get("margin", "Within %d minutes of the limit is a bit odd, but still allowed.")) % rule["odd_margin"])
		lines.append("Good: %s    Bad: %s" % [rule["example_ok"], rule["example_bad"]])
		lines.append("Why: %s" % rule["why"])
		lines.append("")
		number += 1
	return "\n".join(lines)


# --- Debug panel (=) ---

func debug_info() -> String:
	return "LOG #%d   SHIFT %d s   CORRECT %d  WRONG %d" % [_log.get("number", 0), ceili(_shift_left), _correct, _wrong]


func debug_actions() -> Array:
	return [
		["COMPLETE PHASE (perfect run) >", debug_complete.bind(true)],
		["Skip to results (3 wrong) >", debug_complete.bind(false)],
	]


## Ends the shift now with made-up results: 8 right calls, and 3 wrong ones unless `perfect`.
func debug_complete(perfect: bool) -> void:
	if _step == Step.OVER or _data.is_empty():
		return
	_correct = 8
	_wrong = 0 if perfect else 3
	_answers.clear()
	for i in _correct + _wrong:
		_answers.append({"id": "debug_%d" % i, "reported": false, "right": i < _correct, "reason": "This call was made wrong for the debug run."})
	_finish_shift()
