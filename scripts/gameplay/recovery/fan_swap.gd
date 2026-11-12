extends RecoveryTask

## The flood ran the server hot for an hour, and a fan gave up. Two stages, each taught with a picture the player works on.
## Stage 1, THE ROOM: move the boxes off the air vents, set the air conditioner to a cool but sensible number, close the door;
## the thermometer falls. Stage 2, THE SERVER: shut it down, unplug it, open the case, find the fan that has stopped (the speeds
## show), put in a new fan with its arrow the right way, close up and power on. A step out of its turn bounces back with its
## reason (the machine is drawn: lid, cable, fans). Layout: FanSwap.tscn (the controls are built here). content: {room: {...}, server: {...}}.

const SLIDER_THEME := preload("res://assets/ui/slider/slider_theme.tres")

var stage := 1
var temperature := 41
var _vents_clear: Dictionary = {} # vent id -> true
var _ac_done := false
var _door_done := false
var _next := 0 # stage 2: how many steps are done
var _fan_found := ""
var _fan_new := false
var _view: Control
var _caption: Label
var _room_box: VBoxContainer
var _server_box: VBoxContainer
var _vent_buttons: Dictionary = {}
var _ac_slider: HSlider
var _ac_label: Label
var _ac_button: Button
var _door_button: Button
var _step_buttons: Dictionary = {}
var _fan_buttons: Dictionary = {}
var _air_buttons: Dictionary = {}
var _glow_tween: Tween
var _glowing: Control


func setup_task() -> void:
	_view = FanView.new()
	_view.custom_minimum_size = Vector2(0, 104)
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_view)
	_caption = Label.new()
	_caption.theme_type_variation = &"RecoveryAccent"
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_caption)
	_build_room()
	_build_server()


func _build_room() -> void:
	var room: Dictionary = content.get("room", {})
	_room_box = VBoxContainer.new()
	body.add_child(_room_box)
	var vents := HFlowContainer.new()
	_room_box.add_child(vents)
	for vent: Dictionary in room.get("vents", []):
		var button := Button.new()
		button.text = str(vent["label"])
		button.pressed.connect(vent_pressed.bind(str(vent["id"])))
		vents.add_child(button)
		_vent_buttons[str(vent["id"])] = button
	var ac := HBoxContainer.new()
	ac.add_theme_constant_override("separation", 8)
	_room_box.add_child(ac)
	_ac_label = Label.new()
	_ac_label.custom_minimum_size = Vector2(150, 0)
	ac.add_child(_ac_label)
	_ac_slider = HSlider.new()
	_ac_slider.theme = SLIDER_THEME
	_ac_slider.min_value = 5
	_ac_slider.max_value = 30
	_ac_slider.step = 1
	_ac_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ac_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ac_slider.value_changed.connect(_on_ac_changed)
	ac.add_child(_ac_slider)
	_ac_button = Button.new()
	_ac_button.text = str(room.get("ac_set", "SET THE AIR CONDITIONER"))
	_ac_button.pressed.connect(ac_pressed)
	ac.add_child(_ac_button)
	_door_button = Button.new()
	_door_button.text = str(room.get("door", {}).get("label", "Close the door"))
	_door_button.pressed.connect(door_pressed)
	_room_box.add_child(_door_button)


func _build_server() -> void:
	var server: Dictionary = content.get("server", {})
	_server_box = VBoxContainer.new()
	body.add_child(_server_box)
	var steps := HFlowContainer.new()
	_server_box.add_child(steps)
	for step: Dictionary in server.get("steps", []):
		var id := str(step["id"])
		if id == "find" or id == "install":
			continue # these two are choices, below
		var button := Button.new()
		button.text = str(step["label"])
		button.pressed.connect(step_pressed.bind(id))
		steps.add_child(button)
		_step_buttons[id] = button
	var fans := HFlowContainer.new()
	_server_box.add_child(fans)
	var fans_label := Label.new()
	fans_label.theme_type_variation = &"RecoveryMuted"
	fans_label.text = str(server.get("fans_label", "Which fan?"))
	fans.add_child(fans_label)
	for fan: Dictionary in server.get("fans", []):
		var button := Button.new()
		button.text = "%s  %s" % [fan["label"], fan["rpm_text"]]
		button.pressed.connect(fan_pressed.bind(str(fan["id"])))
		fans.add_child(button)
		_fan_buttons[str(fan["id"])] = button
	var air := HFlowContainer.new()
	_server_box.add_child(air)
	var air_label := Label.new()
	air_label.theme_type_variation = &"RecoveryMuted"
	air_label.text = str(server.get("airflow_label", "The new fan's arrow:"))
	air.add_child(air_label)
	for option: Dictionary in server.get("airflow", []):
		var button := Button.new()
		button.text = str(option["label"])
		button.pressed.connect(airflow_pressed.bind(str(option["id"])))
		air.add_child(button)
		_air_buttons[str(option["id"])] = button


