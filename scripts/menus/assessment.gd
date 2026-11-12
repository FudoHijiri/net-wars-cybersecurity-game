class_name AssessmentScreen
extends Control
## The pre-game and the post-game assessment (autoload Assessment has the questions and keeps the results).
## Before the first day (the pre-test): what the study is, an alias and the player's agreement, then the 12 scenario
## questions. After the last day (the post-test): the same questions again, and then the feedback form (ratings from 1 to
## 5 about the game, data/feedback.json). The screen never says which answer is right.
## The screen is made in code, so the look follows the other menus; the scene has only this script.

const FONT := preload("res://assets/font/Press Start 8p/PressStart2P.ttf") # the text of the questions (8 pixels, the font of the dialogue)
const FONT_SMALL := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BACK := Color(0.101960786, 0.10980392, 0.17254902)
const LINE := Color(0.3372549, 0.42352942, 0.5254902)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275)
const MUTED := Color(0.58, 0.69, 0.76)
const GOLD := Color(1, 0.8039216, 0.45882353)
const GREEN := Color(0.654902, 0.9411765, 0.4392157)
const RED := Color(0.9372549, 0.49019608, 0.34117648)
const BODY := 8
const PER_PAGE := 4 # statements of the feedback form on one page

var _phase := "pre"
var _run: Array[Dictionary] = []
var _answers: Array[Dictionary] = []
var _index := 0
var _picked := -1 # the option shown at this place that is picked, or -1
var _asked_at := 0 # msec when the question was shown
var _result: Dictionary = {}
var _fb_pages: Array = [] # the feedback items, PER_PAGE to a page
var _fb_page := 0
var _fb_values: Dictionary = {} # item id -> the rating 1 to 5

var _title: Label
var _progress: Label
var _bar: ColorRect
var _bar_back: ColorRect
var _intro: Control
var _question: Control
var _done: Control
var _feedback: Control
var _who: Control
var _fb_box: Control
var _fb_comment_title: Label
var _fb_comment: LineEdit
var _next: Button
var _hint: Label
var _alias_edit: LineEdit
var _alias_note: Label
var _agree: CheckBox
var _intro_text: RichTextLabel
var _scenario: RichTextLabel
var _options: Array[Button] = []
var _option_group := ButtonGroup.new()
var _done_text: RichTextLabel
var _status: Label
var _retry: Button


func _ready() -> void:
	_phase = Assessment.current_phase()
	_build()
	if _phase == "pre" and Assessment.alias().is_empty() and not Assessment.profile_list().is_empty():
		_show_who() # somebody has played on this computer: is it this player?
	else:
		_show_intro()
	Assessment.status_changed.connect(_refresh_status)


# --- the pages ---

## A new save slot on a computer that already knows some players: "who is playing?". Picking an alias takes over what that
## player did (the pre-test is not asked again and nothing is sent again); "I am new" goes to the pre-test.
func _show_who() -> void:
	_set_page(_who)
	_title.text = "%s  -  WHO IS PLAYING?" % Assessment.title
	_progress.text = ""
	_bar.size.x = 0.0
	for child in _who.get_children():
		_who.remove_child(child)
		child.queue_free()
	var note := _rich(Vector2(0, 0), Vector2(576, 44))
	note.text = "Somebody has already answered the questions on this computer. If that was you, pick your alias: you will not be asked again."
	_who.add_child(note)
	var y := 52.0
	for profile: Dictionary in Assessment.profile_list():
		var done: Array[String] = []
		for phase in ["pre", "post", "feedback"]:
			if profile.has(phase):
				done.append(phase)
		var row := _button("I AM  %s   (%s done)" % [profile["alias"], ", ".join(done)], Vector2(0, y), Vector2(576, 24))
		row.name = "Profile%d" % (y as int)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_color_override("font_color", TEXT)
		row.add_theme_color_override("font_hover_color", GOLD)
		row.add_theme_stylebox_override("normal", _box(BACK, LINE, 4))
		row.add_theme_stylebox_override("hover", _box(Color(0.24, 0.2, 0.12), GOLD, 4))
		row.add_theme_stylebox_override("pressed", _box(Color(0.24, 0.2, 0.12), GOLD, 4))
		row.pressed.connect(_on_profile_picked.bind(str(profile["alias"])))
		_who.add_child(row)
		y += 28.0
	var fresh := _button("I AM NEW HERE", Vector2(0, y + 6.0), Vector2(576, 24))
	fresh.name = "NewPlayerButton"
	fresh.pressed.connect(_show_intro)
	_who.add_child(fresh)
	_next.hide()
	_hint.text = "Someone else's alias is not yours: pick \"I am new here\" and choose your own alias."


