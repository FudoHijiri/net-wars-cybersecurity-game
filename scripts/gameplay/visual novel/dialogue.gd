extends CanvasLayer

## Optional. Leave empty and the current day (GameState.current_day, see data/days.json) decides
## which dialogue to play and which scene comes next. Fill it in to play one file on its own.
@export_file("*.json") var jsonsrc: String = ""

var _finished := false

var scene_script : Dictionary
var current_block : Dictionary
var next_block : Dictionary

@export_category("scene reference")
@export var char_text : RichTextLabel
@export var char_name : Label
@export var char_sprite : TextureRect

@export var BaseLayer: CanvasLayer
@export var ChoiceLayer : CanvasLayer


func _ready() -> void:
	get_json(jsonsrc if not jsonsrc.is_empty() else str(GameState.day_info().get("dialogue", "")))
	load_block(current_block)


func get_json(src: String):
	var jsontext = FileAccess.get_file_as_string(src)
	scene_script = JSON.parse_string(jsontext)
	current_block = scene_script["start"]


func load_block(block : Dictionary):
	if block.has("text"): char_text.text = block["text"]
	if block.has("name"): char_name.text = block["name"]
	
	if block.has("next"): 
		var key = block["next"]
		next_block = scene_script[key]
		
	if block.has("choices"):
		ChoiceLayer.show()
		ChoiceLayer.set_choices(block["choices"])
	pass
	
	if block.has("trigger"):
		if block["trigger"] == "start_investigation":
			_finished = true
			SceneManager.load_scene(str(GameState.day_info().get("investigation_scene", "")))


func next():
	if _finished or ChoiceLayer.visible:
		return
	current_block = next_block
	load_block(current_block)
	

func _input(event: InputEvent)->void:
	if event.is_action_pressed("ui_accept"):
		next()
		
	


func _on_choices_next_id(id: String) -> void:
	next_block = scene_script[id]
	next()
	ChoiceLayer.hide()