func reset_state() -> void:
	stage = 1
	temperature = int(content.get("room", {}).get("temp_start", 41))
	_vents_clear.clear()
	_ac_done = false
	_door_done = false
	_next = 0
	_fan_found = ""
	_fan_new = false
	for button: Button in _vent_buttons.values():
		button.disabled = false
	_ac_slider.editable = true
	_ac_slider.set_value_no_signal(float(content.get("room", {}).get("ac_start", 30)))
	_on_ac_changed(_ac_slider.value)
	_ac_button.disabled = false
	_door_button.disabled = false
	_show_stage()
	set_feedback(str(content.get("room", {}).get("pick", "")))


func _show_stage() -> void:
	_room_box.visible = stage == 1
	_server_box.visible = stage == 2
	_view.set("stage", stage)
	_view.set("temperature", temperature)
	_view.set("vents", _vents_clear)
	_view.set("door", _door_done)
	_view.set("ac", _ac_done)
	_view.set("step", _next)
	_view.set("fan_found", _fan_found)
	_view.set("fan_new", _fan_new)
	_view.queue_redraw()
	if stage == 1:
		_caption.text = str(content.get("room", {}).get("heading", ""))
		var first: Control = null
		for id: String in _vent_buttons:
			if not _vents_clear.has(id) and first == null:
				first = _vent_buttons[id]
		if first == null and not _ac_done:
			first = _ac_button
		if first == null and not _door_done:
			first = _door_button
		_glow(first)
	else:
		var steps: Array = content.get("server", {}).get("steps", [])
		if _next < steps.size():
			_caption.text = "%s  %d / %d: %s" % [content.get("server", {}).get("step_word", "STEP"), _next + 1, steps.size(), steps[_next]["label"]]
			_glow(_step_buttons.get(str(steps[_next]["id"]), null))
		else:
			_caption.text = ""
			_glow(null)


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


# --- stage 1: the room ---

func _on_ac_changed(value: float) -> void:
	_ac_label.text = str(content.get("room", {}).get("ac_text", "Air conditioner: %d")) % int(value)


func vent_pressed(id: String) -> void:
	if solved or stage != 1 or _vents_clear.has(id):
		return
	_vents_clear[id] = true
	_vent_buttons[id].disabled = true
	_cool(int(content.get("room", {}).get("vent_cool", 4)))
	_after_room_step(str(_find(content.get("room", {}).get("vents", []), id).get("done", "")))


func ac_pressed() -> void:
	if solved or stage != 1 or _ac_done:
		return
	var room: Dictionary = content.get("room", {})
	var value := int(_ac_slider.value)
	if value < int(room.get("ac_min", 20)):
		note_mistake(str(room.get("ac_too_cold", "")).format({"value": value}))
		return
	if value > int(room.get("ac_max", 24)):
		note_mistake(str(room.get("ac_too_warm", "")).format({"value": value}))
		return
	_ac_done = true
	_ac_slider.editable = false
	_ac_button.disabled = true
	_cool(int(room.get("ac_cool", 8)))
	_after_room_step(str(room.get("ac_done", "")))


func door_pressed() -> void:
	if solved or stage != 1 or _door_done:
		return
	_door_done = true
	_door_button.disabled = true
	_cool(int(content.get("room", {}).get("door_cool", 1)))
	_after_room_step(str(content.get("room", {}).get("door", {}).get("done", "")))