func _on_profile_picked(chosen: String) -> void:
	Assessment.adopt(chosen)
	_next.show()
	if Assessment.needs_pre():
		_show_intro()
	elif not Assessment.open_if_due(false):
		SceneManager.load_stage_select()


func _show_intro() -> void:
	_next.show()
	_set_page(_intro)
	_title.text = "%s  -  %s" % [Assessment.title, "BEFORE YOU PLAY" if _phase == "pre" else "AFTER YOU PLAYED"]
	if _phase == "feedback":
		_title.text = "%s  -  TELL US WHAT YOU THINK" % Assessment.feedback_title
	_progress.text = ""
	_bar.size.x = 0.0
	if _phase == "pre":
		_intro_text.text = "Before you play, answer %d short questions about computer security. There is no pass or fail: choose what you would really do.\n\nYour alias and your answers are sent to the researchers of this study. Nothing else about you is sent. You may use an alias, not your real name." % Assessment.questions.size()
		_alias_edit.show()
		_alias_note.show()
		_agree.show()
	elif _phase == "feedback":
		_intro_text.text = "Last step, %s.\n\nRate %d statements about the game from 1 to 5, and write a comment if you want to. It takes about two minutes. Your ratings are sent to the researchers of this study, with your alias." % [Assessment.alias(), Assessment.feedback_items.size()]
		_alias_edit.hide()
		_alias_note.hide()
		_agree.hide()
	else:
		_intro_text.text = "Welcome back, %s.\n\nThese are the same %d questions as before the game, in a different order. Answer what you would really do now. Your answers are sent to the researchers of this study." % [Assessment.alias(), Assessment.questions.size()]
		_alias_edit.hide()
		_alias_note.hide()
		_agree.hide()
	_next.text = "START"
	_hint.text = ""
	_update_start()
	if _phase == "pre":
		_alias_edit.grab_focus()
	else:
		_next.grab_focus()


func _update_start() -> void:
	if _phase != "pre":
		_next.disabled = false
		return
	var alias_ok := Assessment.alias_ok(_alias_edit.text) and not Assessment.alias_taken(_alias_edit.text)
	if _alias_edit.text.is_empty() or alias_ok:
		_alias_note.text = ""
	elif Assessment.alias_ok(_alias_edit.text):
		_alias_note.text = "Somebody on this computer already uses this alias. Choose another one."
	else:
		_alias_note.text = "Use %d to %d letters, digits, spaces, dots, dashes or underscores." % [Assessment.ALIAS_MIN, Assessment.ALIAS_MAX]
	_next.disabled = not (alias_ok and _agree.button_pressed)
	_hint.text = "" if not _next.disabled else "Write an alias and tick the box to start."


func _start_questions() -> void:
	_run = Assessment.new_run()
	_answers.clear()
	_index = 0
	_show_question()


func _show_question() -> void:
	_set_page(_question)
	var item := _run[_index]
	_progress.text = "QUESTION %d / %d" % [_index + 1, _run.size()]
	_bar.size.x = _bar_back.size.x * float(_index) / float(_run.size())
	_scenario.text = item["scenario"]
	var options: Array = item["options"]
	for i in _options.size():
		_options[i].text = "%s   %s" % ["ABCD"[i], options[i]["text"]]
		_options[i].set_pressed_no_signal(false)
	_picked = -1
	_next.text = "SUBMIT" if _index == _run.size() - 1 else "CONTINUE"
	_next.disabled = true
	_hint.text = "Pick an answer (or press 1 to 4)."
	_asked_at = Time.get_ticks_msec()


func _pick(slot: int) -> void:
	_picked = slot
	_options[slot].set_pressed_no_signal(true)
	_next.disabled = false
	_hint.text = ""


func _on_next() -> void:
	if _next.disabled:
		return
	if _intro.visible:
		if _phase == "pre":
			Assessment.record()["alias"] = Assessment.clean_alias(_alias_edit.text)
		if _phase == "feedback":
			_start_feedback()
		else:
			_start_questions()
	elif _feedback.visible:
		_fb_page += 1
		if _fb_page < _fb_pages.size():
			_show_feedback_page()
		else:
			_finish_feedback()
	elif _question.visible:
		var item := _run[_index]
		_answers.append({"q": item["id"], "choice": int(item["options"][_picked]["index"]), "ms": Time.get_ticks_msec() - _asked_at})
		_index += 1
		if _index < _run.size():
			_show_question()
		else:
			_finish()
	elif _done.visible:
		if Assessment.needs_feedback(): # the post-test is done: the feedback form comes next
			_phase = "feedback"
			_show_intro()
		else:
			SceneManager.load_stage_select()


