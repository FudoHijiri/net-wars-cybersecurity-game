extends RecoveryTask

## Layout: NetworkRepair.tscn. Device leads are the buttons under %Devices and
## sockets are the buttons under %Sockets, filled in order from the JSON devices.

var selected_device := ""
var connected: Dictionary = {}
var device_buttons: Dictionary = {}
var socket_buttons: Dictionary = {}
var _device_text: Dictionary = {}
var _socket_text: Dictionary = {}
var _eligible: Array[String] = []

@onready var test_button: Button = %TestButton
@onready var _art: RecoveryMachineArt = %PatchPanel
@onready var _devices: Control = %Devices
@onready var _sockets: Control = %Sockets


func setup_task() -> void:
	%DeviceHeading.text = str(content.get("device_heading", ""))
	%PortHeading.text = str(content.get("port_heading", ""))
	var devices: Array = content.get("devices", [])
	_art.connections = connected
	var device_nodes := _devices.get_children()
	for i in device_nodes.size():
		var button := device_nodes[i] as Button
		button.visible = i < devices.size()
		if not button.visible:
			continue
		var device: Dictionary = devices[i]
		var id := str(device["id"])
		_art.device_order.append(id)
		_art.device_clearance[id] = _cleared(id)
		_art.port_shapes[id] = str(device.get("shape", "square"))
		if _cleared(id):
			_eligible.append(id)
		var status := "CLEARED" if _cleared(id) else "OFFLINE"
		_device_text[id] = str(device["label"]) + "\n" + str(device["port"]).replace(" / ", " ") + " / " + status
		button.pressed.connect(_pick_device.bind(id))
		if button is RecoveryDragItem:
			# Mouse: drag the plug onto a socket. Unchecked plugs are taped down.
			button.item_id = id
			button.locked = not _cleared(id)
			button.drag_refused.connect(func(_item: RecoveryDragItem) -> void: _refuse_unsafe(id))
		device_buttons[id] = button
	# Sockets are listed in a different order from the leads.
	var socket_nodes := _sockets.get_children()
	for i in socket_nodes.size():
		var button := socket_nodes[i] as Button
		button.visible = i < devices.size()
		if not button.visible:
			continue
		var device: Dictionary = devices[(i + 1) % devices.size()]
		var id := str(device["id"])
		_art.socket_order.append(id)
		_socket_text[id] = str(device["port"])
		button.pressed.connect(_connect_socket.bind(id))
		if button is RecoveryDropSlot:
			button.item_dropped.connect(func(item: RecoveryDragItem) -> void:
				selected_device = item.item_id
				_connect_socket(id))
		socket_buttons[id] = button
	if device_buttons.size() < devices.size() or socket_buttons.size() < devices.size():
		push_warning("NetworkRepair.tscn has fewer device/socket buttons than the JSON lists.")


func reset_state() -> void:
	selected_device = ""
	connected.clear()
	for id: String in device_buttons:
		device_buttons[id].text = _device_text[id]
	for id: String in socket_buttons:
		socket_buttons[id].text = _socket_text[id]
	_art.queue_redraw()
	set_feedback(str(content.get("pick", "")))


func _cleared(id: String) -> bool:
	return RecoveryContext.is_cleared(runtime_outcome) and runtime_outcome.get("cleared_devices", {}).get(id, false) == true


func _pick_device(id: String) -> void:
	if solved or connected.has(id):
		return
	selected_device = id
	for device: Dictionary in content.get("devices", []):
		if str(device["id"]) == id:
			var status := str(content.get("cleared" if _cleared(id) else "unchecked", ""))
			set_feedback(str(content.get("selected", "")).format({"device": device["label"], "clearance": status, "note": device.get("note", "")}))
	socket_buttons[id].grab_focus()


func _connect_socket(id: String) -> void:
	if solved:
		return
	if selected_device.is_empty():
		set_feedback(str(content.get("pick", "")))
	elif not _cleared(selected_device):
		_refuse_unsafe(selected_device)
	elif selected_device != id:
		_bounce(selected_device)
		note_mistake(str(content.get("wrong", "")))
		selected_device = ""
	else:
		connected[id] = true
		device_buttons[id].disabled = true
		socket_buttons[id].disabled = true
		device_buttons[id].text = "[OK] CONNECTED"
		socket_buttons[id].text = "[OK] CONNECTED"
		selected_device = ""
		_art.queue_redraw()
		set_feedback(str(content.get("connected", "")).format({"done": connected.size(), "total": _eligible.size()}))
		RecoveryStyle.focus_loop(self)


func _refuse_unsafe(id: String) -> void:
	if solved:
		return
	_bounce(id)
	note_mistake(str(content.get("unsafe", "")))
	selected_device = ""


func _bounce(id: String) -> void:
	if device_buttons.get(id) is RecoveryDragItem:
		device_buttons[id].bounce()


func _test_connection() -> void:
	if _eligible.is_empty():
		set_feedback(str(content.get("none_cleared", "")))
	elif connected.size() != _eligible.size():
		set_feedback(str(content.get("incomplete", "")))
	else:
		for id: String in connected:
			if not _cleared(id):
				set_feedback(str(content.get("unsafe", "")))
				return
		succeed()
