extends RecoveryTask

## Put the steps in the right order: click them one after another. A step that comes too early says why it
## has to wait (it counts as a wrong move). Layout: OrderSteps.tscn (the buttons are built here from
## content.steps, which lists them in the RIGHT order; content.shuffled is the order they are shown in).
## Used for "Wipe and rebuild the laptop" (Day 3); any later day can reuse it with other steps.

var _buttons: Dictionary = {} # step id -> Button
var _steps: Array = []
var _next := 0 # how many steps are in place


func setup_task() -> void:
	_steps = content.get("steps", [])
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("heading", ""))
	body.add_child(heading)
	for id: String in content.get("shuffled", []):
		var button := Button.new()
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_pressed.bind(id))
		body.add_child(button)
		_buttons[id] = button


func reset_state() -> void:
	_next = 0
	for id: String in _buttons:
		_buttons[id].disabled = false
		_buttons[id].text = str(_step(id).get("label", id))
	set_feedback(str(content.get("pick", "")))


func _step(id: String) -> Dictionary:
	for step: Dictionary in _steps:
		if str(step["id"]) == id:
			return step
	return {}


func _pressed(id: String) -> void:
	if solved or _next >= _steps.size():
		return
	var step := _step(id)
	if str(_steps[_next]["id"]) != id:
		UiFx.shake(_buttons[id])
		note_mistake(str(step.get("early", content.get("wrong", ""))))
		return
	_next += 1
	_buttons[id].text = "%d. %s" % [_next, step.get("label", id)]
	_buttons[id].disabled = true
	UiFx.pop(_buttons[id])
	set_feedback(str(step.get("done", "")), "good")
	if _next == _steps.size():
		succeed()