func _finish() -> void:
	var alias := Assessment.clean_alias(_alias_edit.text) if _phase == "pre" else Assessment.alias()
	_result = Assessment.submit(_phase, alias, _answers)
	_set_page(_done)
	_progress.text = ""
	_bar.size.x = _bar_back.size.x
	if _phase == "pre":
		_done_text.text = "Thank you, %s. Your answers are saved.\n\nNow play. When you finish the last day (or when the researchers tell you to), the same questions will come once more." % _result["alias"]
	else:
		var before: Dictionary = Assessment.record().get("pre", {})
		_done_text.text = "Thank you, %s.\n\nYou answered %d of %d correctly now" % [_result["alias"], _result["score"], _result["total"]]
		if not before.is_empty():
			_done_text.text += ", and %d of %d before the game." % [before["score"], before["total"]]
		else:
			_done_text.text += "."
		_done_text.text += "\n\nNext: a short feedback form about the game."
	_next.text = "CONTINUE"
	_next.disabled = false
	_hint.text = ""
	_refresh_status()


# --- the feedback form ---

func _start_feedback() -> void:
	_fb_pages.clear()
	_fb_values.clear()
	var items: Array = Assessment.feedback_items
	for i in range(0, items.size(), PER_PAGE):
		_fb_pages.append(items.slice(i, i + PER_PAGE))
	_fb_page = 0
	_show_feedback_page()


func _show_feedback_page() -> void:
	_set_page(_feedback)
	_progress.text = "PAGE %d / %d" % [_fb_page + 1, _fb_pages.size()]
	_bar.size.x = _bar_back.size.x * float(_fb_page) / float(_fb_pages.size())
	for child in _fb_box.get_children():
		_fb_box.remove_child(child)
		child.queue_free()
	var parts: Array[String] = []
	for i in Assessment.scale.size():
		parts.append("%d %s" % [i + 1, Assessment.scale[i]])
	_fb_box.add_child(_label("   ".join(parts), Vector2(0, 0), 6, MUTED, FONT_SMALL))
	var y := 16.0
	for item: Dictionary in _fb_pages[_fb_page]:
		var statement := _label(str(item["text"]), Vector2(0, y), BODY, TEXT)
		statement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		statement.custom_minimum_size = Vector2(576, 0)
		statement.size = Vector2(576, 22)
		_fb_box.add_child(statement)
		var group := ButtonGroup.new()
		for value in 5:
			var rate := Button.new()
			rate.name = "Rate%d" % (value + 1)
			rate.text = str(value + 1)
			rate.toggle_mode = true
			rate.button_group = group
			rate.focus_mode = Control.FOCUS_NONE
			rate.position = Vector2(value * 48.0, y + 24.0)
			rate.size = Vector2(42, 20)
			rate.add_theme_font_override("font", FONT)
			rate.add_theme_font_size_override("font_size", BODY)
			rate.add_theme_color_override("font_color", TEXT)
			rate.add_theme_color_override("font_hover_color", TEXT)
			rate.add_theme_color_override("font_pressed_color", GOLD)
			rate.add_theme_color_override("font_hover_pressed_color", GOLD)
			rate.add_theme_stylebox_override("normal", _box(BACK, LINE, 3))
			rate.add_theme_stylebox_override("hover", _box(Color(0.17, 0.19, 0.28), TEXT, 3))
			rate.add_theme_stylebox_override("pressed", _box(Color(0.24, 0.2, 0.12), GOLD, 3))
			rate.add_theme_stylebox_override("hover_pressed", _box(Color(0.24, 0.2, 0.12), GOLD, 3))
			if int(_fb_values.get(str(item["id"]), 0)) == value + 1:
				rate.set_pressed_no_signal(true)
			rate.pressed.connect(_rate.bind(str(item["id"]), value + 1))
			_fb_box.add_child(rate)
		y += 58.0
	var last := _fb_page == _fb_pages.size() - 1
	_fb_comment_title.visible = last
	_fb_comment.visible = last
	if last:
		_fb_comment_title.text = Assessment.comment_prompt
		_fb_comment_title.position.y = y + 4.0
		_fb_comment.position.y = y + 18.0
	_next.text = "SUBMIT" if last else "CONTINUE"
	_update_feedback_next()


func _rate(id: String, value: int) -> void:
	_fb_values[id] = value
	_update_feedback_next()