func _cool(amount: int) -> void:
	temperature = maxi(temperature - amount, int(content.get("room", {}).get("temp_ok", 24)))


func _after_room_step(text: String) -> void:
	set_feedback(text, "good")
	var vents_ok: bool = _vents_clear.size() == content.get("room", {}).get("vents", []).size()
	if vents_ok and _ac_done and _door_done:
		stage = 2
		set_feedback(str(content.get("room", {}).get("done", "")), "good")
	_show_stage()


# --- stage 2: the server ---

func step_pressed(id: String) -> void:
	if solved or stage != 2:
		return
	var steps: Array = content.get("server", {}).get("steps", [])
	if _next >= steps.size():
		return
	var step := _find(steps, id)
	if str(steps[_next]["id"]) != id:
		note_mistake(str(step.get("early", content.get("server", {}).get("wrong", ""))))
		return
	_advance(step)


func fan_pressed(id: String) -> void:
	if solved or stage != 2:
		return
	var steps: Array = content.get("server", {}).get("steps", [])
	if _next >= steps.size():
		return
	if str(steps[_next]["id"]) != "find":
		note_mistake(str(_find(steps, "find").get("early", "")))
		return
	var fan := _find(content.get("server", {}).get("fans", []), id)
	if not fan.get("ok", false):
		note_mistake(str(fan.get("reason", "")))
		return
	_fan_found = id
	_advance(steps[_next])


func airflow_pressed(id: String) -> void:
	if solved or stage != 2:
		return
	var steps: Array = content.get("server", {}).get("steps", [])
	if _next >= steps.size():
		return
	if str(steps[_next]["id"]) != "install":
		note_mistake(str(_find(steps, "install").get("early", "")))
		return
	var option := _find(content.get("server", {}).get("airflow", []), id)
	if not option.get("ok", false):
		note_mistake(str(option.get("reason", "")))
		return
	_fan_new = true
	_advance(steps[_next])


func _advance(step: Dictionary) -> void:
	_next += 1
	var steps: Array = content.get("server", {}).get("steps", [])
	set_feedback(str(step.get("done", "")), "good")
	if str(step["id"]) in _step_buttons:
		_step_buttons[str(step["id"])].disabled = true
	if _next >= steps.size():
		temperature = int(content.get("server", {}).get("temp_end", 24))
		_show_stage()
		succeed()
		return
	_show_stage()


func _find(list: Array, id: String) -> Dictionary:
	for entry: Dictionary in list:
		if str(entry["id"]) == id:
			return entry
	return {}


