extends RecoveryTask

## Power-cycle a rack in order: six units, each with a switch and a light. Stage 1, shut down from the top: the load balancer,
## the web server, the app server, the database, the network switch, the power strip. Stage 2, start up from the bottom, and wait
## for each unit's green light before the next one. A unit pressed out of its turn refuses and says what it still needs.
## Layout: RackPower.tscn (the rack is built here). content: {units: [{id, label, job}] (top to bottom), shutdown_order,
## start_order, early_off: {id: reason}, early_on: {id: reason}, wait, stage_off, stage_on, off_done, on_done, start_seconds}.

var stage := 1
var _states: Dictionary = {} # unit id -> "on", "off" or "starting"
var _index := 0 # how many units of the stage are done
var _faces: Dictionary = {}
var _buttons: Dictionary = {}
var _caption: Label
var _glow_tween: Tween
var _glowing: Control


func setup_task() -> void:
	_caption = Label.new()
	_caption.theme_type_variation = &"RecoveryAccent"
	body.add_child(_caption)
	for unit: Dictionary in content.get("units", []):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		body.add_child(row)
		var face := UnitFace.new()
		face.custom_minimum_size = Vector2(0, 19)
		face.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		face.label = str(unit["label"])
		face.job = str(unit["job"])
		row.add_child(face)
		_faces[str(unit["id"])] = face
		var button := Button.new()
		button.text = str(content.get("switch", "POWER"))
		button.custom_minimum_size = Vector2(70, 0)
		button.pressed.connect(unit_pressed.bind(str(unit["id"])))
		row.add_child(button)
		_buttons[str(unit["id"])] = button


func reset_state() -> void:
	stage = 1
	_index = 0
	for unit: Dictionary in content.get("units", []):
		_states[str(unit["id"])] = "on"
		_buttons[str(unit["id"])].disabled = false
	_refresh()
	set_feedback(str(content.get("pick", "")))


func _order() -> Array:
	return content.get("shutdown_order" if stage == 1 else "start_order", [])


func _refresh() -> void:
	for id: String in _faces:
		_faces[id].state = _states[id]
		_faces[id].queue_redraw()
	_caption.text = str(content.get("stage_off" if stage == 1 else "stage_on", ""))
	var order := _order()
	_glow(_buttons.get(str(order[_index]), null) if _index < order.size() else null)


func _glow(target: Control) -> void:
	if _glow_tween:
		_glow_tween.kill()
	if is_instance_valid(_glowing):
		_glowing.modulate = Color.WHITE
	_glowing = target
	if target == null or not is_inside_tree():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(target, "modulate", Color(1.5, 1.4, 0.85), 0.45)
	_glow_tween.tween_property(target, "modulate", Color.WHITE, 0.45)


func unit_pressed(id: String) -> void:
	if solved:
		return
	var order := _order()
	if _index >= order.size():
		return
	if stage == 1:
		if _states[id] == "off":
			return # already off
		if str(order[_index]) != id:
			note_mistake(str(content.get("early_off", {}).get(id, "")))
			return
		_states[id] = "off"
		_index += 1
		set_feedback(_unit_text(id, "off_done"), "good")
		if _index >= order.size():
			stage = 2
			_index = 0
			set_feedback(str(content.get("off_done", "")), "good")
		_refresh()
		return
	if _states[id] != "off":
		return # already on, or starting
	if str(order[_index]) != id:
		note_mistake(str(content.get("early_on", {}).get(id, "")))
		return
	if _index > 0 and _states[str(order[_index - 1])] == "starting":
		note_mistake(str(content.get("wait", "")).format({"unit": _label(str(order[_index - 1]))}))
		return
	_states[id] = "starting"
	_index += 1
	set_feedback(_unit_text(id, "on_done"), "good")
	_refresh()
	get_tree().create_timer(float(content.get("start_seconds", 0.5))).timeout.connect(_started.bind(id))


func _started(id: String) -> void:
	if solved or not is_inside_tree() or _states.get(id, "") != "starting":
		return
	_states[id] = "on"
	_refresh()
	for unit_state: String in _states.values():
		if unit_state != "on":
			return
	if stage == 2 and _index >= _order().size():
		set_feedback(str(content.get("on_done", "")), "good")
		succeed()


func _label(id: String) -> String:
	for unit: Dictionary in content.get("units", []):
		if str(unit["id"]) == id:
			return str(unit["label"])
	return id


func _unit_text(id: String, key: String) -> String:
	return str(content.get(key + "_unit", "")).format({"unit": _label(id)})


## One unit of the rack: its metal face with its name and job, and its light (red off, amber starting, green on).
class UnitFace extends Control:
	const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
	const METAL := Color(0.3372549, 0.42352942, 0.5254902, 1)
	const DARK := Color(0.101960786, 0.10980392, 0.17254902, 1)
	const LIGHT := Color(0.95686275, 0.95686275, 0.95686275, 1)
	const MUTED := Color(0.5803922, 0.6901961, 0.7607843, 1)
	var label := ""
	var job := ""
	var state := "on"

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), METAL)
		draw_rect(Rect2(Vector2.ONE, size - Vector2(2, 2)), DARK)
		draw_string(FONT, Vector2(6, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, LIGHT)
		draw_string(FONT, Vector2(112, 12), job, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
		for i in 5:
			draw_rect(Rect2(size.x - 120 + i * 6, 5, 3, 9), METAL) # the air slots
		var color := GameColors.good
		var text := "ON"
		if state == "off":
			color = GameColors.bad
			text = "OFF"
		elif state == "starting":
			color = GameColors.highlight
			text = "..."
		draw_rect(Rect2(size.x - 78, 6, 7, 7), color)
		draw_string(FONT, Vector2(size.x - 66, 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)
