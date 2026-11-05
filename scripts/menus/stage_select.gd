extends Control

@onready var stage_select: Control = $"."
@onready var new_game_button: Button = $NinePatchRect/NewGameButton
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var day_list: VBoxContainer = $"NinePatchRect/ScrollContainer/Panel/Day List"
@onready var book_animation: AnimatedSprite2D = $"../BookArchive/Node2D/BookAnimation"
@onready var book_content: Control = $"../BookArchive/Content"
@onready var book_archive: Control = $"../BookArchive"
@onready var resume_button: Button = $NinePatchRect/PlayButton # its label says RESUME

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