func _update_feedback_next() -> void:
	var missing := 0
	for item: Dictionary in _fb_pages[_fb_page]:
		if not _fb_values.has(str(item["id"])):
			missing += 1
	_next.disabled = missing > 0
	_hint.text = "Rate every statement to go on (%d left)." % missing if missing > 0 else ""


func _finish_feedback() -> void:
	var ratings: Array = []
	for item: Dictionary in Assessment.feedback_items:
		ratings.append({"q": str(item["id"]), "value": int(_fb_values[str(item["id"])])})
	_result = Assessment.submit_feedback(ratings, _fb_comment.text)
	_set_page(_done)
	_progress.text = ""
	_bar.size.x = _bar_back.size.x
	_done_text.text = "Thank you, %s. That was the last part of the study.\n\nYou can keep playing if you like." % _result["alias"]
	_next.text = "CONTINUE"
	_next.disabled = false
	_hint.text = ""
	_refresh_status()


func _refresh_status() -> void:
	if not is_instance_valid(_status) or not _done.visible:
		return
	_retry.visible = false
	match Assessment.status:
		"sending":
			_status.text = "Sending your answers..."
			_status.add_theme_color_override("font_color", MUTED)
		"sent":
			_status.text = "Your answers were sent to the study. Thank you!"
			_status.add_theme_color_override("font_color", GREEN)
		"waiting":
			_status.text = "Could not send your answers yet. They are saved here and are sent again later, when there is a connection."
			_status.add_theme_color_override("font_color", RED)
			_retry.visible = true
		"off":
			_status.text = "Your answers are saved on this computer."
			_status.add_theme_color_override("font_color", MUTED)
		_:
			_status.text = ""


func _set_page(page: Control) -> void:
	for p: Control in [_intro, _question, _done, _feedback, _who]:
		p.visible = p == page


# --- keys ---

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if _question.visible and key.keycode >= KEY_1 and key.keycode <= KEY_4:
		_pick(key.keycode - KEY_1)
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		_on_next()
		get_viewport().set_input_as_handled()


# --- the build ---

