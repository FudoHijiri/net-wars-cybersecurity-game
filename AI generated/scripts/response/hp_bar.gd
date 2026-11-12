class_name HpBar
extends Control
## The health bar of a fighter, under the fighter: the HP number sits inside the bar, and the buffs and
## debuffs (Block now, Dodge later) sit under it starting from the left. Pointing at one of them, or at the
## bar, shows what it is (the tooltip of the project's theme).
## Block is temporary HP: it is a blue part added after the HP, and the number is HP plus Block. A hit takes
## the blue part first. When the bar loses something, a white chunk shows what was lost, then melts away.
## set_values(max_hp, hp, block) and set_statuses([{id, amount, color, tip}]) are all a caller needs.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const INK := Color(0.101960786, 0.10980392, 0.17254902, 1)
const BACK := Color(0.2, 0.23529412, 0.34117648, 1)
const BAR_HEIGHT := 9
const CHIP_TOP := 13 # the status row starts this far under the top of the bar
const DODGE := [
	"#..#...",
	".#..#..",
	"..#..#.",
	"...#..#",
	"...#..#",
	"..#..#.",
	".#..#..",
	"#..#...",
]
const EXPOSED := [
	"..###..",
	".#.#.#.",
	"#..#..#",
	"#######",
	"#..#..#",
	".#.#.#.",
	"..###..",
	".......",
]
const DROP := [
	"...#...",
	"..###..",
	"..###..",
	".#####.",
	"#######",
	"#######",
	".#####.",
	"..###..",
]
const BOLT := [
	"....##.",
	"...##..",
	"..##...",
	".#####.",
	"...##..",
	"..##...",
	".##....",
	".#.....",
]
const CAP := [
	"#######",
	"#######",
	".......",
	"#.#.#.#",
	"#.#.#.#",
	".#.#.#.",
	".......",
	".......",
]
const REFLECT := [
	"..###..",
	".#...#.",
	"#..#..#",
	"#.#...#",
	"#.....#",
	".#...#.",
	"..###..",
	"...#...",
]
const SHIELD := [
	"#######",
	"#######",
	"#######",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#...",
]

## The color role of the fill (GameColors): "good" for the player, "bad" for the threat.
var fill_role: StringName = &"good"

var _max := 1
var _hp := 1
var _block := 0
var _ghost := 0.0 # the total (HP + Block) of the bar before its last drop; it melts down to the real total
var _ghost_tween: Tween
var _statuses: Array[Dictionary] = []
var _chip_rects: Array[Rect2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP # the tooltips need the mouse
	GameColors.changed.connect(queue_redraw)


## Shows max_hp, hp and Block. A drop in the total leaves the white chunk.
func set_values(max_hp: int, hp: int, block: int = 0) -> void:
	var before := float(_hp + _block)
	var total := float(hp + block)
	if total < before and not UiFx.reduced():
		if _ghost_tween == null or not _ghost_tween.is_valid():
			_ghost = before # a drop that lands during another one keeps the chunk that is melting
		if _ghost_tween != null and _ghost_tween.is_valid():
			_ghost_tween.kill()
		_ghost_tween = create_tween()
		_ghost_tween.tween_interval(0.35)
		_ghost_tween.tween_method(func(value: float) -> void:
			_ghost = value
			queue_redraw(), _ghost, total, 0.3)
		UiFx.flash(self, UiFx.RED, 0.3)
	_max = maxi(max_hp, 1)
	_hp = hp
	_block = block
	queue_redraw()


## The statuses under the bar, left to right: {id: "block", amount: 8, color: Color, tip: "text of the tooltip"}.
func set_statuses(statuses: Array[Dictionary]) -> void:
	_statuses = statuses
	queue_redraw()


func _get_tooltip(at_position: Vector2) -> String:
	for i in _chip_rects.size():
		if _chip_rects[i].has_point(at_position):
			return str(_statuses[i].get("tip", ""))
	if at_position.y <= BAR_HEIGHT:
		return "HP %d / %d%s" % [_hp, _max, ("\nBlock %d on top of it" % _block) if _block > 0 else ""]
	return ""


func _draw() -> void:
	var width := size.x
	var span := maxf(float(_max), float(_hp + _block))
	var unit := width / span
	var hp_x := roundf(_hp * unit)
	var total_x := roundf((_hp + _block) * unit)
	var edge := GameColors.block if _block > 0 else INK
	draw_rect(Rect2(-1, -1, width + 2, BAR_HEIGHT + 2), edge)
	draw_rect(Rect2(0, 0, width, BAR_HEIGHT), BACK)
	draw_rect(Rect2(0, 0, hp_x, BAR_HEIGHT), GameColors.fill(fill_role))
	if _block > 0:
		draw_rect(Rect2(hp_x, 0, total_x - hp_x, BAR_HEIGHT), GameColors.block)
	if _ghost > _hp + _block:
		draw_rect(Rect2(total_x, 0, roundf(_ghost * unit) - total_x, BAR_HEIGHT), Color(1, 1, 1, 0.9))
	var text := str(_hp + _block)
	var text_width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var shield_room := 10.0 if _block > 0 else 0.0 # the shield mark goes before the number
	var at := Vector2(roundf((width - text_width - shield_room) / 2.0 + shield_room), BAR_HEIGHT - 2)
	if _block > 0:
		_draw_mark(SHIELD, Vector2(at.x - 10.0, 0.0), INK)
	draw_string_outline(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 1, INK)
	draw_string(FONT, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.block if _block > 0 else Color.WHITE)
	_draw_statuses()


func _draw_statuses() -> void:
	_chip_rects.clear()
	var x := 0.0
	for status in _statuses:
		var color: Color = status.get("color", Color.WHITE)
		var amount := int(status.get("amount", 0))
		var label := str(amount) if amount > 0 else ""
		_draw_mark({"dodge": DODGE, "exposed": EXPOSED, "leak": DROP, "charge": BOLT, "cap": CAP, "reflect": REFLECT}.get(str(status.get("id", "")), SHIELD), Vector2(x, CHIP_TOP), color)
		var label_width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
		if not label.is_empty():
			draw_string(FONT, Vector2(x + 9.0, CHIP_TOP + 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)
		var chip_width := 9.0 + label_width
		_chip_rects.append(Rect2(x, CHIP_TOP - 1.0, chip_width, 10.0))
		x += chip_width + 5.0


## A mark of 7 x 8 pixels: the shield of Block, the chevrons of Dodge.
func _draw_mark(rows: Array, at: Vector2, color: Color) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				draw_rect(Rect2(at.x + x, at.y + y, 1, 1), color)
