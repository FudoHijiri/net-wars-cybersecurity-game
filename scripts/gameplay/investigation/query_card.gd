class_name QueryCard
extends Control
## A small database query drawn in code, for the Day 8 report. It shows what a visitor typed and the question the website
## builds from it ("SELECT * FROM users WHERE name = '" + typed + "'", the typed part underlined), and asks to be run:
## press RUN and it shows the database's answer. Run on "Maria" it is one row; run on a line of code the code is part of
## the question and the answer is every customer, which is the lesson. Running is never required, but it is how the two
## cards show the same website doing two different things. It reads one entry of the report's "queries":
## {label, typed, answer, note}. Each card carries its label as text (QUERY A: ...).

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const BACK := Color(0.9372549, 0.9372549, 0.9529412, 1)
const EDGE := Color(0.3372549, 0.42352942, 0.5254902, 1)
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)
const MUTED := Color(0.3372549, 0.42352942, 0.5254902, 1)
const HEADER := Color(0.16078432, 0.21176471, 0.43529412, 1)
const LIGHT := Color(0.95686275, 0.95686275, 0.95686275, 1)
const TYPED := Color(0.69, 0.24, 0.33, 1)
const GOOD := Color(0.2, 0.55, 0.2, 1)
const ROW := 10.0
const TOP := 13.0
const BUTTON := Rect2(4.0, 54.0, 30.0, 11.0)

var entry: Dictionary = {}
var ran := false
var _pointed := false


func _init() -> void:
	custom_minimum_size = Vector2(190, 76)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Press RUN to see what the database answers."


func show_query(query: Dictionary) -> void:
	entry = query
	ran = false
	queue_redraw()


## What the website asks the database, in two lines: the fixed part, and the part that has the typed text glued in.
func question_parts() -> Array[String]:
	return ["SELECT * FROM users", "WHERE name = '", str(entry.get("typed", "")), "'"]


func run() -> void:
	ran = true
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var now := BUTTON.has_point((event as InputEventMouseMotion).position)
		if now != _pointed:
			_pointed = now
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if now else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		if BUTTON.has_point((event as InputEventMouseButton).position):
			run()
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)
	draw_rect(Rect2(1, 1, size.x - 2, 11), HEADER)
	draw_string(BOLD, Vector2(4, 9), str(entry.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, LIGHT)
	var parts := question_parts()
	var typed_text := parts[2]
	draw_string(FONT, Vector2(4, TOP + 8.0), "Typed:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
	draw_string(FONT, Vector2(38, TOP + 8.0), typed_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 42.0, 6, INK)
	draw_string(FONT, Vector2(4, TOP + ROW + 8.0), "The site asks:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
	draw_string(FONT, Vector2(4, TOP + 2.0 * ROW + 8.0), parts[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, HEADER)
	var y := TOP + 3.0 * ROW + 8.0
	var x := 4.0
	draw_string(FONT, Vector2(x, y), parts[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, HEADER)
	x += FONT.get_string_size(parts[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var typed_width := FONT.get_string_size(typed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	draw_string(FONT, Vector2(x, y), typed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, TYPED)
	draw_rect(Rect2(x, y + 1.0, typed_width, 1.0), TYPED) # underlined: this part came from the visitor
	x += typed_width
	draw_string(FONT, Vector2(x, y), parts[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, HEADER)
	draw_rect(BUTTON, HEADER if not _pointed else Color(0.25, 0.32, 0.6))
	draw_string(BOLD, BUTTON.position + Vector2(0, 8.0), "RUN", HORIZONTAL_ALIGNMENT_CENTER, BUTTON.size.x, 6, LIGHT)
	if ran:
		draw_string(FONT, Vector2(40, BUTTON.position.y + 8.0), "Answer: %s" % entry.get("answer", ""), HORIZONTAL_ALIGNMENT_LEFT, size.x - 44.0, 6, TYPED if str(entry.get("answer", "")).contains("2,400") else GOOD)
		draw_string(FONT, Vector2(4, BUTTON.position.y + 19.0), str(entry.get("note", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, INK)
