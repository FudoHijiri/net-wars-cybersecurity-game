extends Control


## Optional. Leave empty and the current day and phase (GameState.current_day and current_phase,
## see data/days.json) decide which dialogue to play and which scene comes next. Fill it in to
## play one file on its own.
@export_file("*.json") var jsonsrc: String = ""

var _finished := false

var scene_script : Dictionary
var current_block : Dictionary
var next_block : Dictionary

@export_category("scene reference")
@export var char_text : RichTextLabel
@export var char_name : Label
@export var char_sprite : TextureRect

@export var BaseLayer: Control
@export var ChoiceLayer : CanvasLayer

@onready var _skip_button: Button = $Base/SkipButton
@onready var _day_label: Label = $Base/Banner/Day
@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _opening_cover: ColorRect = $Base/Art/Fade
@onready var _phone_sprite: TextureRect = $Base/Art/CharacterSprite2
@onready var _points_label: Label = $Base/SecurityPoints

## Blocks with one of these "art" values bring in the phone. The caller has no sprite of its own.
const PHONE_ARTS: Array[String] = ["Phone", "Client"]

var _fade: FadeText
var _phone_animation: AnimationPlayer # plays CharacterEntrance2 while Joshua keeps bobbing
var _phone_shown := false
var _pending_choices: Dictionary = {} # choices of the current block, shown on the player's next press
var _intro_done := false # clicks and keys do nothing until the opening has played


func _ready() -> void:
	_fade = FadeText.new(char_text)
	_phone_animation = AnimationPlayer.new()
	add_child(_phone_animation)
	_phone_animation.root_node = _animation.root_node
	_phone_animation.add_animation_library(&"", _animation.get_animation_library(&""))
	_day_label.text = "Day %d" % GameState.current_day
	_points_label.text = "%d SP" % GameState.wallet() # the points in the current save
	get_json(jsonsrc if not jsonsrc.is_empty() else str(GameState.phase_info().get("dialogue", "")))
	await _play_intro()
	if _finished: # Skip was pressed during the opening
		return
	load_block(current_block)


## The black cover fades out, then the character fades in and starts bobbing. The first line
## starts when the cover is gone, together with the character's entrance. The cover stays black
## until the scene loader has finished fading in. There is no closing animation: the last block
## goes straight to the next scene.
func _play_intro() -> void:
	char_text.text = "" # not the editor's placeholder text
	char_name.text = ""
	char_sprite.modulate.a = 0.0 # CharacterEntrance1 fades it in
	_phone_sprite.modulate.a = 0.0 # CharacterEntrance2 fades it in
	_opening_cover.show() # it is hidden in the scene so it doesn't hide the art in the editor
	await SceneManager.wait_for_transition()
	_animation.play(&"Opening")
	_animation.queue(&"CharacterEntrance1")
	_animation.queue(&"CharacterBobbing") # loops
	await _animation.animation_finished # the Opening
	_opening_cover.hide()
	_intro_done = true


func get_json(src: String):
	var jsontext = FileAccess.get_file_as_string(src)
	scene_script = JSON.parse_string(jsontext)
	current_block = scene_script["start"]


func load_block(block : Dictionary):
	_pending_choices = {}
	if block.has("text"): _fade.show_text(block["text"])
	if block.has("name"): char_name.text = block["name"]
	if not _phone_shown and PHONE_ARTS.has(str(block.get("art", ""))):
		_phone_shown = true
		_phone_animation.play(&"CharacterEntrance2")
	if block.has("hide_art"):
		_hide_art(str(block["hide_art"]))

	if block.has("next"):
		var key = block["next"]
		next_block = scene_script[key]
		
	if block.has("choices"):
		_pending_choices = block["choices"] # shown after the player has read the text
	pass
	
	if block.has("trigger"):
		if block["trigger"] == "start_phase": # the end of the dialogue: on to the phase itself
			_finished = true
			var scene := str(GameState.phase_info().get("scene", ""))
			if scene.is_empty():
				SceneManager.load_stage_select() # this phase is not built yet
			else:
				SceneManager.load_scene(scene)


## "hide_art" in a block names the art that leaves: its entrance plays backwards.
func _hide_art(art: String) -> void:
	if PHONE_ARTS.has(art):
		if _phone_shown:
			_phone_shown = false # a later "art": "Phone" brings it back in
			_phone_animation.play_backwards(&"CharacterEntrance2")
	elif art == "Joshua":
		_animation.play_backwards(&"CharacterEntrance1")


func next():
	if _finished or ChoiceLayer.visible:
		return
	current_block = next_block
	load_block(current_block)
	

## Skips the rest of the dialogue and goes straight to the block that starts the
## investigation. Where a block offers choices, the first one is taken.
func skip() -> void:
	if _finished:
		return
	var block := current_block
	var visited: Array[String] = []
	while not block.has("trigger"):
		var key := ""
		if block.has("next"):
			key = str(block["next"])
		elif block.has("choices"):
			key = str(block["choices"].values()[0])
		if key.is_empty() or key in visited or not scene_script.has(key):
			return # a dialogue with no trigger to skip to: leave it as it is
		visited.append(key)
		block = scene_script[key]
	ChoiceLayer.hide()
	current_block = block
	load_block(block)


## A click (left mouse button, anywhere), Space or Enter. The first one completes the text
## that is still fading in; the next one moves on to the next block, or shows the choices
## when the block has them.
func _input(event: InputEvent)->void:
	var pressed := event.is_action_pressed("ui_accept")
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		pressed = not _skip_button.get_global_rect().has_point(click.position) # Skip does its own thing
	if not pressed or not _intro_done or _finished or ChoiceLayer.visible: # the choice buttons take the clicks
		return
	get_viewport().set_input_as_handled()
	if _fade.press():
		if _pending_choices.is_empty():
			next()
		else:
			ChoiceLayer.show()
			ChoiceLayer.set_choices(_pending_choices)
			_pending_choices = {}


func _on_choices_next_id(id: String) -> void:
	next_block = scene_script[id]
	ChoiceLayer.hide() # next() does nothing while the choices are showing
	next()


# Connected to Base/SkipButton.pressed in Dialogue.tscn.
func _on_skip_button_pressed() -> void:
	skip()


# --- Debug panel (=) ---

func debug_actions() -> Array:
	return [["Skip dialogue >", skip]]
