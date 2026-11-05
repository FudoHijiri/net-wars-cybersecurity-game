extends Node

@onready var main_content: Control = $MainContent
@onready var save_select: SaveSelect = $MainContent/SaveSelect
@onready var stage_select: Control = $"MainContent/StageSelect"
@onready var animation_player: AnimationPlayer = $"MainContent/AnimationPlayer"
@onready var exit_confirmation: NinePatchRect = $"MainContent/ExitConfirmation"
@onready var book_archive: Control = $MainContent/BookArchive


func _ready() -> void:
	stage_select.hide()
	exit_confirmation.hide()
	book_archive.hide()
	if SceneManager.open_stage_select:
		SceneManager.open_stage_select = false
		_show_stage_select_now()
	# The offset transform only moves a control visually; its click area stays put. A full-screen
	# panel parked off screen would still swallow the clicks meant for the title buttons, so the
	# save slots stay hidden until one of the slide animations brings them in.
	save_select.hide()
	animation_player.animation_started.connect(_on_animation_started)
	save_select.slot_chosen.connect(_on_slot_chosen)
	save_select.exit_requested.connect(_on_save_select_exit_requested)


## Nothing on the title takes a mouse click while one of its animations is playing. The panels
## are already under the cursor halfway through a slide, so an early click would press whatever
## ends up there (a save slot, for example).
func _process(_delta: float) -> void:
	main_content.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED if animation_player.is_playing() \
			else Control.MOUSE_BEHAVIOR_INHERITED


func _on_animation_started(animation: StringName) -> void:
	if animation == &"save_select_animation" or animation == &"stage_select_animation":
		save_select.show()


## A save slot was picked: slide from the slots to the day select.
func _on_slot_chosen(_slot: int) -> void:
	stage_select.show()
	animation_player.play("stage_select_animation")
	await animation_player.animation_finished
	save_select.unlock()


## Exit on the slots: slide back to the title and hide them, so they stop taking clicks.
func _on_save_select_exit_requested() -> void:
	animation_player.play_backwards("save_select_animation")
	await animation_player.animation_finished
	save_select.hide()


## Jumps to the end of the two slide animations (title to save slots, save slots to day select).
func _show_stage_select_now() -> void:
	stage_select.show()
	for animation: StringName in [&"save_select_animation", &"stage_select_animation"]:
		animation_player.play(animation)
		animation_player.seek(animation_player.current_animation_length, true)


func _on_play_button_pressed() -> void:
	animation_player.play("save_select_animation")
	await animation_player.animation_finished


func _on_settings_button_pressed() -> void:
	SceneManager.fade_through(Settings.open) # covers the whole screen: fade out, open, fade in


func _on_exit_button_pressed() -> void:
	exit_confirmation.show()
	animation_player.play("exit_confirmation")
	await animation_player.animation_finished


func _on_yes_button_pressed() -> void:
	get_tree().quit()



func _on_no_button_pressed() -> void:
	animation_player.play_backwards("exit_confirmation")
	await animation_player.animation_finished
	exit_confirmation.hide()
