class_name BulletArena
extends Node2D
## The box of the enemy turn: the player's heart dodges the bullets of one attack pattern.
## start() begins a pattern (see data/response_day1.json), hit() is emitted when a bullet
## touches the heart, pattern_finished() when the pattern's time is up.
##
## The upgrades the player equipped in Hardening change how a pattern plays out, and the box shows it at the
## moment it happens (see note()): that is how the player learns what each upgrade does. A pattern has one
## upgrade that counters it ("counter"). Without it the pattern is played in a harder version: its "harsh"
## numbers replace the normal ones (see _param()), and the box says so (is_harder()).
## Kinds of pattern: stream, sweep, aimed (Credential Abuse), disguise (a bullet that looks harmless and turns
## hostile), split (a bullet that breaks into copies) and flicker (a bullet that fades in and out) (Malware).

signal hit(damage: int)
signal pattern_finished
## A short message about what just happened, for the player. good is true when a defense worked.
signal note(text: String, good: bool)
## A defense did its job (its id), so the result line after the pattern can name it.
signal defense_used(id: String)

const CENTER := Vector2(320, 166) # the middle of the box on the screen (its labels above it need the room under the turn label)
const SOUL_SPEED := 95.0
const SOUL_RADIUS := 3.0
const INVINCIBLE_TIME := 0.9 # after a hit the heart cannot be hit again for this long
const GLIDE := 9.0 # how fast the box reaches its new size
const CRACKED_SPEEDUP := 1.7 # when one password opens every account, the other accounts rush in
const HEART := preload("res://assets/ui/HeartIcon.png")
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const FILL := Color(0.101960786, 0.10980392, 0.17254902, 0.88)
const BORDER := Color(0.5803922, 0.6901961, 0.7607843, 1)
const WARNING := Color(0.69411767, 0.24313726, 0.3254902, 1)
const SPARK := Color(0.95686275, 0.95686275, 0.95686275, 1)
const CRACKED := Color(1.0, 0.45, 0.45, 1)
const AMBER := Color(1, 0.8039216, 0.45882353, 1)

## Replace this to move the heart from code (a demo or a test bot). It takes no arguments and
## returns the direction to move. Empty means the keyboard: arrow keys or WASD.
var direction_provider := Callable()
var size := Vector2(112, 112)
## The ids of the upgrades the player equipped (unique, twostep, lockout, alerts).
var defenses: Array[String] = []
## True while the pattern is the harder version (the upgrade that counters it is not equipped).
var is_harder := false
## An upgrade that warns early (a "helper"): the pattern starts this many seconds later, and the note says why.
var warning_bonus := 0.0
var helper_id := ""
var helper_note := ""

var _target_size := Vector2(112, 112)
var _pattern: Dictionary = {}
var _texture: Texture2D
var _running := false
var _time := 0.0
var _spawn_in := 0.0
var _shots := 0 # how many times the pattern has fired
var _failed_tries := 0 # guesses that flew past the heart
var _locked := 0.0 # seconds the attacker is locked out
var _invincible := 0.0
var _soul := Vector2(50, 40)
var _texture_real: Texture2D # disguise: what the bullet turns into
var _texture_copy: Texture2D # split: a copy
var _announced := false # the first bullet of the pattern told the player what the defense did
var _bullets: Array[Dictionary] = [] # {pos, vel, damage, wall, cracked, + gen, age (split), revealed (disguise), phase (flicker)}
var _warnings: Array[Dictionary] = [] # {from, dir, time} aimed bullets that have not flown yet
var _sparks: Array[Dictionary] = [] # {pos, vel, life} the burst when the heart is hit


func start(pattern: Dictionary) -> void:
	_pattern = pattern
	is_harder = not defenses.has(str(pattern["counter"]))
	_texture = load(str(pattern["sprite"]))
	_texture_real = load(str(pattern["sprite_real"])) if pattern.has("sprite_real") else _texture
	_texture_copy = load(str(pattern["sprite_copy"])) if pattern.has("sprite_copy") else _texture
	_announced = false
	var box: Array = _param("box", [112, 112])
	_target_size = Vector2(float(box[0]), float(box[1]))
	_bullets.clear()
	_warnings.clear()
	_sparks.clear()
	_time = 0.0
	_spawn_in = 0.7 + warning_bonus # the box needs a moment to reach its size, and the player to see it
	_shots = 0
	_failed_tries = 0
	_locked = 0.0
	_invincible = 0.0
	_soul = Vector2(_target_size.x * 0.4, _target_size.y * 0.3) # not exactly between two lanes
	_running = true
	_fit_box(0.0)
	show()
	if warning_bonus > 0.0 and not helper_id.is_empty():
		note.emit(helper_note, true)
		defense_used.emit(helper_id)


