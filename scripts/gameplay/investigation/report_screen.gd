class_name ReportScreen
extends Control

## The report: a short story of the case with blanks, and a tray of words to choose from (some are
## right, some are not). Drag a word into a blank, or click a word and then a blank; drag a word
## out of a blank, or click a filled blank, to put it back. SUBMIT REPORT checks the blanks: the
## wrong words go back to the tray and the player tries again (there is no game over). When every
## blank is right, the button turns into CONTINUE and `completed` is emitted when it is pressed.
##
## The story, words and answers come from the scenario's "report" section. Right and wrong are
## always written out ("[OK]", a message naming the wrong blanks), never shown by color alone.

signal completed

const THEME := preload("res://scenes/gameplay/investigation/report_theme.tres")
const SLOT_MIN_SIZE := Vector2(80, 14)

var _report: Dictionary = {}
var _notes: Array[String] = []
var _built := false
var _chips: Dictionary = {} # chip id -> WordChip
var _reasons: Dictionary = {} # chip id -> why that word does not fit (decoys only)
var _chip_ids: Array[String] = []
var _slots: Array[WordSlot] = [] # _slots[0] is blank number 1
var _placed: Dictionary = {} # blank number -> chip id
var _locked: Dictionary = {} # blank number -> true once the right word is in it
var _picked := "" # the chip chosen by clicking, waiting for a blank
var _solved := false
var _mistakes := 0 # wrong words handed in so far, over every submit

@onready var _story_flow: HFlowContainer = $MainPanel/Case/CaseVBoxContainer/HFlowContainer
@onready var _clue_words: Panel = $MainPanel/ClueWords
@onready var _tray: HFlowContainer = $MainPanel/ClueWords/ClueBox/Clues
@onready var _notes_text: RichTextLabel = $MainPanel/Notes/RichTextLabel
@onready var _message_icon: Label = $MainPanel/Helper/HelperRow/MessageIcon
@onready var _message_text: Label = $MainPanel/Helper/HelperRow/MessageContent
@onready var _submit_button: Button = $MainPanel/FinishReportButton
@onready var _pause_button: TextureButton = $MainPanel/PauseButton


func _ready() -> void:
	_submit_button.pressed.connect(_on_submit_pressed)
	_pause_button.pressed.connect(PauseMenu.open)
	_message_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A drop on the word tray puts a word that came out of a blank back.
	_clue_words.set_drag_forwarding(Callable(), _can_return_chip, _return_chip)
	if get_tree().current_scene == self: # run on its own (F6): mark the clues, open straight away
		GameState.set_phase(GameState.current_phase)
		for app: Dictionary in GameState.scenario.get("investigation", {}).values():
			for entry: Dictionary in app.get("entries", []):
				if entry.get("is_clue", false):
					GameState.set_marked(str(entry["id"]), true)
		open()


## Shows the report. The words in the tray are shuffled every time it opens; blanks that are
## already filled stay as they are.
func open() -> void:
	_report = GameState.scenario.get("report", {})
	if not _built:
		_build()
	_fill_notes()
	_shuffle_tray()
	_picked = ""
	if not _solved:
		_set_message("prompt")
	_refresh()
	show()
	_focus_start()


func is_solved() -> bool:
	return _solved


## How many wrong words the player handed in before the report was right (shown on the FinishScreen).
func mistakes() -> int:
	return _mistakes


func _build() -> void:
	_built = true
	_tray.theme = THEME
	_story_flow.theme = THEME
	_build_story(str(_report.get("text", "")))
	for chip_data: Dictionary in _report.get("chips", []):
		var chip := WordChip.new()
		chip.chip_id = str(chip_data.get("id", ""))
		chip.chip_label = str(chip_data.get("label", ""))
		_reasons[chip.chip_id] = str(chip_data.get("reason", ""))
		chip.mouse_filter = Control.MOUSE_FILTER_PASS # a drop on a word reaches the tray behind it
		chip.theme_type_variation = &"ChipButton"
		chip.pressed.connect(_on_chip_pressed.bind(chip.chip_id))
		_tray.add_child(chip)
		_chips[chip.chip_id] = chip
		_chip_ids.append(chip.chip_id)


