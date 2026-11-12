class_name PixelFx
extends Node2D
## Pixel particles, rings and screen flashes drawn in code, so they need no art. One instance lives in the
## Fx overlay (autoload Fx) and serves every phase; ResponseFx extends it for the fight.
## Positions are screen positions (the game is 640x360). With "Reduce Screen Effects" (reduced) nothing
## here shows: the callers' own state changes still happen, they just are not decorated.

const RED := Color(1.0, 0.35, 0.3, 1.0)
const CYAN := Color(0.4509804, 0.9372549, 0.96862745, 1.0)
const GOLD := Color(1.0, 0.8039216, 0.45882353, 1.0)
const GREEN := Color(0.654902, 0.9411765, 0.4392157, 1.0)
const WHITE := Color(0.95686275, 0.95686275, 0.95686275, 1.0)
const DARK := Color(0.101960786, 0.10980392, 0.17254902, 1.0)
const CONFETTI := [RED, CYAN, GOLD, GREEN]
const MAX_SPARKS := 400

var reduced := false

var _sparks: Array[Spark] = []
var _rings: Array[Ring] = []
var _slashes: Array[Slash] = []
var _screen: ColorRect


class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color
	var size: int
	var gravity: float


class Ring:
	var pos: Vector2
	var color: Color
	var from: float
	var to: float
	var life: float
	var max_life: float


class Slash:
	var pos: Vector2
	var color: Color
	var life: float
	var max_life := 0.22


func _ready() -> void:
	# Looked up by name: this script is loaded by the Fx autoload, before the other autoloads exist as names.
	var effects := get_node_or_null("/root/ScreenEffects")
	reduced = effects != null and bool(effects.get("reduce_effects"))


func _process(delta: float) -> void:
	for spark in _sparks:
		spark.life -= delta
		spark.vel.y += spark.gravity * delta
		spark.pos += spark.vel * delta
	_sparks = _sparks.filter(func(s: Spark) -> bool: return s.life > 0.0)
	for one_ring in _rings:
		one_ring.life -= delta
	_rings = _rings.filter(func(r: Ring) -> bool: return r.life > 0.0)
	for one_slash in _slashes:
		one_slash.life -= delta
	_slashes = _slashes.filter(func(s: Slash) -> bool: return s.life > 0.0)
	queue_redraw()


func _draw() -> void:
	for one_ring in _rings:
		var k := 1.0 - one_ring.life / one_ring.max_life
		var radius := lerpf(one_ring.from, one_ring.to, ease(k, 0.4))
		draw_arc(one_ring.pos.round(), radius, 0.0, TAU, maxi(16, int(radius * 2.0)), Color(one_ring.color, 1.0 - k), 1.0, false)
	for one_slash in _slashes:
		var k := one_slash.life / one_slash.max_life # 1 -> 0
		var reach := minf((1.0 - k) * 4.0, 1.0)
		var start := one_slash.pos.round() + Vector2(-14, -14)
		draw_line(start, start + Vector2(28, 28) * reach, Color(one_slash.color, minf(k * 2.0, 1.0)), 2.0)
		draw_line(start + Vector2(4, -2), start + Vector2(4, -2) + Vector2(28, 28) * reach, Color(WHITE, minf(k * 2.0, 1.0)), 1.0)
	for spark in _sparks:
		@warning_ignore("integer_division")
		var half := spark.size / 2
		draw_rect(Rect2(spark.pos.round() - Vector2(half, half), Vector2(spark.size, spark.size)), Color(spark.color, clampf(spark.life / spark.max_life * 1.6, 0.0, 1.0)))


## Sparks flying out in every direction.
func burst(at: Vector2, color: Color, count: int, speed: float = 90.0, life: float = 0.45) -> void:
	if reduced:
		return
	for i in count:
		var spark := _spark(at, color, life)
		spark.vel = Vector2.from_angle(randf() * TAU) * speed * randf_range(0.3, 1.0)
		spark.gravity = 60.0


## Sparks drifting up (a card that draws, a repaired thing, a found clue).
func rise(at: Vector2, color: Color, count: int) -> void:
	if reduced:
		return
	for i in count:
		var spark := _spark(at + Vector2(randf_range(-10.0, 10.0), randf_range(-4.0, 6.0)), color, randf_range(0.5, 0.9))
		spark.vel = Vector2(randf_range(-14.0, 14.0), randf_range(-70.0, -30.0))
		spark.gravity = 0.0


## Coloured squares thrown up and falling back down.
func confetti(at: Vector2, count: int = 36) -> void:
	if reduced:
		return
	for i in count:
		var spark := _spark(at, CONFETTI[randi() % CONFETTI.size()], randf_range(1.1, 1.8))
		spark.vel = Vector2(randf_range(-110.0, 110.0), randf_range(-190.0, -70.0))
		spark.gravity = 230.0
		spark.size = 2


func ring(at: Vector2, color: Color, from: float, to: float, time: float = 0.3) -> void:
	if reduced:
		return
	var r := Ring.new()
	r.pos = at
	r.color = color
	r.from = from
	r.to = to
	r.life = time
	r.max_life = time
	_rings.append(r)


## A quick diagonal cut across a target.
func slash(at: Vector2, color: Color) -> void:
	if reduced:
		return
	var s := Slash.new()
	s.pos = at
	s.color = color
	s.life = s.max_life
	_slashes.append(s)


## The whole screen flashes for a moment.
func screen_flash(color: Color = Color.WHITE, strength: float = 0.7) -> void:
	if reduced:
		return
	if _screen == null:
		_screen = ColorRect.new()
		_screen.size = Vector2(640, 360)
		_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_screen)
	_screen.color = Color(color, strength)
	create_tween().tween_property(_screen, "color:a", 0.0, 0.35)


func _spark(at: Vector2, color: Color, life: float) -> Spark:
	var spark := Spark.new()
	if _sparks.size() >= MAX_SPARKS:
		_sparks.pop_front()
	spark.pos = at
	spark.life = life
	spark.max_life = life
	spark.color = color if randf() < 0.7 else WHITE
	spark.size = 1 + randi() % 2
	_sparks.append(spark)
	return spark
