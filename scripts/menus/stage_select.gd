extends Control

@onready var stage_select: Control = $"."
@onready var new_game_button: Button = $NinePatchRect/NewGameButton
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var day_list: VBoxContainer = $"NinePatchRect/ScrollContainer/Panel/Day List"

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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_exit_pressed() -> void:
	animation_player.play_backwards("stage_select_animation")
	await animation_player.animation_finished
	stage_select.hide()


func _on_day_pressed(day: int) -> void:
	GameState.set_day(day)


func _on_new_game_button_pressed() -> void:
	if not GameState.has_day():
		return # this day is not built yet
	new_game_button.disabled = true
	GameState.reset_progress()
	SceneManager.load_scene(GAMEPLAY_SCENE)
