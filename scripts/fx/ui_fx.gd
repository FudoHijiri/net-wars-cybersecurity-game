class_name UiFx
extends RefCounted
## The visual vocabulary of the game's interface (docs/visual_effects_plan.md). Every helper:
##   - decorates a change that has already happened in the data, so skipping it can never desync the game,
##   - checks Settings > Reduce Screen Effects / Screen Shake itself (a reduced effect just ends in the final
##     state at once),
##   - returns a Tween (or a finished one), so a caller can `await tween.finished`,
##   - replaces an effect of the same kind that is still running on the node.
## Positions are screen positions (the game is 640x360). Text must stay at whole multiples of its font's size:
## a stamp or a pop only scales for a moment and ends at scale 1.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const GOLD := PixelFx.GOLD
const RED := PixelFx.RED
const CYAN := PixelFx.CYAN
const GREEN := PixelFx.GREEN
const WHITE := PixelFx.WHITE
const DARK := PixelFx.DARK


## The autoloads are looked up by name, so this script compiles in any context (a test script that names a
## class using it is compiled before the autoloads exist as identifiers).
static func _autoload(autoload_name: String) -> Node:
	return (Engine.get_main_loop() as SceneTree).root.get_node_or_null("/root/" + autoload_name)


static func reduced() -> bool:
	var effects := _autoload("ScreenEffects")
	return effects != null and bool(effects.get("reduce_effects"))


static func _shake_allowed() -> bool:
	var effects := _autoload("ScreenEffects")
	return effects == null or bool(effects.call("shake_allowed"))


static func _fx() -> Node:
	return _autoload("Fx")


static func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## A tween that is over at once (Reduce Effects, or nothing to do). It can still be awaited.
static func instant() -> Tween:
	var tween := _tree().create_tween()
	tween.tween_interval(0.0)
	return tween


## A new tween on the node for this kind of effect; the old one of the same kind is stopped.
static func _begin(node: Node, key: String) -> Tween:
	var meta := "_fx_" + key
	if node.has_meta(meta):
		var old: Variant = node.get_meta(meta)
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	var tween := node.create_tween()
	node.set_meta(meta, tween)
	return tween


## The value the node had before any effect touched it (so overlapping effects do not drift).
static func _rest(node: Node, key: String, current: Variant) -> Variant:
	var meta := "_rest_" + key
	if not node.has_meta(meta):
		node.set_meta(meta, current)
	return node.get_meta(meta)


static func _clear_rest(node: Node, key: String) -> void:
	node.remove_meta("_rest_" + key)


static func _center_pivot(node: CanvasItem) -> void:
	if node is Control:
		(node as Control).pivot_offset = (node as Control).size / 2.0


# --- feedback on one node ---

