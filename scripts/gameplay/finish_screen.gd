class_name FinishScreen
extends Control

## The results screen at the end of a phase (Investigation and Monitoring share this script).
## The phase scene calls show_results() with its figures; this screen pays the Security Points into
## the wallet, saves, and plays the results:
##   1. the screen fades to black,
##   2. the title, the rows, Joshua's comment, the points and the wallet appear one by one, top to bottom,
##   3. the numbers count up, the points gained are added up piece by piece, then they are added to the wallet,
##   4. CONTINUE opens the next phase.
## A click, Space or Enter while it plays finishes the animation at once.
##
## show_results() takes {
##   "rows": [{"name": optional text, "count": int, "points": optional int, negative for a penalty}, ...],
##   "comment": text, "bonus": int,
##   "practice": optional bool, true = show the points without paying or saving them
## }. The rows go to the rows of the scene in order: first the ones in LeftContainer, then RightContainer.
## A phase can also change the texts of the scene: "title", "button" (the CONTINUE text), "gained_text"
## (the text before the points) and "extra_button" (shows the scene's ExtraButton with that text; it
## needs an ExtraButton node and emits extra_requested).

## Emitted by CONTINUE when a phase connects to it (Recovery practice returns to its menu).
## With nothing connected, CONTINUE opens the next phase as before.
signal continue_requested
## Emitted by the ExtraButton, the second choice next to CONTINUE (Response: TRY AGAIN).
signal extra_requested

const REPLAY_TEXT := "Replay, half pay: "
const PRACTICE_TEXT := "Practice, not paid: "

const FADE_TIME := 0.6 # to black
const REVEAL_TIME := 0.15 # one element appears
const GAP := 0.2 # pause between two elements
const COUNT_TIME := 0.4

var _rows: Array[HBoxContainer] = []
var _playing := false
var _skipping := false
var _practice := false

@onready var _title: Label = $Title
@onready var _comment_title: Label = $CommentTitle
@onready var _comment: Label = $CommentTitle/CommentContent
@onready var _bonus: Label = $CommentTitle/BonusPointsEarned
@onready var _gained_row: HBoxContainer = $SecurityPoints/SecurityPointsGained
@onready var _gained_name: Label = $SecurityPoints/SecurityPointsGained/SPName
@onready var _gained: Label = $SecurityPoints/SecurityPointsGained/SPGained
@onready var _wallet_row: HBoxContainer = $SecurityPoints/SecurityPointsWalletRow
@onready var _wallet: Label = $SecurityPoints/SecurityPointsWalletRow/CurrentSecurityPoints
@onready var _continue: Button = $LogsButton
@onready var _extra: Button = get_node_or_null("ExtraButton")


func _ready() -> void:
	hide() # it is visible in the scene editor so it can be laid out
	for container_name in ["LeftContainer", "RightContainer", "Container"]: # Investigation uses one "Container"
		var container := get_node_or_null(container_name)
		if container != null:
			for row in container.get_children():
				if row is HBoxContainer:
					_rows.append(row)
	_continue.pressed.connect(_on_continue_pressed)
	if _extra != null:
		_extra.pressed.connect(_on_extra_pressed)
	_comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func show_results(summary: Dictionary) -> void:
	if _playing or visible:
		return
	var lines: Array = summary["rows"]
	var bonus := int(summary.get("bonus", 0))
	var steps: Array[int] = [] # what the points gained add up to after each line, then the bonus
	var total := 0
	for line: Dictionary in lines:
		if line.has("points"):
			total += int(line["points"])
			steps.append(maxi(total, 0))
	if bonus > 0:
		total += bonus
		steps.append(maxi(total, 0))
	var gain := maxi(total, 0)

	# A phase that was already cleared pays half. Paid and saved before the animation, so quitting
	# during it loses nothing.
	var day := GameState.current_day
	var phase := GameState.current_phase
	_practice = summary.get("practice", false) == true
	var replay := not _practice and SaveManager.current_slot >= 0 and SaveManager.is_phase_complete(day, phase)
	if replay:
		gain = int(gain / 2.0)
		steps.append(gain)
	var before := GameState.wallet()
	if not _practice:
		GameState.capture_phase_findings(phase, summary.get("monitoring_answers", []))
		_pay(gain, day, phase)

	_fill(lines, str(summary.get("comment", "")), bonus, replay)
	_apply_texts(summary)
	await _play(lines, bonus, steps, gain, before)