## The room and the server, drawn in code.
class FanView extends Control:
	const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
	const BACK := Color(0.101960786, 0.10980392, 0.17254902, 1)
	const WALL := Color(0.3372549, 0.42352942, 0.5254902, 1)
	const METAL := Color(0.5803922, 0.6901961, 0.7607843, 1)
	const DARK := Color(0.2, 0.23529412, 0.34117648, 1)
	const WOOD := Color(0.8784314, 0.72156864, 0.47843137, 1)
	const GOOD := Color(0.654902, 0.9411765, 0.4392157, 1)
	const WARM := Color(0.9372549, 0.49019608, 0.34117648, 1)
	var stage := 1
	var temperature := 41
	var vents: Dictionary = {}
	var door := false
	var ac := false
	var step := 0
	var fan_found := ""
	var fan_new := false

	func _process(_delta: float) -> void:
		queue_redraw() # the fans turn

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), BACK)
		draw_rect(Rect2(Vector2.ZERO, size), DARK, false, 1.0)
		_thermometer(Vector2(size.x - 40, 8))
		if stage == 1:
			_room()
		else:
			_server()

	func _thermometer(at: Vector2) -> void:
		draw_rect(Rect2(at, Vector2(8, 80)), DARK)
		draw_rect(Rect2(at, Vector2(8, 80)), WALL, false, 1.0)
		var share := clampf((float(temperature) - 15.0) / 30.0, 0.0, 1.0)
		var color := WARM.lerp(GOOD, 1.0 - share)
		draw_rect(Rect2(at + Vector2(1, 79.0 - 78.0 * share), Vector2(6, 78.0 * share)), color)
		draw_string(FONT, at + Vector2(-4, 90), "%d C" % temperature, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)

	func _room() -> void:
		draw_string(FONT, Vector2(6, 9), "THE SERVER ROOM", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		# two air vents, each with a box in front until it is moved
		for i in 2:
			var x := 40.0 + i * 120.0
			draw_rect(Rect2(x, 24, 70, 14), METAL)
			for line in 5:
				draw_rect(Rect2(x + 4, 27 + line * 2, 62, 1), DARK)
			if not vents.has("vent_a" if i == 0 else "vent_b"):
				draw_rect(Rect2(x + 8, 18, 54, 28), WOOD)
				draw_rect(Rect2(x + 8, 18, 54, 28), Color(0.69, 0.51, 0.31), false, 1.0)
				draw_rect(Rect2(x + 30, 18, 10, 28), Color(1, 0.8, 0.46))
		# the air conditioner and the door
		draw_rect(Rect2(280, 24, 56, 28), METAL)
		draw_rect(Rect2(284, 28, 48, 6), GOOD if ac else DARK)
		draw_string(FONT, Vector2(288, 48), "AIR COND." if not ac else "AIR ON", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, DARK)
		draw_rect(Rect2(360, 18, 30, 56) if not door else Rect2(360, 18, 6, 56), WOOD)
		draw_string(FONT, Vector2(354, 84), "DOOR OPEN" if not door else "DOOR SHUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		draw_rect(Rect2(20, 60, 230, 26), DARK) # the racks, seen from the front
		for k in 6:
			draw_rect(Rect2(26 + k * 38, 64, 30, 18), METAL)
			draw_rect(Rect2(30 + k * 38, 70, 5, 3), WARM if temperature > 30 else GOOD)

	func _server() -> void:
		draw_string(FONT, Vector2(6, 9), "THE SERVER, FROM THE SIDE", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		var lid_open := step >= 3 and step < 6
		var plugged := step < 2
		var running := step < 1
		draw_rect(Rect2(20, 22, 300, 56), METAL)
		draw_rect(Rect2(20, 22, 300, 56), WALL, false, 1.0)
		if lid_open:
			draw_rect(Rect2(24, 26, 292, 48), BACK)
		else:
			draw_rect(Rect2(24, 26, 292, 8), DARK)
			draw_string(FONT, Vector2(120, 56), "CASE CLOSED", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, DARK)
		draw_rect(Rect2(326, 36, 4, 4), GOOD if running else (WARM if step < 6 else GOOD)) # the light
		draw_string(FONT, Vector2(336, 41), "ON" if running or step >= 6 else "OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, WALL)
		# the power cable and its plug
		draw_line(Vector2(320, 70), Vector2(344 if plugged else 336, 70), WARM, 1.0)
		draw_rect(Rect2(344 if plugged else 348, 66, 8, 8), METAL)
		draw_rect(Rect2(364, 62, 10, 16), WALL) # the wall socket
		if lid_open:
			var names: Array = ["fan_1", "fan_2", "fan_3"]
			for i in 3:
				var center := Vector2(60 + i * 96, 50)
				var failed: bool = i == 0 and not fan_new
				var good: bool = fan_new and i == 0
				var color := GOOD if (good or i > 0) else WARM
				draw_circle(center, 16, DARK)
				draw_arc(center, 16, 0, TAU, 24, color, 1.0)
				var spin := 0.0 if failed else Time.get_ticks_msec() / 160.0 * (1.0 if (i > 0 or good) and step >= 6 else 0.0)
				for blade in 4:
					var angle := spin + blade * TAU / 4.0
					draw_line(center, center + Vector2(cos(angle), sin(angle)) * 13.0, color, 2.0)
				var text := "0 rpm" if failed else "4,200 rpm"
				if i > 0:
					text = "%s rpm" % ("4,200" if i == 1 else "4,100")
				if not (step >= 3):
					text = ""
				draw_string(FONT, center + Vector2(-16, 25), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)
			if fan_new:
				draw_string(FONT, Vector2(28, 84), "NEW FAN: AIR ->", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GOOD)