func stop() -> void:
	_running = false
	_bullets.clear()
	_warnings.clear()
	_sparks.clear()
	hide()


func _physics_process(delta: float) -> void:
	if not _running:
		return
	_fit_box(delta)
	_time += delta
	_invincible = maxf(_invincible - delta, 0.0)
	_locked = maxf(_locked - delta, 0.0)
	_move_soul(delta)
	_spawn_in -= delta
	if _time < float(_pattern["duration"]) and _spawn_in <= 0.0 and _locked <= 0.0:
		_spawn_in += float(_param("interval"))
		_spawn()
		_shots += 1
	_fire_warnings(delta)
	_move_bullets(delta)
	_move_sparks(delta)
	queue_redraw()
	if _time >= float(_pattern["duration"]) and _bullets.is_empty() and _warnings.is_empty():
		_running = false
		_bullets.clear()
		_warnings.clear()
		pattern_finished.emit()


## The box glides toward the size of the pattern and stays centred on the screen.
func _fit_box(delta: float) -> void:
	size = _target_size if delta == 0.0 else size.lerp(_target_size, 1.0 - exp(-GLIDE * delta))
	position = (CENTER - size / 2.0).floor()


func _move_soul(delta: float) -> void:
	var direction := Vector2.ZERO
	if direction_provider.is_valid():
		direction = direction_provider.call()
	else:
		direction = Vector2(
			int(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)),
			int(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
		)
	_soul += direction.normalized() * SOUL_SPEED * delta
	_soul = _soul.clamp(Vector2.ONE * 5.0, size - Vector2.ONE * 5.0)


func _spawn() -> void:
	if not _announced and _shots == 0 and defenses.has(str(_pattern["counter"])) and _pattern.has("works_note"):
		_announced = true # the defense shows at once what it does
		note.emit(str(_pattern["works_note"]), true)
		defense_used.emit(str(_pattern["counter"]))
	var speed := float(_param("speed"))
	# Bullets start outside the box on the enemy's side, "lead" seconds before they reach it.
	var spawn_x := size.x + speed * float(_pattern.get("lead", 0.8))
	match str(_pattern["kind"]):
		"stream":
			# Guesses at random heights, all flying the same way at the same speed.
			_add(Vector2(spawn_x, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0))
		"sweep":
			# A wall of accounts with one gap. "gaps" is where the gap is in each wall, from 0 (top)
			# to 1 (bottom), so the gap walks up and down in a path that can be followed.
			var gap := float(_param("gap"))
			var gaps: Array = _pattern["gaps"]
			var gap_y := lerpf(gap / 2.0 + 8.0, size.y - gap / 2.0 - 8.0, float(gaps[_shots % gaps.size()]))
			var y := 6.0
			while y < size.y:
				if absf(y - gap_y) > gap / 2.0:
					_add(Vector2(spawn_x, y), Vector2(-speed, 0), _shots)
				y += float(_param("spacing"))
		"disguise":
			# Looks like a gift; turns hostile when it has crossed "reveal" of the box. With the counter it is
			# shown as what it is from the start (reveal is then larger than where it starts).
			_add(Vector2(spawn_x, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0), 0, {"revealed": false, "reveal_x": size.x * float(_param("reveal", 9.0))})
		"split":
			# A bullet that breaks into two copies after "split_after" seconds; the copies break again until
			# the generation limit ("generations") is reached.
			_add(Vector2(spawn_x, randf_range(10.0, size.y - 10.0)), Vector2(-speed, 0), 0, {"gen": 0, "age": 0.0})
		"flicker":
			# Bullets that fade out of sight and back, so the player has to remember where they were.
			_add(Vector2(spawn_x, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0), 0, {"phase": randf() * float(_param("period", 0.9))})
		"aimed":
			# A blinking line shows where the key will fly, then it flies along that line. Every
			# few shots it is a fan of keys with wide gaps between them.
			var from := Vector2(spawn_x, size.y * 0.4)
			var aim := (_soul - from).normalized()
			var volley_every := int(_param("volley_every", 0))
			var count := 1
			if volley_every > 0 and _shots % volley_every == volley_every - 1:
				count = int(_param("volley_count", 3))
			var step := deg_to_rad(float(_param("spread", 14.0)))
			var warning := float(_param("warning", 0.5))
			if defenses.has("alerts"):
				warning += float(_pattern.get("alert_extra", 0.0))
				if _shots == 0:
					note.emit("ALERT: unusual sign-in", true)
					defense_used.emit("alerts")
			for i in count:
				var offset := (i - (count - 1) / 2.0) * step
				_warnings.append({"from": from, "dir": aim.rotated(offset), "time": warning})


