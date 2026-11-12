class_name TrafficGraph
extends Control
## A small line graph of the requests a minute over time, drawn in code. The Day 6 report shows two of them and
## asks which is the real rush of customers and which is the attack. It reads one entry of the report's "graphs":
## {label, points: [requests a minute at each step]}, with the axis of the report: {start, end (clock texts),
## max (the top of the graph)}. Each graph carries its label as text (GRAPH A), never only a color.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const BACK := Color(0.101960786, 0.10980392, 0.17254902, 1)
const EDGE := Color(0.3372549, 0.42352942, 0.5254902, 1)
const GRID := Color(0.2, 0.23529412, 0.34117648, 1)
const LINE := Color(0.4509804, 0.9372549, 0.96862745, 1)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275, 1)
const LIGHT := Color(0.5803922, 0.6901961, 0.7607843, 1)
const PLOT := Rect2(24.0, 12.0, 160.0, 36.0) # where the line is drawn, inside the control

var label := ""
var points: Array = []
var axis: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(190, 62)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_graph(entry: Dictionary, graph_axis: Dictionary) -> void:
	label = str(entry.get("label", ""))
	points = entry.get("points", [])
	axis = graph_axis
	tooltip_text = ""
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)
	draw_string(BOLD, Vector2(4, 9), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, TEXT)
	var top := float(axis.get("max", 1))
	draw_string(FONT, Vector2(0, 9), "%s a minute" % _short(top), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4.0, 6, LIGHT)
	for i in 3:
		var y := PLOT.position.y + PLOT.size.y * i / 2.0
		draw_line(Vector2(PLOT.position.x, y), Vector2(PLOT.end.x, y), GRID, 1.0)
	draw_string(FONT, Vector2(2, PLOT.end.y + 3), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, LIGHT)
	var labels := [str(axis.get("start", "")), str(axis.get("middle", "")), str(axis.get("end", ""))]
	for i in labels.size():
		var x := PLOT.position.x + PLOT.size.x * i / 2.0
		var align := HORIZONTAL_ALIGNMENT_LEFT if i == 0 else (HORIZONTAL_ALIGNMENT_CENTER if i == 1 else HORIZONTAL_ALIGNMENT_RIGHT)
		var at := x if i == 0 else (x - 20.0 if i == 1 else x - 40.0)
		draw_string(FONT, Vector2(at, size.y - 3), labels[i], align, 40.0 if i > 0 else -1, 6, LIGHT)
	if points.size() < 2:
		return
	var line := PackedVector2Array()
	for i in points.size():
		var x := PLOT.position.x + PLOT.size.x * i / float(points.size() - 1)
		var y := PLOT.end.y - PLOT.size.y * clampf(float(points[i]) / top, 0.0, 1.0)
		line.append(Vector2(roundf(x), roundf(y)))
	draw_polyline(line, LINE, 1.0)
	for p in line:
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(2, 2)), LINE)


func _short(value: float) -> String:
	return "%dk" % int(value / 1000.0) if value >= 1000.0 else str(int(value))