## The sentence, word by word so it wraps, with a blank where {1}, {2}... stand. Punctuation that
## follows a blank is kept right next to it.
func _build_story(text: String) -> void:
	var regex := RegEx.create_from_string("\\{(\\d+)\\}")
	var cursor := 0
	for found in regex.search_all(text):
		_add_words(text.substr(cursor, found.get_start() - cursor))
		cursor = found.get_end()
		var suffix := ""
		while cursor < text.length() and text[cursor] != " " and text[cursor] != "{":
			suffix += text[cursor]
			cursor += 1
		_add_blank(int(found.get_string(1)), suffix)
	_add_words(text.substr(cursor))


func _add_words(segment: String) -> void:
	for word in segment.split(" ", false):
		_story_flow.add_child(_story_label(word))


func _story_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = &"StoryLabel"
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _add_blank(number: int, suffix: String) -> void:
	var slot := WordSlot.new()
	slot.slot_number = number
	slot.custom_minimum_size = SLOT_MIN_SIZE
	slot.pressed.connect(_on_slot_pressed.bind(number))
	slot.chip_dropped.connect(_on_chip_dropped)
	_slots.append(slot)
	if suffix.is_empty():
		_story_flow.add_child(slot)
		return
	var pair := HBoxContainer.new()
	pair.add_theme_constant_override("separation", 0)
	pair.add_child(slot)
	pair.add_child(_story_label(suffix))
	_story_flow.add_child(pair)


## The notes are the summaries of the clues the player found, in scenario order.
func _fill_notes() -> void:
	_notes.clear()
	for app: Dictionary in GameState.scenario.get("investigation", {}).values():
		for entry: Dictionary in app.get("entries", []):
			if GameState.is_marked(str(entry.get("id", ""))):
				_notes.append("- %s" % entry.get("summary", entry.get("title", "")))
	_notes_text.text = "\n".join(_notes)


func _shuffle_tray() -> void:
	var order := _chip_ids.duplicate()
	order.shuffle()
	for i in order.size():
		_tray.move_child(_chips[order[i]], i)


## Redraws every chip, blank, the message and the button from the placements.
func _refresh() -> void:
	var picked_prefix := str(_report.get("chip_picked", ""))
	for id: String in _chips:
		var chip: WordChip = _chips[id]
		var is_picked := id == _picked
		chip.visible = _slot_of(id) == 0
		chip.theme_type_variation = &"ChipButtonPicked" if is_picked else &"ChipButton"
		chip.text = (picked_prefix if is_picked else "") + chip.chip_label
	for slot in _slots:
		var n := slot.slot_number
		var id: String = _placed.get(n, "")
		slot.chip_id = id
		slot.chip_label = _chips[id].chip_label if _chips.has(id) else ""
		slot.locked = _locked.has(n)
		slot.disabled = slot.locked
		if slot.locked:
			slot.theme_type_variation = &"SlotButtonLocked"
			slot.text = "%s %s" % [_report.get("slot_correct", ""), slot.chip_label]
		elif not id.is_empty():
			slot.theme_type_variation = &"SlotButtonFilled"
			slot.text = "%d: %s" % [n, slot.chip_label]
		else:
			slot.theme_type_variation = &"SlotButton"
			slot.text = "%d: %s" % [n, _report.get("slot_empty", "")]
	var all_filled := _placed.size() == _slots.size()
	_submit_button.disabled = not (all_filled or _solved)
	if _solved:
		_submit_button.text = str(_report.get("continue_button", ""))
	elif all_filled:
		_submit_button.text = str(_report.get("submit_button", ""))
	else:
		_submit_button.text = str(_report.get("submit_locked", ""))


## kind: prompt, picked, some_wrong, none_right or solved. `values` fills {tokens} in the text.
func _set_message(kind: String, values: Dictionary = {}) -> void:
	var text := str(_report.get("messages", {}).get(kind, ""))
	if kind == "solved":
		text += " " + str(_report.get("solved_explanation", ""))
	for key: String in values:
		text = text.replace("{%s}" % key, str(values[key]))
	_message_text.text = text
	var icon_key := "wrong" if kind in ["some_wrong", "none_right"] else kind
	_message_icon.text = str(_report.get("icons", {}).get(icon_key, ""))


func _slot_of(chip_id: String) -> int:
	for n: int in _placed:
		if _placed[n] == chip_id:
			return n
	return 0


