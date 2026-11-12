class_name ResponseFx
extends PixelFx
## The visual effects of the Response fight. There is no art for them: the particles, bolts, rings and the
## shield are drawn here in code (pixel squares, whole-pixel positions), and the fighters are animated by
## moving their offset and by the sprite_fx.gdshader (white flash, tint, grey, pixel dissolve), because the
## sprites only have an idle animation.
##   - bolt()      an orb flies from a card to its target (red to the enemy, cyan to the player), then bursts
##   - burst(), rise(), ring(), slash(), confetti()   the small effects
##   - set_aura()  the shield around the player while Block is up
##   - attack(), hurt(), cast(), defeat(), knock_out(), victory()   the fighters' animations (each returns
##     the Tween, so a caller can await tween.finished)
## With "Reduce Screen Effects" (reduced = true) there are no particles and no flashes: the fighters
## still move, and the defeated one still dissolves.

const SHADER := preload("res://AI generated/scripts/response/sprite_fx.gdshader")
const AURA_RADIUS := 34.0

var _bolts: Array[Bolt] = []
var _aura_on := false
var _aura_at := Vector2.ZERO
var _aura_alpha := 0.0
var _aura_pulse := 0.0
var _time := 0.0
var _home := {} # sprite -> its resting offset
var _tweens := {} # sprite -> the Tween playing on it
var _locked := {} # sprite -> true once it is defeated, knocked out or celebrating: nothing else moves it


class Bolt:
	var pos: Vector2
	var color: Color
	var size: int


func _process(delta: float) -> void:
	super(delta) # the particles
	_time += delta
	_aura_alpha = move_toward(_aura_alpha, 1.0 if _aura_on else 0.0, delta * 6.0)
	_aura_pulse = move_toward(_aura_pulse, 0.0, delta * 3.0)


func _draw() -> void:
	if _aura_alpha > 0.01:
		var wobble := 0.0 if reduced else sin(_time * 5.0) * 0.12
		var strength := clampf(_aura_alpha * (0.6 + wobble + _aura_pulse * 0.4), 0.0, 1.0)
		draw_set_transform(_aura_at.round(), 0.0, Vector2(0.85, 1.0))
		draw_circle(Vector2.ZERO, AURA_RADIUS, Color(GameColors.block, 0.10 * _aura_alpha + _aura_pulse * 0.15))
		draw_arc(Vector2.ZERO, AURA_RADIUS, 0.0, TAU, 48, Color(GameColors.block, strength), 1.0, false)
		draw_arc(Vector2.ZERO, AURA_RADIUS - 3.0, 0.0, TAU, 48, Color(WHITE, strength * 0.35), 1.0, false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	super() # rings, slashes, sparks
	for bolt in _bolts:
		var p := bolt.pos.round()
		var s := float(bolt.size)
		draw_rect(Rect2(p - Vector2(s + 2.0, s + 2.0), Vector2(s + 2.0, s + 2.0) * 2.0), Color(bolt.color, 0.3))
		draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), bolt.color)
		draw_rect(Rect2(p - Vector2(s * 0.5, s * 0.5).floor(), Vector2(s, s).floor()), WHITE)


# --- the bolt of a played card ---

## An orb flies from `from` to `to` (power 0..1 sets its size), bursts there, and then on_land is called.
## Returns how long the flight takes, so a caller can wait for it.
func bolt(from: Vector2, to: Vector2, color: Color, power: float, on_land: Callable, arc: float = 14.0) -> float:
	var orb := Bolt.new()
	orb.pos = from
	orb.color = color
	orb.size = 2 + roundi(clampf(power, 0.0, 1.0) * 3.0)
	_bolts.append(orb)
	var time := clampf(from.distance_to(to) / 520.0, 0.18, 0.42)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		orb.pos = from.lerp(to, ease(t, 1.8)) + Vector2(0.0, -sin(t * PI) * arc)
		if not reduced and randf() < 0.9:
			var trail := _spark(orb.pos, color, 0.22)
			trail.vel = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
			trail.gravity = 0.0
	, 0.0, 1.0, time)
	tween.tween_callback(func() -> void:
		_bolts.erase(orb)
		burst(to, color, 8 + roundi(power * 16.0), 70.0 + power * 80.0)
		ring(to, color, 3.0, 12.0 + power * 16.0)
		on_land.call())
	return time


# --- the shield ---