## Good: the node pops up a little and settles.
static func pop(node: CanvasItem, amount: float = 0.15, time: float = 0.2) -> Tween:
	if reduced() or not node.is_inside_tree():
		return instant()
	_center_pivot(node)
	var base: Vector2 = _rest(node, "scale", node.scale)
	var tween := _begin(node, "pop")
	tween.tween_property(node, "scale", base * (1.0 + amount), time * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", base, time * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: _clear_rest(node, "scale"))
	return tween


## Wrong or refused: a short horizontal shake (not with Reduce Screen Effects or Screen Shake off: the cross
## and the text still say it).
static func shake(node: CanvasItem, strength: float = 3.0, steps: int = 5) -> Tween:
	if reduced() or not _shake_allowed() or not node.is_inside_tree():
		return instant()
	var origin: Vector2 = _rest(node, "shake", node.position)
	var tween := _begin(node, "shake")
	for i in steps:
		var amount := strength * (1.0 - float(i) / steps)
		tween.tween_property(node, "position:x", origin.x + (amount if i % 2 == 0 else -amount), 0.04)
	tween.tween_property(node, "position:x", origin.x, 0.04)
	tween.tween_callback(func() -> void: _clear_rest(node, "shake"))
	return tween


## A color that fades away: red for a mistake, gold for a find.
static func flash(node: CanvasItem, tint: Color = RED, time: float = 0.3) -> Tween:
	if reduced() or not node.is_inside_tree():
		return instant()
	var base: Color = _rest(node, "flash", node.modulate)
	node.modulate = tint
	var tween := _begin(node, "flash")
	tween.tween_property(node, "modulate", base, time)
	tween.tween_callback(func() -> void: _clear_rest(node, "flash"))
	return tween


## The node fades in.
static func fade_in(node: CanvasItem, time: float = 0.2) -> Tween:
	node.show()
	if reduced() or not node.is_inside_tree():
		node.modulate.a = 1.0
		return instant()
	node.modulate.a = 0.0
	var tween := _begin(node, "fade")
	tween.tween_property(node, "modulate:a", 1.0, time)
	return tween


## The node slides in from `from` (an offset) while it fades in. Not for children of a container: the
## container puts them back.
static func slide_in(node: Control, from: Vector2 = Vector2(0, 16), time: float = 0.2) -> Tween:
	node.show()
	if reduced() or not node.is_inside_tree():
		node.modulate.a = 1.0
		return instant()
	var home: Vector2 = _rest(node, "slide", node.position)
	node.position = home + from
	node.modulate.a = 0.0
	var tween := _begin(node, "slide")
	tween.tween_property(node, "position", home, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "modulate:a", 1.0, time)
	tween.tween_callback(func() -> void: _clear_rest(node, "slide"))
	return tween


## The node slides away by `to` while it fades out, then hides and goes back to where it was.
static func slide_out(node: Control, to: Vector2 = Vector2(0, 16), time: float = 0.18) -> Tween:
	if reduced() or not node.is_inside_tree() or not node.visible:
		node.hide()
		return instant()
	var home: Vector2 = _rest(node, "slide", node.position)
	var tween := _begin(node, "slide")
	tween.tween_property(node, "position", home + to, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(node, "modulate:a", 0.0, time)
	tween.tween_callback(func() -> void:
		node.hide()
		node.position = home
		node.modulate.a = 1.0
		_clear_rest(node, "slide"))
	return tween


## Switching views: the old one slides out one way, the new one slides in from the other. dir is +1 when
## the new view is "further on" (to the right) and -1 when it is back.
static func swap_views(old: Control, new: Control, dir: int = 1, time: float = 0.18, distance: float = 24.0) -> Tween:
	if old != null and old != new and old.visible:
		slide_out(old, Vector2(-dir * distance, 0), time)
	return slide_in(new, Vector2(dir * distance, 0), time)


## Nodes appear one after another (rows of a list). They fade only, so containers can keep them in place.
static func stagger_fade(nodes: Array, step: float = 0.02, time: float = 0.14) -> void:
	for i in nodes.size():
		var node := nodes[i] as CanvasItem
		if node == null or not node.is_inside_tree():
			continue
		if reduced():
			node.modulate.a = 1.0
			continue
		node.modulate.a = 0.0
		var tween := _begin(node, "fade")
		tween.tween_property(node, "modulate:a", 1.0, time).set_delay(step * i)


## A number that counts from one value to another; fmt gets the number ("%d", "%+dSP").
static func count_to(label: Label, from: int, to: int, fmt: String = "%d", time: float = 0.35) -> Tween:
	if reduced() or from == to or not label.is_inside_tree():
		label.text = fmt % to
		return instant()
	var tween := _begin(label, "count")
	tween.tween_method(func(value: float) -> void: label.text = fmt % roundi(value), float(from), float(to), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: label.text = fmt % to)
	return tween


## Final: the node slams down (starts at twice its size, ends at 1) with a tiny shake. For stamps.
static func stamp(node: Control, time: float = 0.26) -> Tween:
	node.show()
	if reduced() or not node.is_inside_tree():
		node.modulate.a = 1.0
		node.scale = Vector2.ONE
		return instant()
	_center_pivot(node)
	node.scale = Vector2(2, 2)
	node.modulate.a = 0.0
	var tween := _begin(node, "stamp")
	tween.tween_property(node, "modulate:a", 1.0, time * 0.3)
	tween.parallel().tween_property(node, "scale", Vector2.ONE, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: shake(node, 2.0, 3))
	return tween


## Needs attention: a 1px bounce, whole pixels so the text stays crisp, that goes on until stop_attention()
## (or the node is freed). Reduce Screen Effects: no bounce (the caller's `!` or text says it).
static func attention(node: CanvasItem) -> void:
	if reduced() or not node.is_inside_tree():
		return
	stop_attention(node)
	var origin: Vector2 = _rest(node, "attention", node.position)
	var tween := _begin(node, "attention")
	tween.set_loops()
	for dy in [0.0, -1.0, -2.0, -1.0]:
		tween.tween_property(node, "position:y", origin.y + dy, 0.24)


## Stops the bounce and puts the node back.
static func stop_attention(node: CanvasItem) -> void:
	if node.has_meta("_fx_attention"):
		var old: Variant = node.get_meta("_fx_attention")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	if node.has_meta("_rest_attention"):
		node.position = node.get_meta("_rest_attention")
		_clear_rest(node, "attention")


# --- effects on the screen (the overlay above everything) ---

## Sparks, a ring and (for a find) a star at a screen position.
static func sparkle(at: Vector2, color: Color = GOLD, count: int = 10) -> void:
	if reduced():
		return
	_fx().pixels.burst(at, color, count, 70.0, 0.45)
	_fx().pixels.ring(at, color, 3.0, 14.0, 0.3)


static func rise(at: Vector2, color: Color = GOLD, count: int = 8) -> void:
	if reduced():
		return
	_fx().pixels.rise(at, color, count)


static func center_of(control: Control) -> Vector2:
	return control.get_global_rect().get_center()


## A word or number that floats up from a screen position and fades. size is 6 or 12 (whole multiples of the font).
static func float_text(text: String, at: Vector2, color: Color = WHITE, size: int = 6, life: float = 0.7) -> void:
	assert(size % 6 == 0, "UiFx.float_text: the font is 6px, so the size must be 6 or 12")
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", DARK)
	label.add_theme_constant_override("outline_size", 3)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label.position = (at - Vector2(width / 2.0, 0.0)).round()
	_fx().add_child(label)
	if reduced():
		_tree().create_timer(life).timeout.connect(label.queue_free)
		return
	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 14.0, life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, life * 0.4).set_delay(life * 0.6)
	tween.chain().tween_callback(label.queue_free)


## An icon flies from one screen position to another along an arc, and on_land is called when it arrives.
## Returns how long it takes (0 with Reduce Screen Effects: on_land is called at once).
static func fly(kind: Glyph.Kind, color: Color, from: Vector2, to: Vector2, on_land: Callable = Callable(), time: float = 0.4, arc: float = 24.0) -> float:
	if reduced():
		if on_land.is_valid():
			on_land.call()
		return 0.0
	var glyph := Glyph.make(kind, color, 1)
	glyph.z_index = 10
	_fx().add_child(glyph)
	var tween := glyph.create_tween()
	tween.tween_method(func(t: float) -> void:
		glyph.position = (from.lerp(to, ease(t, 1.6)) + Vector2(0.0, -sin(t * PI) * arc) - glyph.size / 2.0).round()
		if randf() < 0.5:
			_fx().pixels.rise(glyph.position + glyph.size / 2.0, color, 1)
	, 0.0, 1.0, time)
	tween.tween_callback(func() -> void:
		glyph.queue_free()
		if on_land.is_valid():
			on_land.call())
	return time


## A glyph that pops in next to a node ("the second cue"): a check for right, a cross for wrong, a star for a find.
static func badge(kind: Glyph.Kind, color: Color, at: Vector2, pixel: int = 2, life: float = 1.2) -> Glyph:
	var glyph := Glyph.make(kind, color, pixel)
	glyph.position = (at - glyph.size / 2.0).round()
	glyph.z_index = 10
	_fx().add_child(glyph)
	glyph.pivot_offset = glyph.size / 2.0
	if reduced():
		_tree().create_timer(life).timeout.connect(glyph.queue_free)
		return glyph
	glyph.scale = Vector2(2, 2)
	var tween := glyph.create_tween()
	tween.tween_property(glyph, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(life)
	tween.tween_property(glyph, "modulate:a", 0.0, 0.25)
	tween.tween_callback(glyph.queue_free)
	return glyph


## A word in a bordered box that slams onto the screen at `at` (REPORTED, CASE SOLVED, SOLD...), stays
## for `life` seconds, then fades. size is 6 or 12. Returns the box.
static func stamp_label(text: String, color: Color, at: Vector2, size: int = 12, life: float = 1.3) -> PanelContainer:
	assert(size % 6 == 0, "UiFx.stamp_label: the font is 6px, so the size must be 6 or 12")
	var box := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(DARK, 0.9)
	style.set_border_width_all(2)
	style.border_color = color
	style.set_content_margin_all(4.0)
	box.add_theme_stylebox_override("panel", style)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	box.z_index = 20
	_fx().add_child(box)
	box.size = box.get_combined_minimum_size()
	box.position = (at - box.size / 2.0).round()
	stamp(box)
	var tween := box.create_tween()
	tween.tween_interval(life)
	tween.tween_property(box, "modulate:a", 0.0, 0.25)
	tween.tween_callback(box.queue_free)
	return box


## A wide strip with a word that sweeps across the screen (YOUR TURN, ENEMY TURN, SHIFT OVER) and goes. It
## does not take the mouse. Reduce Screen Effects: the strip just fades in and out where it stops.
static func banner(text: String, color: Color, y: float = 150.0, hold: float = 0.5) -> void:
	var strip := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(DARK, 0.88)
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = color
	strip.add_theme_stylebox_override("panel", style)
	strip.size = Vector2(640, 24)
	strip.position = Vector2(0, y)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	label.size = strip.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.add_child(label)
	strip.z_index = 30
	_fx().add_child(strip)
	var tween := strip.create_tween()
	if reduced():
		strip.modulate.a = 0.0
		tween.tween_property(strip, "modulate:a", 1.0, 0.12)
		tween.tween_interval(hold)
		tween.tween_property(strip, "modulate:a", 0.0, 0.12)
	else:
		strip.position.x = -640.0
		tween.tween_property(strip, "position:x", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_interval(hold)
		tween.tween_property(strip, "position:x", 640.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(strip.queue_free)


## The middle of the first panel of a window (its frame): they all scale around this one point.
static func _common_center(panels: Array) -> Vector2:
	for panel in panels:
		if panel is Control and is_instance_valid(panel):
			return (panel as Control).get_global_rect().get_center()
	return Vector2.ZERO


## A window opens like a terminal: it grows from a thin line while the dim behind it fades in. The sizes are
## only known after the first frame, so it waits for that (the panels are invisible until then).
static func terminal_open(panels: Array, dim: CanvasItem = null) -> void:
	if reduced():
		return
	for panel in panels:
		if panel is CanvasItem:
			(panel as CanvasItem).modulate.a = 0.0
	if dim != null:
		dim.modulate.a = 0.0
	await _tree().process_frame
	# These keep running while the game is paused (Esc while a window opens): a window left half-open is a bug.
	if dim != null and is_instance_valid(dim):
		var dim_tween := dim.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		dim_tween.tween_property(dim, "modulate:a", 1.0, 0.15)
	var center := _common_center(panels)
	for panel in panels:
		if not (panel is Control) or not is_instance_valid(panel):
			continue
		var control := panel as Control
		control.pivot_offset = center - control.global_position # one centre for all, so the header moves with the frame
		control.scale = Vector2(1.0, 0.04)
		control.modulate.a = 1.0
		var tween := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(control, "scale:y", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## The same, backwards: the window shrinks to a line and fades. The tween belongs to the tree, so it runs even
## when the window is switched off. Returns it (chain a callback to remove the window afterwards).
static func terminal_close(panels: Array, dim: CanvasItem = null) -> Tween:
	var tween := _tree().create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var center := _common_center(panels)
	for panel in panels:
		if not (panel is Control) or not is_instance_valid(panel):
			continue
		var control := panel as Control
		control.pivot_offset = center - control.global_position
		tween.tween_property(control, "scale:y", 0.04, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(control, "modulate:a", 0.0, 0.15)
	if dim != null and is_instance_valid(dim):
		tween.tween_property(dim, "modulate:a", 0.0, 0.15)
	if panels.is_empty():
		tween.tween_interval(0.01)
	return tween


## A vertical line sweeps across the screen from left to right; on_x is called with its x as it goes (a scan).
static func sweep(color: Color, time: float, on_x: Callable = Callable()) -> void:
	if reduced():
		return
	var line := ColorRect.new()
	line.color = Color(color, 0.85)
	line.size = Vector2(2, 360)
	line.position = Vector2(-4, 0)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.z_index = 15
	_fx().add_child(line)
	var tween := line.create_tween()
	tween.tween_method(func(x: float) -> void:
		line.position.x = roundf(x)
		if on_x.is_valid():
			on_x.call(x), -4.0, 644.0, time)
	tween.tween_callback(line.queue_free)


## A small hop, whole pixels (a character that starts to speak).
static func hop(node: CanvasItem, height: float = 3.0) -> Tween:
	if reduced() or not node.is_inside_tree():
		return instant()
	var origin: Vector2 = _rest(node, "hop", node.position)
	var tween := _begin(node, "hop")
	tween.tween_property(node, "position:y", origin.y - height, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "position:y", origin.y, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: _clear_rest(node, "hop"))
	return tween


## Dims a node (the one who is not speaking) or lights it up again. It uses self_modulate, so it does not
## fight an entrance that animates modulate.
static func dim(node: CanvasItem, dimmed: bool, time: float = 0.18) -> void:
	var color := Color(0.62, 0.62, 0.72, 1.0) if dimmed else Color.WHITE
	if reduced() or not node.is_inside_tree():
		node.self_modulate = color
		return
	var tween := _begin(node, "dim")
	tween.tween_property(node, "self_modulate", color, time)


## Like badge(), but the icon is a child of `control` (at its top right corner, a little above), so it moves with
## the control when a layout moves it, and it never covers what is next to it.
static func badge_on(control: Control, kind: Glyph.Kind, color: Color, pixel: int = 2, life: float = 1.2) -> Glyph:
	var glyph := Glyph.make(kind, color, pixel)
	glyph.position = Vector2(control.size.x - 2.0 - glyph.size.x / 2.0, -2.0 - glyph.size.y / 2.0).round()
	glyph.z_index = 10
	control.add_child(glyph)
	glyph.pivot_offset = glyph.size / 2.0
	var tween := glyph.create_tween()
	if not reduced():
		glyph.scale = Vector2(2, 2)
		tween.tween_property(glyph, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(life)
	tween.tween_property(glyph, "modulate:a", 0.0, 0.25)
	tween.tween_callback(glyph.queue_free)
	return glyph