## A number of the pattern. Without the upgrade that counters the pattern, its "harsh" numbers win.
func _param(key: String, fallback: Variant = null) -> Variant:
	if not defenses.has(str(_pattern["counter"])):
		var harsh: Dictionary = _pattern.get("harsh", {})
		if harsh.has(key):
			return harsh[key]
	return _pattern.get(key, fallback)


func _add(pos: Vector2, vel: Vector2, wall: int = 0, extra: Dictionary = {}) -> void:
	var bullet := {"pos": pos, "vel": vel, "damage": int(_param("damage")), "wall": wall, "cracked": false}
	bullet.merge(extra)
	_bullets.append(bullet)


func _fire_warnings(delta: float) -> void:
	var waiting: Array[Dictionary] = []
	for w in _warnings:
		w["time"] = float(w["time"]) - delta
		if float(w["time"]) <= 0.0:
			_add(w["from"], w["dir"] * float(_param("speed")))
		else:
			waiting.append(w)
	_warnings = waiting


func _move_bullets(delta: float) -> void:
	var kept: Array[Dictionary] = []
	var born: Array[Dictionary] = [] # the copies of a split
	var radius := float(_pattern["radius"])
	var kind := str(_pattern["kind"])
	for b in _bullets:
		b["pos"] += b["vel"] * delta
		var pos: Vector2 = b["pos"]
		if pos.x < -20.0:
			_guess_missed()
			continue
		if pos.x > size.x + 300.0 or pos.y < -20.0 or pos.y > size.y + 20.0:
			continue
		if kind == "disguise" and not b["revealed"] and pos.x <= float(b["reveal_x"]):
			b["revealed"] = true # the mask comes off
		if kind == "split" and _split(b, born):
			continue # it broke into copies
		var harmless: bool = kind == "disguise" and not b["revealed"] # a gift is harmless until it turns
		if not harmless and _invincible <= 0.0 and pos.distance_to(_soul) < radius + SOUL_RADIUS:
			_invincible = INVINCIBLE_TIME
			_burst(_soul)
			_on_bullet_hit(b)
			continue # the bullet that hit the heart bursts with it
		kept.append(b)
	_bullets = kept
	_bullets.append_array(born)
	if _locked > 0.0 and not _bullets.is_empty() and str(_pattern["kind"]) == "stream":
		_bullets.clear() # the lock stops the guesses that were already on their way


## True when the player can see the bullet as a danger right now: a hidden spy bullet cannot be seen, and a
## disguised gift does not look dangerous before it turns. (Used by the drawing, and by the test bots, so they
## play like a person.)
func bullet_visible(b: Dictionary) -> bool:
	match str(_pattern["kind"]):
		"flicker":
			var period := float(_param("period", 0.9))
			return fmod(_time + float(b["phase"]), period) < period * float(_param("visible", 1.0))
		"disguise":
			return b["revealed"]
	return true


## A split bullet that is old enough breaks into two copies, unless it is of the last generation. True when it did.
func _split(b: Dictionary, born: Array[Dictionary]) -> bool:
	b["age"] = float(b["age"]) + get_physics_process_delta_time()
	if int(b["gen"]) >= int(_param("generations", 1)) or float(b["age"]) < float(_param("split_after", 0.8)):
		return false
	var spread := deg_to_rad(float(_param("split_angle", 32.0)))
	for side in [-1.0, 1.0]:
		var copy := b.duplicate()
		copy["vel"] = (b["vel"] as Vector2).rotated(spread * side) * 0.9
		copy["gen"] = int(b["gen"]) + 1
		copy["age"] = 0.0
		born.append(copy)
	if not _announced and defenses.has(str(_pattern["counter"])):
		_announced = true
		note.emit("PATCHED: a copy splits only once", true)
		defense_used.emit(str(_pattern["counter"]))
	return true