## The shield around the player, shown while Block is up. Turning it off breaks it into sparks.
func set_aura(on: bool, at: Vector2) -> void:
	_aura_at = at
	if _aura_on and not on:
		burst(at, GameColors.block, 16, 100.0)
		ring(at, GameColors.block, AURA_RADIUS, AURA_RADIUS + 14.0, 0.35)
	if on and not _aura_on:
		ring(at, GameColors.block, 8.0, AURA_RADIUS + 4.0, 0.35)
	_aura_on = on


## The shield takes a hit.
func pulse_aura() -> void:
	_aura_pulse = 1.0
	if _aura_on:
		burst(_aura_at + Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 10.0)), GameColors.block, 5, 50.0, 0.3)


# --- the fighters ---

## Gives a sprite the effects shader and remembers where it rests. Call once per sprite.
func prepare(sprite: AnimatedSprite2D) -> void:
	var material := ShaderMaterial.new()
	material.shader = SHADER
	sprite.material = material
	for name in ["flash", "tint_amount", "gray", "dissolve"]: # a parameter can only be tweened once it has been set
		material.set_shader_parameter(name, 0.0)
	material.set_shader_parameter("tint", GameColors.bad)
	_home[sprite] = sprite.offset


func _param(sprite: AnimatedSprite2D, name: String, value: Variant) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter(name, value)


## A new animation replaces the one running on the sprite, and starts from its resting pose.
## Returns null when the sprite is locked (defeated, knocked out, celebrating).
func _start(sprite: AnimatedSprite2D) -> Tween:
	if _locked.has(sprite):
		return null
	if _tweens.has(sprite) and (_tweens[sprite] as Tween).is_valid():
		(_tweens[sprite] as Tween).kill()
	sprite.offset = _home[sprite]
	_param(sprite, "flash", 0.0)
	_param(sprite, "tint_amount", 0.0)
	_param(sprite, "dissolve", 0.0) # an entrance that was interrupted must not leave the fighter half-gone
	var tween := create_tween()
	_tweens[sprite] = tween
	return tween


func _idle() -> Tween:
	var tween := create_tween()
	tween.tween_interval(0.01)
	return tween


## A shader parameter runs from `from` to `to`, alongside the step before it (or as a step of its own with
## `together` false). It goes through tween_method because the parameter is not a real property: tweening
## "shader_parameter/..." directly stalls when the renderer does not list the shader's uniforms (headless).
func _fade_param(tween: Tween, sprite: AnimatedSprite2D, name: String, from: float, to: float, time: float, together: bool = true) -> void:
	var material := sprite.material as ShaderMaterial
	if together:
		tween.parallel()
	tween.tween_method(func(value: float) -> void: material.set_shader_parameter(name, value), from, to, time)


## The fighter is invisible (before the fight starts).
func conceal(sprite: AnimatedSprite2D) -> void:
	if not UiFx.reduced():
		_param(sprite, "dissolve", 1.0)


## The fighter forms out of pixels, with a ring. Reduce Screen Effects: it is simply there.
func appear(sprite: AnimatedSprite2D, delay: float = 0.0) -> Tween:
	if reduced:
		_param(sprite, "dissolve", 0.0)
		return _idle()
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	_param(sprite, "tint", GameColors.block)
	_param(sprite, "dissolve", 1.0) # nothing to see until its turn comes
	tween.tween_interval(delay)
	_fade_param(tween, sprite, "dissolve", 1.0, 0.0, 0.6, false)
	tween.parallel().tween_callback(func() -> void: ring(sprite.global_position, GameColors.block, 8.0, 44.0, 0.5))
	return tween


