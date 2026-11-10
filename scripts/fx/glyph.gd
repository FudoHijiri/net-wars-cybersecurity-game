class_name Glyph
extends Control
## A small pixel icon drawn in code: check, cross, star, exclaim, lock, coin. It is the second cue next to a
## color ("not only colors"), and it can be replaced by sprites later. Use Glyph.make().

enum Kind { CHECK, CROSS, STAR, EXCLAIM, LOCK, COIN, CARD }

const SIZE := 7
const SHAPES := {
	Kind.CHECK: [
		".......",
		"......#",
		".....##",
		"#...##.",
		"##.##..",
		".###...",
		"..#....",
	],
	Kind.CROSS: [
		"#.....#",
		".#...#.",
		"..#.#..",
		"...#...",
		"..#.#..",
		".#...#.",
		"#.....#",
	],
	Kind.STAR: [
		"...#...",
		"...#...",
		"#######",
		".#####.",
		"..###..",
		".##.##.",
		".#...#.",
	],
	Kind.EXCLAIM: [
		"..###..",
		"..###..",
		"..###..",
		"..###..",
		".......",
		"..###..",
		"..###..",
	],
	Kind.LOCK: [
		"..###..",
		".#...#.",
		".#...#.",
		"#######",
		"###.###",
		"###.###",
		"#######",
	],
	Kind.COIN: [
		"..###..",
		".#####.",
		"#######",
		"###.###",
		"#######",
		".#####.",
		"..###..",
	],
	Kind.CARD: [
		".#####.",
		".#...#.",
		".#.#.#.",
		".#...#.",
		".#.#.#.",
		".#...#.",
		".#####.",
	],
}

var kind: Kind = Kind.CHECK
var color := Color.WHITE
var pixel := 1 # whole pixels only, so the icon stays crisp


## A glyph of the kind, `pixel` screen pixels per dot.
static func make(glyph_kind: Kind, glyph_color: Color, glyph_pixel: int = 1) -> Glyph:
	var glyph := Glyph.new()
	glyph.kind = glyph_kind
	glyph.color = glyph_color
	glyph.pixel = glyph_pixel
	glyph.custom_minimum_size = Vector2(SIZE, SIZE) * glyph_pixel
	glyph.size = glyph.custom_minimum_size
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return glyph


func _draw() -> void:
	var rows: Array = SHAPES[kind]
	for shadow in [true, false]: # a dark edge first, so the icon reads on any background
		for y in SIZE:
			var row: String = rows[y]
			for x in SIZE:
				if row[x] == "#":
					var at := Vector2(x, y) * pixel + (Vector2.ONE * pixel if shadow else Vector2.ZERO)
					draw_rect(Rect2(at, Vector2.ONE * pixel), PixelFx.DARK if shadow else color)
