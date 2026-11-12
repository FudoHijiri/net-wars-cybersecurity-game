class_name MessageCard
extends Control
## A small email drawn in code, for the Day 7 report. It shows the header of one message (the sender, the reply address)
## and a link, and asks to be looked at closer: click the sender, the reply address or the link and it shows the whole
## address, or where the link really goes. Looking closer is never required, but the text alone looks the same on the
## real message and on the fake one, which is the lesson. It reads one entry of the report's "cards":
## {label, from_name, from_addr, reply_to, link_text, link_target, ask}. Each card carries its label as text (MESSAGE A).

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const BACK := Color(0.9372549, 0.9372549, 0.9529412, 1)
const EDGE := Color(0.3372549, 0.42352942, 0.5254902, 1)
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)
const MUTED := Color(0.3372549, 0.42352942, 0.5254902, 1)
const HEADER := Color(0.16078432, 0.21176471, 0.43529412, 1)
const LIGHT := Color(0.95686275, 0.95686275, 0.95686275, 1)
const ROW := 10.0
const TOP := 13.0
const PARTS := ["from", "reply", "link"] # the rows that can be clicked

var entry: Dictionary = {}
var revealed: Dictionary = {} # part -> true once clicked
var _pointed := ""


func _init() -> void:
	custom_minimum_size = Vector2(190, 66)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Click a part of the message to look closer."


func show_message(message: Dictionary) -> void:
	entry = message
	revealed.clear()
	queue_redraw()


## The domain of an address or link: what comes after the "@", before the first "/".
static func domain_of(text: String) -> String:
	var at := text.rfind("@")
	var rest := text.substr(at + 1) if at >= 0 else text
	return rest.get_slice("/", 0)


## True when a link points to the domain its text shows.
func link_matches() -> bool:
	return domain_of(str(entry.get("link_text", ""))) == domain_of(str(entry.get("link_target", "")))


func look_closer(part: String) -> void:
	if part in PARTS:
		revealed[part] = true
		queue_redraw()


func _row_rect(part: String) -> Rect2:
	return Rect2(2.0, TOP + float(PARTS.find(part)) * ROW + 1.0, size.x - 4.0, ROW)


func _part_at(at: Vector2) -> String:
	for part: String in PARTS:
		if _row_rect(part).has_point(at):
			return part
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var now := _part_at((event as InputEventMouseMotion).position)
		if now != _pointed:
			_pointed = now
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not now.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var part := _part_at((event as InputEventMouseButton).position)
		if not part.is_empty():
			look_closer(part)
			accept_event()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACK)
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)
	draw_rect(Rect2(1, 1, size.x - 2, 11), HEADER)
	draw_string(BOLD, Vector2(4, 9), str(entry.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, LIGHT)
	draw_string(FONT, Vector2(0, 9), "click to look closer", HORIZONTAL_ALIGNMENT_RIGHT, size.x - 4.0, 6, Color(LIGHT, 0.7))
	for part: String in PARTS:
		var rect := _row_rect(part)
		if _pointed == part:
			draw_rect(rect, Color(0.45, 0.94, 0.97, 0.35))
		var baseline := rect.position.y + 7.0
		match part:
			"from":
				draw_string(FONT, Vector2(4, baseline), "From:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
				var shown := str(entry.get("from_name", ""))
				shown += "  <%s>" % (str(entry.get("from_addr", "")) if revealed.has("from") else "...")
				draw_string(FONT, Vector2(34, baseline), shown, HORIZONTAL_ALIGNMENT_LEFT, size.x - 38.0, 6, INK)
			"reply":
				draw_string(FONT, Vector2(4, baseline), "Reply-to:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
				draw_string(FONT, Vector2(44, baseline), str(entry.get("reply_to", "")) if revealed.has("reply") else "(hidden)", HORIZONTAL_ALIGNMENT_LEFT, size.x - 48.0, 6, INK)
			"link":
				draw_string(FONT, Vector2(4, baseline), "Link:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, MUTED)
				draw_string(FONT, Vector2(30, baseline), str(entry.get("link_text", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 34.0, 6, HEADER)
	var y := TOP + 3.0 * ROW + 8.0
	if revealed.has("link"):
		var matches := link_matches()
		var word := "MATCHES" if matches else "DOES NOT MATCH"
		draw_string(FONT, Vector2(4, y), "goes to: %s" % entry.get("link_target", ""), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, INK)
		draw_string(FONT, Vector2(4, y + 9.0), word, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.2, 0.55, 0.2) if matches else Color(0.69, 0.24, 0.33))
	else:
		draw_string(FONT, Vector2(4, y), "Asks: %s" % entry.get("ask", ""), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, INK)