## Puts a chip in a blank. A word already in that blank goes to the chip's old blank, or back to
## the tray when the chip came from the tray.
func _place(chip_id: String, blank: int) -> void:
	var old_blank := _slot_of(chip_id)
	var displaced: String = _placed.get(blank, "")
	if old_blank != 0:
		_placed.erase(old_blank)
		if not displaced.is_empty():
			_placed[old_blank] = displaced
	_placed[blank] = chip_id


func _on_chip_pressed(chip_id: String) -> void:
	if _solved:
		return
	if _picked == chip_id:
		_picked = ""
		_set_message("prompt")
	else:
		_picked = chip_id
		_set_message("picked", {"word": _chips[chip_id].chip_label})
	_refresh()
	if not _picked.is_empty():
		_focus_first_empty_blank() # keyboard: Enter on a word, then Enter on the blank it goes in


func _on_slot_pressed(blank: int) -> void:
	if _solved or _locked.has(blank):
		return
	if not _picked.is_empty():
		_place(_picked, blank)
		_picked = ""
		_set_message("prompt")
		_refresh()
		_focus_start()
	elif _placed.has(blank):
		var returned: String = _placed[blank]
		_placed.erase(blank) # back to the tray
		_refresh()
		(_chips[returned] as WordChip).grab_focus()


func _on_chip_dropped(blank: int, data: Dictionary) -> void:
	if _solved:
		return
	var chip_id := str(data.get("chip_id", ""))
	if not _chips.has(chip_id) or _locked.has(_slot_of(chip_id)):
		return
	_place(chip_id, blank)
	_picked = ""
	_set_message("prompt")
	_refresh()
	_focus_start()


func _can_return_chip(_at_position: Vector2, data: Variant) -> bool:
	if _solved or not data is Dictionary or data.get("type", "") != WordChip.DRAG_TYPE:
		return false
	var blank := _slot_of(str(data.get("chip_id", "")))
	return blank != 0 and not _locked.has(blank)


func _return_chip(_at_position: Vector2, data: Variant) -> void:
	_placed.erase(_slot_of(str((data as Dictionary).get("chip_id", ""))))
	_refresh()


func _on_submit_pressed() -> void:
	if _solved:
		completed.emit()
		return
	if _placed.size() < _slots.size():
		return
	var answers: Dictionary = _report.get("answers", {})
	var first_wrong := "" # the first wrong word, so the message can say why it does not fit
	for slot in _slots:
		var n := slot.slot_number
		if _locked.has(n):
			continue
		if _placed[n] == str(answers.get(str(n), "")):
			_locked[n] = true
		else:
			_mistakes += 1
			if first_wrong.is_empty():
				first_wrong = _placed[n]
			_placed.erase(n) # the word goes back to the tray
	_picked = ""
	if _locked.size() == _slots.size():
		_solved = true
		_set_message("solved")
	else:
		var values := {"right": _locked.size(), "total": _slots.size(), "reason": _reason_for(first_wrong)}
		_set_message("none_right" if _locked.is_empty() else "some_wrong", values)
	_refresh()
	_focus_start()


## Why a wrong word does not fit: the word's own "reason" in the data, or a general line for a
## real clue that was put in the wrong blank.
func _reason_for(chip_id: String) -> String:
	var reason := str(_reasons.get(chip_id, ""))
	if not reason.is_empty():
		return reason
	var misplaced := str(_report.get("messages", {}).get("misplaced", ""))
	return misplaced.replace("{word}", str(_chips[chip_id].chip_label))


## Keyboard focus starts on the first word still in the tray (the one thing to do next), or on
## the button when everything is placed.
func _focus_start() -> void:
	if not _submit_button.disabled and (_solved or _placed.size() == _slots.size()):
		_submit_button.grab_focus()
		return
	for child in _tray.get_children():
		if child is WordChip and child.visible:
			child.grab_focus()
			return


func _focus_first_empty_blank() -> void:
	for slot in _slots:
		if not slot.locked and slot.chip_id.is_empty():
			slot.grab_focus()
			return
	# every blank is full: the picked word will replace the word in the first open one
	for slot in _slots:
		if not slot.locked:
			slot.grab_focus()
			return