func _build() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = BACK
	back.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var card := Panel.new()
	card.add_theme_stylebox_override("panel", _box(BACK, LINE))
	card.position = Vector2(20, 12)
	card.size = Vector2(600, 336)
	add_child(card)
	_title = _label("", Vector2(32, 20), 8, GOLD)
	add_child(_title)
	_progress = _label("", Vector2(380, 20), BODY, MUTED)
	_progress.size = Vector2(228, 14)
	_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_progress)
	_bar_back = ColorRect.new()
	_bar_back.color = Color(0.17, 0.19, 0.28)
	_bar_back.position = Vector2(32, 40)
	_bar_back.size = Vector2(576, 3)
	add_child(_bar_back)
	_bar = ColorRect.new()
	_bar.color = GOLD
	_bar.position = _bar_back.position
	_bar.size = Vector2(0, 3)
	add_child(_bar)

	_intro = _page()
	_intro_text = _rich(Vector2(0, 0), Vector2(576, 130))
	_intro.add_child(_intro_text)
	_alias_note = _label("", Vector2(0, 148), 6, RED, FONT_SMALL)
	_alias_note.size = Vector2(576, 10)
	_intro.add_child(_alias_note)
	_alias_edit = LineEdit.new()
	_alias_edit.placeholder_text = "Your alias"
	_alias_edit.max_length = Assessment.ALIAS_MAX
	_alias_edit.position = Vector2(0, 118)
	_alias_edit.size = Vector2(260, 24)
	_alias_edit.add_theme_font_override("font", FONT)
	_alias_edit.add_theme_font_size_override("font_size", BODY)
	_alias_edit.add_theme_stylebox_override("normal", _box(Color(0.07, 0.08, 0.13), LINE, 4))
	_alias_edit.add_theme_stylebox_override("focus", _box(Color(0.07, 0.08, 0.13), GOLD, 4))
	_alias_edit.text_changed.connect(func(_t: String) -> void: _update_start())
	_alias_edit.text_submitted.connect(func(_t: String) -> void: _on_next())
	_intro.add_child(_alias_edit)
	_agree = CheckBox.new()
	_agree.text = "I agree that my alias and answers are sent to the study."
	_agree.position = Vector2(0, 166)
	_agree.add_theme_font_override("font", FONT)
	_agree.add_theme_font_size_override("font_size", BODY)
	_agree.add_theme_color_override("font_color", TEXT)
	_agree.toggled.connect(func(_on: bool) -> void: _update_start())
	_intro.add_child(_agree)

	_question = _page()
	_scenario = _rich(Vector2(0, 0), Vector2(576, 62))
	_question.add_child(_scenario)
	for i in 4:
		var option := Button.new()
		option.name = "Choice%d" % (i + 1)
		option.toggle_mode = true
		option.button_group = _option_group
		option.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option.focus_mode = Control.FOCUS_NONE # the keys 1 to 4 and the mouse choose
		option.position = Vector2(0, 66 + i * 49)
		option.size = Vector2(576, 45)
		option.add_theme_font_override("font", FONT)
		option.add_theme_font_size_override("font_size", BODY)
		option.add_theme_constant_override("line_spacing", 3)
		option.add_theme_color_override("font_color", TEXT)
		option.add_theme_color_override("font_hover_color", TEXT)
		option.add_theme_color_override("font_pressed_color", GOLD)
		option.add_theme_color_override("font_hover_pressed_color", GOLD)
		option.add_theme_stylebox_override("normal", _box(BACK, LINE, 5))
		option.add_theme_stylebox_override("hover", _box(Color(0.17, 0.19, 0.28), TEXT, 5))
		option.add_theme_stylebox_override("pressed", _box(Color(0.24, 0.2, 0.12), GOLD, 5))
		option.add_theme_stylebox_override("hover_pressed", _box(Color(0.24, 0.2, 0.12), GOLD, 5))
		option.pressed.connect(_pick.bind(i))
		_question.add_child(option)
		_options.append(option)

	_done = _page()
	_done_text = _rich(Vector2(0, 0), Vector2(576, 110))
	_done.add_child(_done_text)
	_status = _label("", Vector2(0, 90), BODY, MUTED)
	_status.size = Vector2(576, 40)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_done.add_child(_status)
	_retry = _button("TRY TO SEND AGAIN", Vector2(0, 140), Vector2(200, 22))
	_retry.pressed.connect(Assessment.flush)
	_retry.hide()
	_done.add_child(_retry)

	_who = _page()
	_feedback = _page()
	_fb_box = Control.new()
	_feedback.add_child(_fb_box)
	_fb_comment_title = _label("", Vector2(0, 0), 6, MUTED, FONT_SMALL)
	_feedback.add_child(_fb_comment_title)
	_fb_comment = LineEdit.new()
	_fb_comment.max_length = Assessment.COMMENT_MAX
	_fb_comment.size = Vector2(576, 22)
	_fb_comment.add_theme_font_override("font", FONT)
	_fb_comment.add_theme_font_size_override("font_size", BODY)
	_fb_comment.add_theme_stylebox_override("normal", _box(Color(0.07, 0.08, 0.13), LINE, 4))
	_fb_comment.add_theme_stylebox_override("focus", _box(Color(0.07, 0.08, 0.13), GOLD, 4))
	_feedback.add_child(_fb_comment)

	_hint = _label("", Vector2(32, 322), 6, MUTED, FONT_SMALL)
	_hint.size = Vector2(380, 12)
	add_child(_hint)
	_next = _button("CONTINUE", Vector2(488, 316), Vector2(120, 24))
	_next.name = "ContinueButton"
	_next.pressed.connect(_on_next)
	add_child(_next)


func _page() -> Control:
	var page := Control.new()
	page.position = Vector2(32, 52)
	page.size = Vector2(576, 256)
	add_child(page)
	return page


func _label(text: String, at: Vector2, font_size: int, color: Color, font: Font = FONT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _rich(at: Vector2, box_size: Vector2) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.position = at
	rich.size = box_size
	rich.scroll_active = false
	rich.bbcode_enabled = false
	rich.add_theme_font_override("normal_font", FONT)
	rich.add_theme_font_size_override("normal_font_size", BODY)
	rich.add_theme_color_override("default_color", TEXT)
	rich.add_theme_constant_override("line_separation", 4)
	return rich


func _button(text: String, at: Vector2, box_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = box_size
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", BODY)
	button.add_theme_color_override("font_color", BACK)
	button.add_theme_color_override("font_hover_color", BACK)
	button.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.58))
	button.add_theme_stylebox_override("normal", _box(Color(0.45, 0.8, 0.85), Color(0.45, 0.8, 0.85), 3))
	button.add_theme_stylebox_override("hover", _box(Color(0.6, 0.9, 0.95), TEXT, 3))
	button.add_theme_stylebox_override("pressed", _box(Color(0.3, 0.6, 0.65), TEXT, 3))
	button.add_theme_stylebox_override("disabled", _box(Color(0.17, 0.19, 0.28), LINE, 3))
	return button


static func _box(fill: Color, border: Color, margin: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(1)
	style.border_color = border
	style.set_content_margin_all(margin)
	return style
