@tool
class_name RecoveryMachineArt
extends Control

## Close-up hardware drawn behind real focusable controls.
## Patch mode draws a cable from each button under devices_root to the matching
## button under sockets_root, so moving those buttons in the editor moves the cables.

@export_enum("patch", "cartridge", "account", "contact", "file") var mode := "patch":
	set(value):
		mode = value
		queue_redraw()
@export var checked := false:
	set(value):
		checked = value
		queue_redraw()
@export_group("Patch panel")
@export var devices_root: Control
@export var sockets_root: Control
## Horizontal gap between a socket button and its drawn socket icon.
@export var socket_icon_gap := 14.0

var connections: Dictionary = {}
var device_order: Array[String] = []
var socket_order: Array[String] = []
var device_clearance: Dictionary = {}
var port_shapes: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	# Editor preview follows buttons as they are dragged.
	set_process(Engine.is_editor_hint() and mode == "patch")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), RecoveryStyle.SLATE)
	match mode:
		"patch":
			_draw_patch()
		"cartridge":
			_draw_cartridge()
		_:
			_draw_screen()


func _draw_patch() -> void:
	var devices := _buttons(devices_root)
	var sockets := _buttons(sockets_root)
	var device_ids := _ids(device_order, devices.size())
	var socket_ids := _ids(socket_order, sockets.size())
	for j in sockets.size():
		var socket := _socket_point(sockets[j])
		draw_rect(Rect2(socket - Vector2(10, 10), Vector2(20, 20)), RecoveryStyle.DARK)
		_port_shape(socket, str(port_shapes.get(socket_ids[j], "square")), RecoveryStyle.LIGHT)
	for i in devices.size():
		var id := device_ids[i]
		var rect := _local_rect(devices[i])
		var a := Vector2(rect.end.x, rect.get_center().y)
		var j := socket_ids.find(id)
		var plugged := connections.has(id) and j >= 0
		var b := _socket_point(sockets[j]) if plugged else a + Vector2(78 - i * 9, 6)
		var middle := (a + b) / 2.0 + Vector2(0, 10)
		var color: Color = [RecoveryStyle.CYAN, RecoveryStyle.YELLOW, RecoveryStyle.ORANGE][i % 3]
		if not device_clearance.get(id, Engine.is_editor_hint()):
			color = RecoveryStyle.STEEL
		var line := PackedVector2Array([a, a + Vector2(10, 0), middle, b - Vector2(10, 0), b])
		draw_polyline(line, RecoveryStyle.DARK, 7)
		draw_polyline(line, color, 3)
		if not plugged:
			draw_rect(Rect2(b - Vector2(7, 8), Vector2(16, 16)), RecoveryStyle.DARK)
			_port_shape(b, str(port_shapes.get(id, "square")), color)


func _draw_cartridge() -> void:
	var cartridge := Rect2(size.x * 0.20, 7, size.x * 0.60, size.y - 14)
	draw_rect(cartridge, RecoveryStyle.SLATE)
	draw_rect(cartridge, RecoveryStyle.YELLOW if checked else RecoveryStyle.LIGHT, false, 2)
	draw_rect(Rect2(cartridge.position + Vector2(6, 5), Vector2(cartridge.size.x - 12, 10)), RecoveryStyle.ORANGE)
	draw_rect(Rect2(cartridge.position + Vector2(8, 20), Vector2(cartridge.size.x - 16, maxf(7, cartridge.size.y - 29))), RecoveryStyle.DARK)
	for i in range(5):
		draw_rect(Rect2(cartridge.position + Vector2(10 + i * 6, cartridge.size.y - 4), Vector2(3, 3)), RecoveryStyle.YELLOW)


func _draw_screen() -> void:
	var screen := Rect2(10, 5, size.x - 20, size.y - 14)
	draw_rect(screen, RecoveryStyle.DARK)
	draw_rect(screen, RecoveryStyle.CYAN if checked else RecoveryStyle.STEEL, false, 2)
	var center := screen.get_center()
	if mode in ["account", "contact"]:
		draw_circle(center + Vector2(0, -5), 5, RecoveryStyle.CYAN)
		draw_rect(Rect2(center + Vector2(-9, 3), Vector2(18, 7)), RecoveryStyle.CYAN)
	else:
		draw_rect(Rect2(center + Vector2(-7, -10), Vector2(14, 20)), RecoveryStyle.WHITE)
		for y in [-5, 0, 5]:
			draw_line(center + Vector2(-4, y), center + Vector2(4, y), RecoveryStyle.NAVY, 1)
	draw_rect(Rect2(size.x / 2 - 12, size.y - 7, 24, 3), RecoveryStyle.STEEL)


func _buttons(parent: Control) -> Array[Control]:
	var found: Array[Control] = []
	if is_instance_valid(parent):
		for child in parent.get_children():
			if child is Control and child.visible:
				found.append(child)
	return found


func _ids(order: Array[String], count: int) -> Array[String]:
	if not order.is_empty():
		return order
	var placeholder: Array[String] = []
	for i in count:
		placeholder.append("preview_%d" % i)
	return placeholder


func _local_rect(control: Control) -> Rect2:
	return Rect2(control.global_position - global_position, control.size)


func _socket_point(socket: Control) -> Vector2:
	var rect := _local_rect(socket)
	return Vector2(rect.position.x - socket_icon_gap, rect.get_center().y)


func _port_shape(center: Vector2, shape: String, color: Color) -> void:
	match shape:
		"circle":
			draw_circle(center, 6, color, false, 2)
		"triangle":
			draw_polyline(PackedVector2Array([center + Vector2(0, -7), center + Vector2(7, 6), center + Vector2(-7, 6), center + Vector2(0, -7)]), color, 2)
		_:
			draw_rect(Rect2(center - Vector2(6, 6), Vector2(12, 12)), color, false, 2)