func _pay(gain: int, day: int, phase: String) -> void:
	var total := GameState.wallet() + gain
	GameState.security_points = total
	if SaveManager.current_slot >= 0:
		SaveManager.data["security_points"] = total
		if phase == "investigation": # later phases (Hardening) read what the player found
			var found: Array = SaveManager.data["found_clues"]
			for id: String in GameState.found_clue_ids():
				if not found.has(id):
					found.append(id)
		SaveManager.complete_phase(day, phase)
		SaveManager.save()


## The texts, before anything is shown: the animation only reveals and counts.
func _fill(lines: Array, comment: String, bonus: int, replay: bool) -> void:
	for i in _rows.size():
		_rows[i].visible = i < lines.size()
		if i >= lines.size():
			continue
		var line: Dictionary = lines[i]
		if line.has("name"):
			(_rows[i].get_node("Name") as Label).text = str(line["name"])
		(_rows[i].get_node("Number") as Label).text = "0"
		var points := _points_label(_rows[i])
		if points != null:
			points.visible = line.has("points")
			points.text = _signed(0)
	if lines.size() > _rows.size():
		push_warning("FinishScreen: %d rows given, the scene has %d" % [lines.size(), _rows.size()])
	_comment.text = comment
	_comment.visible_ratio = 0.0
	_bonus.visible = bonus > 0
	_bonus.text = "( +0 SP)"
	_gained_name.text = PRACTICE_TEXT if _practice else (REPLAY_TEXT if replay else "Security Points: ")
	_gained.text = _signed(0)
	_wallet.text = "%dSP" % GameState.wallet()
	_continue.text = "CONTINUE"


## The optional texts of the summary (see the top). With an ExtraButton the two buttons sit side by side.
func _apply_texts(summary: Dictionary) -> void:
	if summary.has("title"):
		_title.text = str(summary["title"])
	if summary.has("button"):
		_continue.text = str(summary["button"])
	if summary.has("gained_text"):
		_gained_name.text = str(summary["gained_text"])
	if _extra == null:
		return
	_extra.text = str(summary.get("extra_button", ""))
	_extra.visible = not _extra.text.is_empty()
	if _extra.visible:
		var shift := (_continue.anchor_right - _continue.anchor_left) / 2.0 + 0.01
		_extra.anchor_left = _continue.anchor_left - shift
		_extra.anchor_right = _continue.anchor_right - shift
		_continue.anchor_left += shift
		_continue.anchor_right += shift


func _play(lines: Array, bonus: int, steps: Array[int], gain: int, before: int) -> void:
	_playing = true
	_skipping = false
	_hide_content()
	_continue.disabled = true
	if _extra != null:
		_extra.disabled = true
	modulate.a = 0.0
	show()

	await _fade(self, FADE_TIME) # to black

	await _fade(_title, REVEAL_TIME)
	await _wait(GAP)
	for i in lines.size():
		var row := _rows[i]
		var line: Dictionary = lines[i]
		await _fade(row.get_node("Name"), REVEAL_TIME)
		var number := row.get_node("Number") as Label
		number.modulate.a = 1.0
		await _count(number, 0, int(line["count"]), COUNT_TIME, "%d")
		var points := _points_label(row)
		if points != null and line.has("points"):
			points.modulate.a = 1.0
			await _count(points, 0, int(line["points"]), COUNT_TIME, "%+dSP")
		await _wait(GAP)

	await _fade(_comment_title, REVEAL_TIME)
	_comment.modulate.a = 1.0
	await _type(_comment)
	if bonus > 0:
		_bonus.modulate.a = 1.0
		await _count(_bonus, 0, bonus, COUNT_TIME, "( +%d SP)")
	await _wait(GAP)

	# The points are added up piece by piece: every row, then the bonus.
	await _fade(_gained_row, REVEAL_TIME)
	var shown := 0
	for step in steps:
		await _count(_gained, shown, step, COUNT_TIME, "%+dSP")
		shown = step
	_gained.text = _signed(gain)
	await _wait(GAP)

	# Then into the wallet.
	await _fade(_wallet_row, REVEAL_TIME)
	await _wait(GAP)
	await _count(_wallet, before, before + (0 if _practice else gain), COUNT_TIME * 2.0, "%dSP")
	await _wait(GAP)

	if _extra != null and _extra.visible:
		await _fade(_extra, REVEAL_TIME)
		_extra.disabled = false
	await _fade(_continue, REVEAL_TIME)
	_continue.disabled = false
	_continue.grab_focus()
	_playing = false


