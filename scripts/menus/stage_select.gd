extends Control

@onready var stage_select: Control = $"."
@onready var new_game_button: Button = $NinePatchRect/NewGameButton
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var day_list: VBoxContainer = $"NinePatchRect/ScrollContainer/Panel/Day List"
@onready var book_animation: AnimatedSprite2D = $"../BookArchive/Node2D/BookAnimation"
@onready var book_content: Control = $"../BookArchive/Content"
@onready var book_archive: Control = $"../BookArchive"
@onready var resume_button: Button = $NinePatchRect/PlayButton # its label says RESUME
@onready var open_deck_button: Button = $NinePatchRect/OpenDeckButton

const GAMEPLAY_SCENE := "uid://3c7f3ifrv4i1" # the day's dialogue; it hands over to the investigation

var _study_menu: StudyMenu # the small Study button and its pop-up
var _day1_text := "" # the description written in the scene for Day 1 (days.json has none for it)
var _chosen_slot := -2 # the slot whose day was chosen for the player; it is chosen again when the slot changes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Day buttons are in order: the first is day 1, the next day 2, and so on.
	var day := 1
	for button in day_list.get_children():
		if button is Button:
			button.pressed.connect(_on_day_pressed.bind(day))
		day += 1
	var description := get_node_or_null("NinePatchRect/PanelContainer/Day Description") as RichTextLabel
	if description != null:
		_day1_text = description.text
	GameState.set_day(1)
	_refresh_days()
	resume_button.pressed.connect(_on_resume_pressed)
	open_deck_button.pressed.connect(_on_open_deck_pressed)
	visibility_changed.connect(_refresh_resume) # the slot may have changed since the last time
	_study_menu = StudyMenu.new()
	add_child(_study_menu)
	_study_menu.setup(get_node_or_null("../CreditsButton") as Button) # at the edge, like Credits in the title menu


func _on_exit_pressed() -> void:
	Music.play(&"title")
	animation_player.play_backwards("stage_select_animation")
	await animation_player.animation_finished
	stage_select.hide()


func _on_day_pressed(day: int) -> void:
	GameState.set_day(day)
	_show_description(day)
	_update_resume() # RESUME is for the day chosen


## A day opens when it is built and the day before it is finished in the loaded slot (Day 1 is always open).
func is_day_open(day: int) -> bool:
	if not GameState.has_day(day):
		return false
	if day == 1:
		return true
	if SaveManager.current_slot < 0:
		return false
	for phase: String in GameState.PHASES:
		if not SaveManager.is_phase_complete(day - 1, phase):
			return false
	return true


## Day buttons: open or closed by progress, named from days.json.
func _refresh_days() -> void:
	var day := 1
	for button in day_list.get_children():
		if button is Button:
			var info := GameState.day_info(day)
			if not info.is_empty():
				button.text = "Day %d - %s" % [day, str(info.get("title", ""))]
			button.disabled = not is_day_open(day)
		day += 1


## The text beside the list for the day chosen (Day 1 keeps the text written in the scene).
func _show_description(day: int) -> void:
	var blurb := str(GameState.day_info(day).get("blurb", ""))
	if blurb.is_empty():
		var first := get_node_or_null("NinePatchRect/PanelContainer/Day Description") as RichTextLabel
		if first != null and not _day1_text.is_empty():
			first.text = _day1_text
		return
	var label := get_node_or_null("NinePatchRect/PanelContainer/Day Description") as RichTextLabel
	if label != null:
		label.text = " Day %d - %s\n\n%s\n" % [day, str(GameState.day_info(day).get("title", "")), blurb]


## RESUME continues the chosen day where the player last played on it (the first phase of that day not finished).
## It is off when the day was finished, or was not started (NEW GAME starts it). The hover text says why or where.
func _refresh_resume() -> void:
	if not is_visible_in_tree():
		return
	_refresh_days()
	_choose_first_day()
	_update_resume()
	_study_menu.refresh()
	Assessment.flush() # a result that could not be sent before is tried again
	open_deck_button.disabled = _deck_day() == 0
	if not resume_button.disabled:
		UiFx.hop(resume_button) # the way on is the one that jumps


## The RESUME button for the day chosen.
func _update_resume() -> void:
	var day := GameState.current_day
	var point := SaveManager.day_resume_point(day) if SaveManager.current_slot >= 0 else {}
	resume_button.disabled = point.is_empty() or not GameState.is_phase_built(point["phase"], day)
	if not resume_button.disabled:
		resume_button.tooltip_text = "Day %d - %s" % [day, str(point["phase"]).capitalize()]
	elif SaveManager.current_slot >= 0 and SaveManager.is_day_complete(day):
		resume_button.tooltip_text = "Day %d is finished" % day
	else:
		resume_button.tooltip_text = "Day %d was not started. NEW GAME starts it." % day


## When a slot is opened (or the scene is), the day it is at is chosen for the player, so RESUME continues it:
## the first day with a phase not finished, or the last open day when everything is.
func _choose_first_day() -> void:
	if SaveManager.current_slot == _chosen_slot:
		return
	_chosen_slot = SaveManager.current_slot
	if SaveManager.current_slot < 0:
		return
	var day := int(SaveManager.resume_point()["day"])
	while day > 1 and not is_day_open(day):
		day -= 1
	GameState.set_day(day)
	_show_description(day)


## The day whose Hardening OPEN DECK opens: the day the save is at, or the last built one before it.
## 0 when there is none, or no slot is loaded (nothing could be saved).
func _deck_day() -> int:
	if SaveManager.current_slot < 0:
		return 0
	for day in range(int(SaveManager.resume_point()["day"]), 0, -1):
		if not str(GameState.phase_info("hardening", day).get("scene", "")).is_empty():
			return day
	return 0


## Opens the deck and upgrade screens on their own, without the shop or the rest of the phase.
func _on_open_deck_pressed() -> void:
	var day := _deck_day()
	if open_deck_button.disabled or day == 0:
		return
	open_deck_button.disabled = true
	resume_button.disabled = true
	new_game_button.disabled = true
	GameState.reset_progress()
	GameState.set_day(day)
	GameState.set_phase("hardening")
	SceneManager.build_only = true
	SceneManager.load_scene(str(GameState.phase_info()["scene"]))


## Continues the slot at the first phase it has not finished: the dialogue before that phase, then the phase.
func _on_resume_pressed() -> void:
	if resume_button.disabled:
		return
	var day := GameState.current_day
	var point := SaveManager.day_resume_point(day)
	if point.is_empty():
		return
	resume_button.disabled = true
	new_game_button.disabled = true
	GameState.reset_progress() # clues and the rest of the run start clean, as in a new game
	GameState.set_day(day)
	GameState.set_phase(point["phase"])
	SceneManager.open_current_phase()


func _on_new_game_button_pressed() -> void:
	if not GameState.has_day():
		return # this day is not built yet
	new_game_button.disabled = true
	GameState.reset_progress()
	SceneManager.load_scene(GAMEPLAY_SCENE)


func _on_archive_button_pressed() -> void:
	Music.play(&"archive")
	book_archive.show()
	animation_player.play("book_archive_animation")
	await animation_player.animation_finished
	stage_select.hide()
	book_animation.play()
	await book_animation.animation_finished
	book_content.show()
