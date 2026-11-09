extends SceneTree

## Builds assets/recovery/technician.png (the Recovery player) to look like Joshua
## (assets/charactersprite/Joshua.png): short slate hair, charcoal jacket over a light
## blue-grey shirt, dark trousers.
##
## Composites the CC0 MetroCity layers (art_source/recovery/licensed/metrocity) at native
## pixels: body row 0 + Outfit6 + hair row 3, then recolours each layer to Joshua's
## palette. Output: 6 frames x 4 rows (down, left, right, up) of 20x32, cropped at x = 6 in
## each 32px source cell. MetroCity orders its 24 frames down/right/up/left; the left row
## is the exact mirror of the right row so both directions always match.
##
##   godot --headless --path . --script res://tools/build_technician.gd -- [hair_row] [out.png]
## hair_row defaults to 3 (short swept cut, closest to Joshua); out.png defaults to res://assets/recovery/technician.png.

const SRC := "res://art_source/recovery/licensed/metrocity/MetroCity/"
const CELL := 32
const CROP_X := 6
const FRAME := Vector2i(20, 32)

# Joshua's portrait colours.
const SKIN := [Color("ffddcc"), Color("eeaa99"), Color("bb7766"), Color("5a3e3a")] # light -> outline (muted so hands do not read as red)
const HAIR := [Color("6f8282"), Color("556666"), Color("444444"), Color("222222")] # light -> outline
const JACKET := [Color("5e5e5e"), Color("4a4a4a"), Color("3a3a3a"), Color("2b2b2b"), Color("1a1a1a")]
const SHIRT := Color("99aabb")
const SHIRT_SHADE := Color("7d8fa0")
const TROUSERS := [Color("566c86"), Color("3b4466"), Color("333c57"), Color("1a1c2c")]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var hair_row := int(args[0]) if args.size() > 0 else 3
	var out_path: String = args[1] if args.size() > 1 else "res://assets/recovery/technician.png"
	var body := _load(SRC + "CharacterModel/Character Model.png").get_region(Rect2i(0, 0, 24 * CELL, CELL))
	var outfit := _load(SRC + "Outfits/Outfit6.png")
	var hair := _load(SRC + "Hair/Hairs.png").get_region(Rect2i(0, hair_row * CELL, 24 * CELL, CELL))
	_recolour_skin(body)
	_recolour_outfit(outfit)
	_recolour_by_brightness(hair, HAIR)
	var strip := Image.create(24 * CELL, CELL, false, Image.FORMAT_RGBA8)
	for layer in [body, outfit, hair]:
		strip.blend_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()), Vector2i.ZERO)
	_add_shirt_front(strip)
	var sheet := Image.create(6 * FRAME.x, 4 * FRAME.y, false, Image.FORMAT_RGBA8)
	# MetroCity groups: 0 down, 1 right, 2 up, 3 left. Game rows: down, left, right, up.
	for frame in 6:
		_place(sheet, strip, 0 * 6 + frame, frame, 0, false) # down
		_place(sheet, strip, 1 * 6 + frame, frame, 1, true)  # left = mirrored right
		_place(sheet, strip, 1 * 6 + frame, frame, 2, false) # right
		_place(sheet, strip, 2 * 6 + frame, frame, 3, false) # up
	var err := sheet.save_png(out_path)
	print("technician: hair row %d -> %s (%s)" % [hair_row, out_path, error_string(err)])
	quit(0 if err == OK else 1)


func _load(path: String) -> Image:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _place(sheet: Image, strip: Image, source_frame: int, column: int, row: int, mirror: bool) -> void:
	var cell := strip.get_region(Rect2i(source_frame * CELL + CROP_X, 0, FRAME.x, FRAME.y))
	if mirror:
		cell.flip_x()
	sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, FRAME), Vector2i(column * FRAME.x, row * FRAME.y))


## Skin keeps its shading but takes Joshua's tones. Neutral greys (eyes, teeth) stay.
func _recolour_skin(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5 or c.s < 0.12:
				continue
			var l := c.get_luminance()
			var tone: Color = SKIN[0] if l > 0.8 else (SKIN[1] if l > 0.62 else (SKIN[2] if l > 0.45 else SKIN[3]))
			image.set_pixel(x, y, tone)


## Outfit6: the red top becomes Joshua's charcoal jacket, the blue trousers go dark slate.
func _recolour_outfit(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var ramp: Array = TROUSERS if c.h > 0.5 and c.h < 0.75 else JACKET
			image.set_pixel(x, y, _ramp(ramp, c.get_luminance(), 0.55))


## Joshua's light shirt shows down the middle of the open jacket, front view only.
func _add_shirt_front(strip: Image) -> void:
	for frame in 6:
		var cx := frame * CELL + 16
		for y in range(17, 23):
			for x in [cx - 1, cx]:
				var c := strip.get_pixel(x, y)
				if c.a > 0.5 and JACKET.has(c):
					strip.set_pixel(x, y, SHIRT if y < 21 else SHIRT_SHADE)


func _recolour_by_brightness(image: Image, ramp: Array) -> void:
	var max_l := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				max_l = maxf(max_l, c.get_luminance())
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				image.set_pixel(x, y, _ramp(ramp, c.get_luminance(), max_l))


## Picks a ramp colour by brightness relative to the layer's brightest pixel (ramp is light -> dark).
func _ramp(ramp: Array, l: float, top: float) -> Color:
	var t := clampf(1.0 - l / maxf(top, 0.001), 0.0, 0.999)
	return ramp[int(t * ramp.size())]
