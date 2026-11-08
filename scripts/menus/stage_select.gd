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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Day buttons are in order: the first is day 1, the next day 2, and so on.
	var day := 1
	for button in day_list.get_children():
		if button is Button:
			button.pressed.connect(_on_day_pressed.bind(day))
		day += 1
	GameState.set_day(1)
	resume_button.pressed.connect(_on_resume_pressed)
	open_deck_button.pressed.connect(_on_open_deck_pressed)
	visibility_changed.connect(_refresh_resume) # the slot may have changed since the last time


func _on_exit_pressed() -> void:
	animation_player.play_backwards("stage_select_animation")
	await animation_player.animation_finished
	stage_select.hide()


func _on_day_pressed(day: int) -> void:
	GameState.set_day(day)


## RESUME works when a slot is loaded and the phase it left off at has something to open. The hover text says where.
func _refresh_resume() -> void:
	if not is_visible_in_tree():
		return
	var point := SaveManager.resume_point() if SaveManager.current_slot >= 0 else {}
	resume_button.disabled = point.is_empty() or not GameState.is_phase_built(point["phase"], point["day"])
	resume_button.tooltip_text = "" if resume_button.disabled else "Day %d - %s" % [point["day"], str(point["phase"]).capitalize()]
	open_deck_button.disabled = _deck_day() == 0


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
	var point := SaveManager.resume_point()
	resume_button.disabled = true
	new_game_button.disabled = true
	GameState.reset_progress() # clues and the rest of the run start clean, as in a new game
	GameState.set_day(point["day"])
	GameState.set_phase(point["phase"])
	SceneManager.open_current_phase()


func _on_new_game_button_pressed() -> void:
	if not GameState.has_day():
		return # this day is not built yet
	new_game_button.disabled = true
	GameState.reset_progress()
	SceneManager.load_scene(GAMEPLAY_SCENE)


func _on_archive_button_pressed() -> void:
	book_archive.show()
	animation_player.play("book_archive_animation")
	await animation_player.animation_finished
	stage_select.hide()
	book_animation.play()
	await book_animation.animation_finished
	book_content.show()