## Everything is invisible (not hidden, so the layout stays) until its turn.
func _hide_content() -> void:
	for node: CanvasItem in [_title, _comment_title, _comment, _bonus, _gained_row, _wallet_row, _continue]:
		node.modulate.a = 0.0
	if _extra != null:
		_extra.modulate.a = 0.0
	for row in _rows:
		for child in row.get_children():
			(child as CanvasItem).modulate.a = 0.0


func _points_label(row: HBoxContainer) -> Label:
	return row.get_node_or_null("PointsEarned") as Label


func _signed(value: int) -> String:
	return "%+dSP" % value


func _fade(node: CanvasItem, time: float) -> void:
	var elapsed := 0.0
	while elapsed < time and not _skipping:
		elapsed += get_process_delta_time()
		node.modulate.a = clampf(elapsed / time, 0.0, 1.0)
		await get_tree().process_frame
	node.modulate.a = 1.0


func _wait(time: float) -> void:
	var elapsed := 0.0
	while elapsed < time and not _skipping:
		elapsed += get_process_delta_time()
		await get_tree().process_frame


## The number runs from `from` to `to` and slows down as it arrives.
func _count(label: Label, from: int, to: int, time: float, format: String) -> void:
	var elapsed := 0.0
	while elapsed < time and not _skipping and from != to:
		elapsed += get_process_delta_time()
		var progress := ease(clampf(elapsed / time, 0.0, 1.0), 0.4)
		label.text = format % roundi(lerpf(from, to, progress))
		await get_tree().process_frame
	label.text = format % to


## Joshua's comment is typed out.
func _type(label: Label) -> void:
	var time := clampf(label.text.length() * 0.015, 0.4, 1.2)
	var elapsed := 0.0
	while elapsed < time and not _skipping:
		elapsed += get_process_delta_time()
		label.visible_ratio = clampf(elapsed / time, 0.0, 1.0)
		await get_tree().process_frame
	label.visible_ratio = 1.0


func _input(event: InputEvent) -> void:
	if not _playing or _skipping:
		return
	var pressed := event.is_action_pressed("ui_accept")
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pressed = true
	if pressed:
		_skipping = true
		get_viewport().set_input_as_handled()


## Opens what comes next: the dialogue of the next phase, or the phase itself when it has no dialogue,
## or the day select when nothing follows (the phase is not built yet, or the day is over).
func _on_extra_pressed() -> void:
	_continue.disabled = true
	_extra.disabled = true
	extra_requested.emit()


func _on_continue_pressed() -> void:
	_continue.disabled = true
	if _extra != null:
		_extra.disabled = true
	if not continue_requested.get_connections().is_empty():
		continue_requested.emit()
		return
	var next := GameState.PHASES.find(GameState.current_phase) + 1
	if next >= GameState.PHASES.size():
		SceneManager.load_stage_select()
		return
	GameState.set_phase(GameState.PHASES[next])
	SceneManager.open_current_phase()