## A wind-up and a lunge toward `toward` and back (the player playing an attack card, the enemy attacking).
func attack(sprite: AnimatedSprite2D, toward: Vector2, color: Color = RED, distance: float = 12.0) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	var home: Vector2 = _home[sprite]
	var dir := (toward - sprite.global_position).normalized()
	_param(sprite, "tint", color)
	tween.tween_property(sprite, "offset", home - dir * 4.0, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if not reduced:
		_fade_param(tween, sprite, "tint_amount", 0.0, 0.45, 0.1)
	tween.tween_property(sprite, "offset", home + dir * distance, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		ring(sprite.global_position + dir * 22.0, color, 2.0, 12.0, 0.2)
		burst(sprite.global_position + dir * 22.0, color, 6, 60.0, 0.3))
	tween.tween_property(sprite, "offset", home, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_fade_param(tween, sprite, "tint_amount", 0.45, 0.0, 0.2)
	return tween


## The sprite is hit: a white flash, red tint and a knock in the direction `away`.
func hurt(sprite: AnimatedSprite2D, away: Vector2) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	var home: Vector2 = _home[sprite]
	_param(sprite, "tint", GameColors.bad)
	_param(sprite, "tint_amount", 0.7)
	if not reduced:
		_param(sprite, "flash", 1.0)
		_fade_param(tween, sprite, "flash", 1.0, 0.0, 0.12)
	tween.parallel().tween_property(sprite, "offset", home + away.normalized() * 5.0, 0.04)
	tween.tween_property(sprite, "offset", home, 0.22).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_fade_param(tween, sprite, "tint_amount", 0.7, 0.0, 0.3)
	return tween


## A small hop with a coloured glow (the player playing a defense or utility card).
func cast(sprite: AnimatedSprite2D, color: Color) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	var home: Vector2 = _home[sprite]
	_param(sprite, "tint", color)
	tween.tween_property(sprite, "offset", home + Vector2(0, -4), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_fade_param(tween, sprite, "tint_amount", 0.0, 0.4, 0.1)
	tween.tween_property(sprite, "offset", home, 0.16).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_fade_param(tween, sprite, "tint_amount", 0.4, 0.0, 0.16)
	return tween


## The enemy is defeated: it flashes, shakes, then falls apart pixel by pixel in a shower of sparks.
func defeat(sprite: AnimatedSprite2D) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	_locked[sprite] = true
	var home: Vector2 = _home[sprite]
	var center := sprite.global_position
	_param(sprite, "tint", GameColors.highlight)
	if not reduced:
		_param(sprite, "flash", 1.0)
		_fade_param(tween, sprite, "flash", 1.0, 0.0, 0.25)
		screen_flash()
		ring(center, WHITE, 6.0, 60.0, 0.5)
		burst(center, GameColors.highlight, 26, 130.0, 0.6)
		for i in 7:
			tween.tween_property(sprite, "offset", home + Vector2(randf_range(-3.0, 3.0), randf_range(-1.0, 1.0)), 0.05)
	else:
		tween.tween_interval(0.2)
	_fade_param(tween, sprite, "tint_amount", 0.0, 0.5, 0.2)
	tween.tween_method(func(t: float) -> void:
		if randf() < 0.6:
			burst(center + Vector2(randf_range(-18.0, 18.0), randf_range(-24.0, 20.0)), GameColors.highlight, 2, 50.0, 0.4)
		, 0.0, 1.0, 0.9)
	_fade_param(tween, sprite, "dissolve", 0.0, 1.0, 0.9)
	tween.parallel().tween_property(sprite, "offset", home + Vector2(0, 8), 0.9).set_ease(Tween.EASE_IN)
	tween.tween_callback(sprite.hide)
	return tween


## The player is knocked out: a flash, a shake, then it loses its colour and sinks.
func knock_out(sprite: AnimatedSprite2D) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	_locked[sprite] = true
	var home: Vector2 = _home[sprite]
	_param(sprite, "tint", GameColors.bad)
	if not reduced:
		_param(sprite, "flash", 1.0)
		_fade_param(tween, sprite, "flash", 1.0, 0.0, 0.2)
		burst(sprite.global_position, GameColors.bad, 18, 100.0, 0.5)
		for i in 5:
			tween.tween_property(sprite, "offset", home + Vector2(randf_range(-3.0, 3.0), 0.0), 0.05)
	else:
		tween.tween_interval(0.2)
	_fade_param(tween, sprite, "gray", 0.0, 1.0, 0.5, false)
	tween.parallel().tween_property(sprite, "offset", home + Vector2(0, 10), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "modulate:a", 0.6, 0.5)
	return tween


## The player has won: two happy hops, and confetti.
func victory(sprite: AnimatedSprite2D) -> Tween:
	var tween := _start(sprite)
	if tween == null:
		return _idle()
	_locked[sprite] = true
	var home: Vector2 = _home[sprite]
	var feet := sprite.global_position + Vector2(0, 24)
	_param(sprite, "tint", GameColors.highlight)
	confetti(sprite.global_position + Vector2(0, -16))
	for i in 2:
		tween.tween_property(sprite, "offset", home + Vector2(0, -14), 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if not reduced:
			_fade_param(tween, sprite, "tint_amount", 0.0, 0.35, 0.17)
		tween.tween_property(sprite, "offset", home, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_fade_param(tween, sprite, "tint_amount", 0.35, 0.0, 0.17)
		tween.tween_callback(func() -> void:
			ring(feet, GameColors.highlight, 4.0, 20.0, 0.3)
			burst(feet, GameColors.highlight, 8, 60.0, 0.35))
	tween.tween_interval(0.2)
	return tween