## A guess that flew past: with the lock defense, a few of them lock the attacker out.
func _guess_missed() -> void:
	if str(_pattern["kind"]) != "stream" or not defenses.has("lockout") or _locked > 0.0:
		return
	_failed_tries += 1
	if _failed_tries >= int(_pattern["lock_after"]):
		_failed_tries = 0
		_locked = float(_pattern["lock_time"])
		note.emit("LOCKED OUT: too many wrong tries", true)
		defense_used.emit("lockout")


## What a hit means depends on the pattern and on the defenses.
func _on_bullet_hit(b: Dictionary) -> void:
	var damage := int(b["damage"])
	match str(_pattern["kind"]):
		"sweep":
			if defenses.has("unique"):
				note.emit("Only this account is hit", true)
				defense_used.emit("unique")
			else:
				for other in _bullets:
					if other != b and other["wall"] == b["wall"] and not other["cracked"]:
						other["cracked"] = true
						other["vel"] *= CRACKED_SPEEDUP
		"aimed":
			if defenses.has("twostep"):
				damage = int(_pattern["reduced_damage"])
				note.emit("CODE NEEDED: mostly blocked", true)
				defense_used.emit("twostep")
	hit.emit(damage)


## A few pixels fly out of the heart when it is hit.
func _burst(at: Vector2) -> void:
	for i in 8:
		_sparks.append({"pos": at, "vel": Vector2.RIGHT.rotated(TAU * i / 8.0 + randf() * 0.4) * randf_range(35.0, 70.0), "life": 0.35})


func _move_sparks(delta: float) -> void:
	var kept: Array[Dictionary] = []
	for s in _sparks:
		s["life"] = float(s["life"]) - delta
		if float(s["life"]) > 0.0:
			s["pos"] += s["vel"] * delta
			kept.append(s)
	_sparks = kept


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FILL)
	draw_rect(Rect2(Vector2.ZERO, size), WARNING if is_harder and _running else BORDER, false, 1.0)
	if _running and is_harder:
		draw_string(FONT, Vector2(0, -4), "HARDER VERSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, CRACKED) # above the box, like the lock counter
	elif _running and defenses.has("lockout") and str(_pattern["kind"]) == "stream":
		var text := "LOCKED OUT" if _locked > 0.0 else "FAILED TRIES %d / %d" % [_failed_tries, int(_pattern["lock_after"])]
		draw_string(FONT, Vector2(0, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, AMBER) # above the box, so bullets never cover it
	for w in _warnings:
		# A dashed line from the enemy to where the key will fly. It blinks.
		if int(float(w["time"]) * 14.0) % 2 == 0:
			var from: Vector2 = w["from"]
			var dir: Vector2 = w["dir"]
			for i in range(0, 60, 2):
				draw_rect(Rect2((from + dir * (i * 5.0)).floor(), Vector2(2, 2)), WARNING)
	var rotate_bullets := bool(_pattern.get("rotate", false))
	var kind := str(_pattern["kind"])
	for b in _bullets:
		var angle: float = (b["vel"] as Vector2).angle() if rotate_bullets else 0.0
		var texture := _texture
		var tint := CRACKED if b["cracked"] else Color.WHITE
		if kind == "disguise" and b["revealed"]:
			texture = _texture_real
		elif kind == "split" and int(b["gen"]) > 0:
			texture = _texture_copy
		elif kind == "flicker" and not bullet_visible(b):
			tint = Color(1, 1, 1, 0.1) # out of sight: only a faint trace is left
		draw_bullet(self, texture, b["pos"], angle, float(_pattern.get("scale", 1)), tint)
	for s in _sparks:
		draw_rect(Rect2((s["pos"] as Vector2).floor(), Vector2(2, 2)), SPARK)
	if _invincible <= 0.0 or int(_invincible * 12.0) % 2 == 0: # the heart blinks while it cannot be hit
		draw_texture(HEART, (_soul - Vector2(4.5, 4.5)).floor())


## Draws one bullet sprite centred on pos. Used by the arena and by the icon of the next pattern.
static func draw_bullet(canvas: CanvasItem, texture: Texture2D, pos: Vector2, angle: float, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	canvas.draw_set_transform(pos.floor() if angle == 0.0 else pos, angle, Vector2.ONE * scale)
	canvas.draw_texture(texture, -texture.get_size() / 2.0, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
