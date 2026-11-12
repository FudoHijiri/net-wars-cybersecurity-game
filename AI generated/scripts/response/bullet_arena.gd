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
## hostile), split (a bullet that breaks into copies) and flicker (a bullet that fades in and out) (Malware),
## creep (a lock that spreads over a grid of cells), demand (a bar that fills while notes fall, then one wall comes)
## and twin (a pair of files, one from each side) (Ransomware), inside (a badge that appears inside the box and
## bursts), ramp (a trickle that grows until an alert stops it) and carry (carriers that take files out of the
## box unless the heart guards them) (Insider Threat).

signal hit(damage: int)
signal pattern_finished
## A short message about what just happened, for the player. good is true when a defense worked.
signal note(text: String, good: bool)
## A defense did its job (its id), so the result line after the pattern can name it.
signal defense_used(id: String)
## A hit of the "leak" pattern that adds Leak to the player (emitted just before `hit`).
signal leaked(amount: int)
## A real envelope of the "bait" pattern was touched: HP the player gets back.
signal healed(amount: int)

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
const SPARK := Color(0.95686275, 0.95686275, 0.95686275, 1)

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
var _cells := {} # creep: Vector2i of a cell -> {locked, time}; a cell that is not locked yet blinks for "time" seconds
var _spread_in := 0.0 # creep: seconds until the lock spreads one more ring
var _demand := 0.0 # demand: how full the bar is, 0 to 1
var _wall_sent := false # demand: the first wall of the full bar has come
var _walls_left := 0 # demand: more walls to send after the first (the harder version sends two)
var _wall_in := 0.0 # demand: seconds until the next wall
var _badges: Array[Dictionary] = [] # inside: {pos, time} a badge that is about to burst into a ring of bullets
var _alerted := false # ramp: the alert fired and the copying stopped
var _items: Array[Dictionary] = [] # carry: {pos, state} the files in the box; state is "here", "carried" or "gone"
var _carriers: Array[Dictionary] = [] # carry: {pos, target, out, load} a carrier on its way to a file or out of the box
var _lane_calls: Array[Dictionary] = [] # lanes: {lane, time} a lane that is lit and will fire in `time` seconds
var _last_lane := -1 # lanes: the lane that fired last, so the next one is another
var _announced_lane := false # lanes: the upgrade has been shown at work
var _sources: Array[Dictionary] = [] # swarm: {pos, fired} the places on the edge that shoot at the heart
var _swarm_calls: Array[Dictionary] = [] # swarm: {source, time} a source that is lit and fires in `time` seconds
var _held := {} # inject: the pieces the heart holds, piece kind ("quote" or "code") -> seconds left
var _announced_inject := false # inject: the upgrade has been shown at work


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
	_cells.clear()
	_badges.clear()
	_carriers.clear()
	_lane_calls.clear()
	_last_lane = -1
	_announced_lane = false
	_swarm_calls.clear()
	_held.clear()
	_announced_inject = false
	_make_sources()
	_alerted = false
	_demand = 0.0
	_wall_sent = false
	_walls_left = 0
	_time = 0.0
	_spawn_in = 0.7 + warning_bonus # the box needs a moment to reach its size, and the player to see it
	_spread_in = _spawn_in + float(_param("spread_every", 1.4))
	_make_items()
	_shots = 0
	_failed_tries = 0
	_locked = 0.0
	_invincible = 0.0
	_soul = _target_size / 2.0 # the heart starts in the middle of the box
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
	_cells.clear()
	_badges.clear()
	_carriers.clear()
	_lane_calls.clear()
	_swarm_calls.clear()
	_held.clear()
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
		_spawn_in += _next_interval()
		_spawn()
		_shots += 1
	_update_creep(delta)
	_update_demand(delta)
	_update_badges(delta)
	_update_carriers(delta)
	_update_lanes(delta)
	_update_swarm(delta)
	_update_inject(delta)
	_update_ramp()
	_fire_warnings(delta)
	_move_bullets(delta)
	_move_sparks(delta)
	queue_redraw()
	if _time >= float(_pattern["duration"]) and _bullets.is_empty() and _warnings.is_empty() and _badges.is_empty() and _carriers.is_empty() and _lane_calls.is_empty() and _swarm_calls.is_empty():
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
		"inside":
			_place_badge() # a badge appears inside the box and bursts (see _update_badges)
		"ramp":
			# Small slow bullets from the enemy's side; the gaps between them shrink over the pattern (see _next_interval).
			_add(Vector2(spawn_x, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0))
		"leak":
			# The same, in a steady stream: each hit is tiny, and adds Leak (see _on_bullet_hit).
			_add(Vector2(spawn_x, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0))
		"blob":
			# One huge package that homes toward the heart (see _move_bullets); a new one only when the last is gone.
			if not _bullets.any(func(b: Dictionary) -> bool: return b.get("blob", false)):
				var packages := int(_param("blobs", 1)) # the harder version sends more than one
				for i in packages:
					var y := size.y * 0.5 + (i - (packages - 1) / 2.0) * 44.0 + randf_range(-10.0, 10.0)
					_add(Vector2(size.x + 14.0 + i * 24.0, y), Vector2(-speed, 0), 0, {"blob": true, "age": 0.0})
		"lanes":
			_light_lane() # one lane is lit, then fires a volley across the whole box (see _update_lanes)
		"flood":
			_spawn_flood(speed)
		"swarm":
			_light_source() # a source on the edge is lit, then shoots at where the heart is (see _update_swarm)
		"drip":
			_spawn_drip()
		"bait":
			_spawn_bait(speed)
		"doomwall":
			# The key upgrade is missing: a wall over the whole height of the box, with no gap, so it cannot be dodged.
			var spacing := float(_param("spacing", 8))
			var wall_y := 4.0
			while wall_y < size.y:
				_add(Vector2(spawn_x, wall_y), Vector2(-speed, 0), _shots)
				wall_y += spacing
		"inject":
			# Pieces of a quote and of code drift across. One alone is harmless; the heart holds what it touches (see _collect).
			_add(Vector2(spawn_x, randf_range(8.0, size.y - 8.0)), Vector2(-speed, randf_range(-6.0, 6.0)), 0, {"frag": "quote" if randf() < 0.5 else "code", "radius": float(_param("radius", 4.0))})
		"carry":
			_send_carrier()
		"creep":
			_seed_lock() # a padlock appears on one cell; the lock then spreads (see _update_creep)
		"demand":
			# Slow notes fall from the top while the demand bar fills (see _update_demand).
			_add(Vector2(randf_range(6.0, size.x - 6.0), -10.0), Vector2(0, speed))
		"twin":
			# A threat from the right and, unless the stolen copy is useless, its copy from the left.
			var y := randf_range(10.0, size.y - 10.0)
			_add(Vector2(spawn_x, y), Vector2(-speed, 0))
			if not defenses.has(str(_pattern["counter"])):
				var copy_y := clampf(size.y - y + randf_range(-12.0, 12.0), 10.0, size.y - 10.0)
				_add(Vector2(-speed * float(_pattern.get("lead", 0.8)), copy_y), Vector2(speed, 0), 0, {"copy": true})
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


# --- inside: the badge that bursts (Trusted access) ---

## A badge appears inside the box and blinks for "warn" seconds. With the upgrade that counters it, only in the far
## part of the box (from "far_from" of its width on); without it anywhere, even close to the heart.
func _place_badge() -> void:
	var far := defenses.has(str(_pattern["counter"]))
	var low_x := size.x * float(_pattern.get("far_from", 0.62)) if far else 8.0
	var at := Vector2.ZERO
	for attempt in 14:
		at = Vector2(randf_range(low_x, size.x - 8.0), randf_range(8.0, size.y - 8.0))
		if at.distance_to(_soul) >= float(_param("min_distance", 30.0)):
			break
	_badges.append({"pos": at, "time": float(_param("warn", 0.7))})


func _update_badges(delta: float) -> void:
	var waiting: Array[Dictionary] = []
	for badge in _badges:
		badge["time"] = float(badge["time"]) - delta
		if float(badge["time"]) > 0.0:
			waiting.append(badge)
			continue
		var count := int(_param("count", 6))
		var turn := randf() * TAU
		for i in count:
			_add(badge["pos"], Vector2.RIGHT.rotated(turn + TAU * i / count) * float(_param("speed")))
		_burst(badge["pos"])
	_badges = waiting


func _draw_badges() -> void:
	for badge in _badges:
		var at: Vector2 = badge["pos"]
		draw_arc(at, 9.0 + float(badge["time"]) * 6.0, 0.0, TAU, 20, GameColors.fill(&"bad"), 1.0) # the ring closes in as it bursts
		if int(float(badge["time"]) * 12.0) % 2 == 0:
			draw_bullet(self, _texture, at, 0.0)


# --- ramp: the slow copy that grows until an alert (Slow copy) ---

## The seconds until the next bullet: fixed for most patterns, shrinking over the pattern for the slow copy.
func _next_interval() -> float:
	if str(_pattern["kind"]) == "ramp":
		var progress := clampf(_time / float(_pattern["duration"]), 0.0, 1.0)
		return lerpf(float(_param("start_interval", 0.9)), float(_param("end_interval", 0.2)), progress)
	return float(_param("interval"))


## With the upgrade that counters it, an alert fires part of the way through: the copying stops and the pattern ends.
func _update_ramp() -> void:
	if str(_pattern["kind"]) != "ramp" or _alerted or not defenses.has(str(_pattern["counter"])):
		return
	if _time >= float(_pattern["duration"]) * float(_pattern.get("alert_at", 0.5)):
		_alerted = true
		_locked = 999.0 # nothing more is copied
		_time = maxf(_time, float(_pattern["duration"]))
		note.emit("ALERT: the copying stopped", true)


## How much has been copied: the bar under the box.
func _draw_copied_bar() -> void:
	var share := clampf(_time / float(_pattern["duration"]), 0.0, 1.0)
	var y := size.y + 3.0
	draw_rect(Rect2(0.0, y, size.x, 4.0), FILL)
	draw_rect(Rect2(0.0, y, size.x, 4.0), BORDER, false, 1.0)
	draw_rect(Rect2(1.0, y + 1.0, (size.x - 2.0) * share, 2.0), GameColors.bad if share > 0.8 else GameColors.highlight)
	var label := "COPIED %d%%" % roundi(share * 100.0)
	if _alerted:
		label = "ALERT: COPYING STOPPED AT %d%%" % roundi(share * 100.0)
	draw_string(FONT, Vector2(0.0, y + 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.highlight)


# --- carry: the files that walk out (Walk-out) ---

func _make_items() -> void:
	_items.clear()
	for spot: Array in _pattern.get("items", []):
		_items.append({"pos": Vector2(_target_size.x * float(spot[0]), _target_size.y * float(spot[1])), "state": "here"})


func _send_carrier() -> void:
	var open: Array[int] = []
	for i in _items.size():
		var taken := false
		for carrier in _carriers:
			taken = taken or (int(carrier["target"]) == i and not carrier["out"])
		if _items[i]["state"] == "here" and not taken:
			open.append(i)
	if open.is_empty():
		return
	_carriers.append({"pos": Vector2(size.x + 10.0, randf_range(10.0, size.y - 10.0)), "target": open[randi() % open.size()], "out": false, "load": -1})


## True while the heart is close to a file: nothing can take it then.
func _guarding(at: Vector2) -> bool:
	return _soul.distance_to(at) < float(_pattern.get("guard_radius", 22.0))


func _update_carriers(delta: float) -> void:
	if str(_pattern["kind"]) != "carry":
		return
	var speed := float(_param("carrier_speed", 90.0))
	var kept: Array[Dictionary] = []
	for carrier in _carriers:
		var item: Dictionary = _items[int(carrier["target"])]
		if not carrier["out"]:
			var to: Vector2 = item["pos"] - carrier["pos"]
			carrier["pos"] += to.normalized() * speed * delta
			if to.length() < 5.0:
				carrier["out"] = true
				if item["state"] == "here" and not _guarding(item["pos"]):
					item["state"] = "carried"
					carrier["load"] = int(carrier["target"])
				elif item["state"] == "here":
					note.emit("GUARDED: it could not take the file", true)
		else:
			carrier["pos"] += Vector2.RIGHT * speed * 1.2 * delta
			if (carrier["pos"] as Vector2).x > size.x + 14.0:
				if int(carrier["load"]) >= 0:
					_items[int(carrier["load"])]["state"] = "gone"
					note.emit("A FILE LEFT", false)
					hit.emit(int(_param("loss_damage", 6)))
				continue
		if _invincible <= 0.0 and (carrier["pos"] as Vector2).distance_to(_soul) < float(_pattern["radius"]) + SOUL_RADIUS:
			_invincible = INVINCIBLE_TIME
			_burst(_soul)
			hit.emit(int(_param("damage")))
		kept.append(carrier)
	_carriers = kept


func _draw_carry() -> void:
	var marked := defenses.has(str(_pattern["counter"])) # with the upgrade, the file a carrier wants is marked
	for item in _items:
		if item["state"] == "gone":
			continue
		var at: Vector2 = item["pos"]
		if item["state"] == "here":
			draw_bullet(self, _texture_copy, at, 0.0)
			if _guarding(at):
				draw_arc(at, float(_pattern.get("guard_radius", 22.0)), 0.0, TAU, 24, Color(GameColors.block, 0.8), 1.0) # the guarded file glows
	for carrier in _carriers:
		var at: Vector2 = carrier["pos"]
		if marked and not carrier["out"]:
			var target: Vector2 = _items[int(carrier["target"])]["pos"]
			for dot in range(1, 12):
				draw_rect(Rect2(at.lerp(target, dot / 12.0).floor(), Vector2(2, 2)), GameColors.fill(&"bad"))
			draw_arc(target, 8.0, 0.0, TAU, 14, GameColors.fill(&"bad"), 1.0)
		draw_bullet(self, _texture, at, 0.0)
		if int(carrier["load"]) >= 0:
			draw_bullet(self, _texture_copy, at + Vector2(0, -8), 0.0)


# --- creep: the lock that spreads (Mass lock) ---

func _grid() -> Vector2i:
	var cell := float(_pattern.get("cell", 16))
	return Vector2i(int(_target_size.x / cell), int(_target_size.y / cell))


## With the upgrade that counters it, the walls between the folders stop the lock.
func _walls_up() -> bool:
	return _pattern.has("wall_cols") and defenses.has(str(_pattern["counter"]))


func _lock_cap() -> int:
	var grid := _grid()
	return int(float(_param("cap", 0.4)) * grid.x * grid.y)


## A padlock appears on a free cell, not near the heart. It blinks for "warn" seconds, then it is locked.
func _seed_lock() -> void:
	if _cells.size() >= _lock_cap():
		return
	var grid := _grid()
	var cell := float(_pattern.get("cell", 16))
	var options: Array[Vector2i] = []
	for x in grid.x:
		for y in grid.y:
			var at := Vector2i(x, y)
			if not _cells.has(at) and (Vector2(x + 0.5, y + 0.5) * cell).distance_to(_soul) > cell * 3.0:
				options.append(at)
	if not options.is_empty():
		_cells[options[randi() % options.size()]] = {"locked": false, "time": float(_param("warn", 0.6))}


func _update_creep(delta: float) -> void:
	if str(_pattern["kind"]) != "creep":
		return
	for at: Vector2i in _cells:
		var state: Dictionary = _cells[at]
		if not state["locked"]:
			state["time"] = float(state["time"]) - delta
			if float(state["time"]) <= 0.0:
				state["locked"] = true
	_spread_in -= delta
	if _spread_in <= 0.0:
		_spread_in += float(_param("spread_every", 1.4))
		_spread()
	var cell := float(_pattern.get("cell", 16))
	var heart := Vector2i(int(_soul.x / cell), int(_soul.y / cell))
	if _invincible <= 0.0 and _cells.has(heart) and _cells[heart]["locked"]:
		_invincible = INVINCIBLE_TIME
		_burst(_soul)
		hit.emit(int(_param("damage")))


## Every locked cell locks its free neighbors: one ring at a time. A wall (with the upgrade) stops it.
func _spread() -> void:
	var grid := _grid()
	var fresh: Array[Vector2i] = []
	for at: Vector2i in _cells:
		if not _cells[at]["locked"]:
			continue
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := at + step
			if next.x < 0 or next.y < 0 or next.x >= grid.x or next.y >= grid.y or _cells.has(next) or fresh.has(next):
				continue
			if _crosses_wall(at, next):
				continue
			fresh.append(next)
	fresh.shuffle()
	for next in fresh:
		if _cells.size() >= _lock_cap():
			break
		_cells[next] = {"locked": false, "time": float(_param("warn", 0.6))}


func _crosses_wall(from: Vector2i, to: Vector2i) -> bool:
	if not _walls_up():
		return false
	for column: Variant in _pattern["wall_cols"]:
		if (from.x < int(column)) != (to.x < int(column)):
			return true
	return false


# --- demand: the bar that fills (Ransom demand) ---

## The bar fills with time. When it is full, one wall comes. With the upgrade that counters it the bar never gets
## past "fill_cap": there is nothing to ask for.
func _update_demand(delta: float) -> void:
	if str(_pattern["kind"]) != "demand":
		return
	var capped := defenses.has(str(_pattern["counter"]))
	_demand = minf(_time / float(_param("fill_time", 5.0)), float(_pattern.get("fill_cap", 0.6)) if capped else 1.0)
	if not capped and not _wall_sent and _demand >= 1.0:
		_wall_sent = true
		_walls_left = int(_param("walls", 1)) - 1
		_wall_in = float(_param("wall_every", 1.3))
		_send_wall()
	elif _walls_left > 0:
		_wall_in -= delta
		if _wall_in <= 0.0:
			_walls_left -= 1
			_wall_in = float(_param("wall_every", 1.3))
			_send_wall()


## One wall with a gap, from the enemy's side. The gap is wide enough to reach from anywhere in the box, because
## the wall appears far away, so the player sees it long before it arrives.
func _send_wall() -> void:
	note.emit("DEMAND: a wall comes", false)
	var gap := float(_param("wall_gap", 40.0))
	var speed := float(_param("wall_speed", 85.0))
	var gap_y := randf_range(gap / 2.0 + 8.0, size.y - gap / 2.0 - 8.0)
	var spawn_x := size.x + speed * float(_pattern.get("lead", 1.5))
	var y := 6.0
	while y < size.y:
		if absf(y - gap_y) > gap / 2.0:
			_add(Vector2(spawn_x, y), Vector2(-speed, 0), 1, {"damage": int(_param("wall_damage", 9))})
		y += float(_param("wall_spacing", 8))


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


# --- flood: a dense stream, from the right and from the other sides ---

## With the upgrade that counters it, the load is shared: one side at a time (the right side most of the time), and the
## side that is firing is marked on the box. Without it, the right side and one more side fire at once, every time.
func _flood_side() -> String:
	var order: Array = _pattern.get("side_order", ["right", "top", "right", "bottom"])
	return str(order[int(_time / float(_param("side_time", 1.8))) % order.size()])


func _flood_bullet(side: String, speed: float) -> void:
	match side:
		"right":
			_add(Vector2(size.x + 6.0, randf_range(6.0, size.y - 6.0)), Vector2(-speed, 0))
		"left":
			_add(Vector2(-6.0, randf_range(6.0, size.y - 6.0)), Vector2(speed, 0))
		"top":
			_add(Vector2(randf_range(6.0, size.x - 6.0), -6.0), Vector2(0, speed))
		"bottom":
			_add(Vector2(randf_range(6.0, size.x - 6.0), size.y + 6.0), Vector2(0, -speed))


func _spawn_flood(speed: float) -> void:
	if defenses.has(str(_pattern["counter"])):
		_flood_bullet(_flood_side(), speed)
		if not _announced:
			_announced = true
			note.emit(str(_pattern.get("works_note", "")), true)
			defense_used.emit(str(_pattern["counter"]))
		return
	_flood_bullet("right", speed)
	_flood_bullet(["top", "bottom", "left"][randi() % 3], speed)


## The edge of the box that is firing, marked while the load is shared.
func _draw_flood_side() -> void:
	if not defenses.has(str(_pattern["counter"])):
		return
	var color := Color(GameColors.block, 0.9)
	match _flood_side():
		"right":
			draw_rect(Rect2(size.x - 2.0, 0.0, 2.0, size.y), color)
		"left":
			draw_rect(Rect2(0.0, 0.0, 2.0, size.y), color)
		"top":
			draw_rect(Rect2(0.0, 0.0, size.x, 2.0), color)
		"bottom":
			draw_rect(Rect2(0.0, size.y - 2.0, size.x, 2.0), color)


# --- bait: envelopes with a word on them; the fake ones hurt, the real ones heal ---

## The words on the envelopes: red-flag words on the fake ones, ordinary words on the real ones.
func _spawn_bait(speed: float) -> void:
	var fake := randf() < float(_param("fake_share", 0.6))
	var words: Array = _pattern.get("flags", ["URGENT", "PRIZE", "VERIFY", "FREE"]) if fake else _pattern.get("real_words", ["MEETING", "LUNCH", "NOTICE", "PAYSLIP"])
	var from := Vector2(size.x + 12.0, randf_range(12.0, size.y - 6.0))
	var vel := Vector2(-speed, 0.0)
	if fake and randf() < float(_param("aim_share", 0.0)): # the harder version sends some fakes at the heart
		vel = (_soul - from).normalized() * speed
	_add(from, vel, 0, {"bait": true, "real": not fake, "label": str(words[randi() % words.size()]), "radius": float(_param("radius")),
			"marked": fake and defenses.has(str(_pattern["counter"]))})


## A real envelope touched: a little HP back (it does not make the heart blink, and it is gone).
func _touch_real(b: Dictionary) -> void:
	for i in 5:
		_sparks.append({"pos": b["pos"], "vel": Vector2.RIGHT.rotated(TAU * i / 5.0) * randf_range(20.0, 40.0), "life": 0.3})
	healed.emit(int(_param("heal", 2)))


# --- inject: pieces of a quote and of code; two different pieces held together become a command and hit ---

func _other_piece(kind: String) -> String:
	return "code" if kind == "quote" else "quote"


## The heart touched a piece. With the upgrade that counters it the piece is cleaned (it is gone and held by no one).
## Without it the heart holds the piece; holding a quote and a piece of code at the same time runs the code: a hit.
func _collect(b: Dictionary) -> void:
	var kind := str(b["frag"])
	for i in 4:
		_sparks.append({"pos": b["pos"], "vel": Vector2.RIGHT.rotated(TAU * i / 4.0) * randf_range(15.0, 30.0), "life": 0.25})
	if defenses.has(str(_pattern["counter"])):
		if not _announced_inject:
			_announced_inject = true
			note.emit(str(_pattern.get("works_note", "")), true)
			defense_used.emit(str(_pattern["counter"]))
		return
	if _held.has(_other_piece(kind)):
		_held.clear()
		_invincible = INVINCIBLE_TIME
		_burst(_soul)
		hit.emit(int(_param("damage")))
		return
	_held[kind] = float(_param("hold_time", 3.0))


func _update_inject(delta: float) -> void:
	if str(_pattern["kind"]) != "inject":
		return
	for kind: String in _held.keys():
		_held[kind] = float(_held[kind]) - delta
		if float(_held[kind]) <= 0.0:
			_held.erase(kind)


## What the heart holds, shown under the box (and how long it will hold it, when it lets go at all).
func _draw_inject() -> void:
	var y := size.y + 3.0
	if defenses.has(str(_pattern["counter"])):
		draw_string(FONT, Vector2(0.0, y + 8.0), "INPUT CHECKED: PIECES ARE CLEANED", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.block)
		return
	draw_string(FONT, Vector2(0.0, y + 8.0), "HOLDING: NOTHING" if _held.is_empty() else "HOLDING:", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.highlight)
	var x := 52.0
	for kind: String in ["quote", "code"]:
		if not _held.has(kind):
			continue
		draw_bullet(self, _texture if kind == "quote" else _texture_copy, Vector2(x + 5.0, y + 5.0), 0.0)
		if float(_param("hold_time", 3.0)) < 50.0:
			draw_rect(Rect2(x + 12.0, y + 3.0, 20.0 * clampf(float(_held[kind]) / float(_param("hold_time", 3.0)), 0.0, 1.0), 3.0), GameColors.highlight)
		x += 40.0
	if not _held.is_empty():
		draw_string(FONT, Vector2(0.0, y + 17.0), "QUOTE + CODE = HIT", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.bad)


# --- swarm: many sources that shoot at where the heart is ---

func _make_sources() -> void:
	_sources.clear()
	if str(_pattern.get("kind", "")) != "swarm":
		return
	for at: Array in _pattern.get("sources", [[1.0, 0.2], [1.0, 0.5], [1.0, 0.8], [0.3, 0.0], [0.7, 1.0], [0.0, 0.5]]):
		_sources.append({"pos": Vector2(float(at[0]), float(at[1])), "fired": 0}) # as shares of the box, on its edge


func _source_pos(source: Dictionary) -> Vector2:
	return Vector2(float((source["pos"] as Vector2).x) * size.x, float((source["pos"] as Vector2).y) * size.y)


## A source that can still fire (with the counter, each may fire only "source_cap" times) lights up for "warn" seconds.
func _light_source() -> void:
	var capped := defenses.has(str(_pattern["counter"]))
	var open: Array[int] = []
	for i in _sources.size():
		if not capped or int(_sources[i]["fired"]) < int(_pattern.get("source_cap", 2)):
			open.append(i)
	if open.is_empty():
		return
	var pick: int = open[randi() % open.size()]
	_sources[pick]["fired"] = int(_sources[pick]["fired"]) + 1
	_swarm_calls.append({"source": pick, "time": float(_param("warn", 0.35))})
	if capped and not _announced:
		_announced = true
		note.emit(str(_pattern.get("works_note", "")), true)
		defense_used.emit(str(_pattern["counter"]))


func _update_swarm(delta: float) -> void:
	var waiting: Array[Dictionary] = []
	for call in _swarm_calls:
		call["time"] = float(call["time"]) - delta
		if float(call["time"]) <= 0.0:
			var from := _source_pos(_sources[int(call["source"])])
			var aim := (_soul - from).normalized() # where the heart is NOW: it does not follow
			for i in int(_param("burst", 1)):
				_add(from - aim * (i * 7.0), aim * float(_param("speed")))
		else:
			waiting.append(call)
	_swarm_calls = waiting


## The sources: small squares on the edge, lit when about to shoot; with the counter a source that has shot its share shows a cross.
func _draw_swarm() -> void:
	var capped := defenses.has(str(_pattern["counter"]))
	for i in _sources.size():
		var at := _source_pos(_sources[i]).floor()
		var done: bool = capped and int(_sources[i]["fired"]) >= int(_pattern.get("source_cap", 2))
		var lit := false
		for call in _swarm_calls:
			if int(call["source"]) == i and int(float(call["time"]) * 14.0) % 2 == 0:
				lit = true
		draw_rect(Rect2(at - Vector2(3, 3), Vector2(7, 7)), FILL)
		draw_rect(Rect2(at - Vector2(3, 3), Vector2(7, 7)), GameColors.bad if lit else (BORDER if not done else Color(BORDER, 0.4)), false, 1.0)
		if done:
			draw_line(at - Vector2(2, 2), at + Vector2(2, 2), GameColors.block, 1.0)
			draw_line(at + Vector2(-2, 2), at + Vector2(2, -2), GameColors.block, 1.0)
		elif lit:
			draw_rect(Rect2(at - Vector2(1, 1), Vector2(3, 3)), GameColors.bad)


# --- drip: connections that arrive slowly, stop in the box and stay ---

func _spawn_drip() -> void:
	var held := _bullets.filter(func(b: Dictionary) -> bool: return b.get("held", false) or b.has("target")).size()
	if held >= int(_param("max_held", 8)):
		return # the box never fills up: there is always a way through
	var margin := 12.0
	var target := Vector2(randf_range(margin, size.x - margin), randf_range(margin, size.y - margin))
	var start := Vector2(size.x + 8.0, target.y) if randf() < 0.5 else Vector2(target.x, -8.0 if randf() < 0.5 else size.y + 8.0)
	var speed := float(_param("speed"))
	_add(start, (target - start).normalized() * speed, 0, {"target": target, "held": false, "age": 0.0, "radius": float(_param("radius"))})


## A connection that has reached its place stops and stays. With the upgrade that counters it, it closes after "hold_time" seconds.
## All of them close when the pattern is over.
func _drip_step(b: Dictionary, delta: float) -> bool:
	if b.get("held", false):
		b["age"] = float(b["age"]) + delta
		var closing: bool = _time >= float(_pattern["duration"]) or float(b["age"]) >= float(_param("hold_time", 999.0))
		if closing and defenses.has(str(_pattern["counter"])) and not _announced:
			_announced = true
			note.emit("CLOSED: idle connections do not stay", true)
			defense_used.emit(str(_pattern["counter"]))
		return closing
	if (b["pos"] as Vector2).distance_to(b["target"]) <= (b["vel"] as Vector2).length() * delta + 0.5:
		b["pos"] = b["target"]
		b["vel"] = Vector2.ZERO
		b["held"] = true
	return false


# --- lanes: the hidden door ---

func _lane_y(lane: int) -> float:
	return (float(lane) + 0.5) * size.y / float(_param("lanes", 5))


## One lane (or "multi" lanes at once, in the harder version), not the one that fired last, lights up for "warn" seconds:
## long with the upgrade that counters it, a flash without.
func _light_lane() -> void:
	var count := int(_param("lanes", 5))
	var lit: Array[int] = []
	for i in mini(int(_param("multi", 1)), count - 1):
		var lane := randi() % count
		while lane == _last_lane or lit.has(lane):
			lane = (lane + 1) % count
		lit.append(lane)
		_lane_calls.append({"lane": lane, "time": float(_param("warn", 0.8))})
	_last_lane = lit[0]
	if defenses.has(str(_pattern["counter"])) and not _announced_lane:
		_announced_lane = true
		defense_used.emit(str(_pattern["counter"]))


func _update_lanes(delta: float) -> void:
	var waiting: Array[Dictionary] = []
	for call in _lane_calls:
		call["time"] = float(call["time"]) - delta
		if float(call["time"]) <= 0.0:
			for i in int(_param("count", 4)):
				_add(Vector2(size.x + 8.0 + i * float(_param("gap", 16.0)), _lane_y(int(call["lane"]))), Vector2(-float(_param("speed")), 0))
		else:
			waiting.append(call)
	_lane_calls = waiting


## The lanes as faint lines, and the lit lane as a band that blinks before it fires.
func _draw_lanes() -> void:
	var count := int(_param("lanes", 5))
	for lane in count:
		var y := floorf(_lane_y(lane))
		for x in range(0, int(size.x), 6):
			draw_rect(Rect2(float(x), y, 2.0, 1.0), Color(BORDER, 0.35))
	for call in _lane_calls:
		var y := floorf(_lane_y(int(call["lane"])))
		if int(float(call["time"]) * 14.0) % 2 == 0 or float(call["time"]) < 0.2:
			draw_rect(Rect2(0.0, y - 7.0, size.x, 15.0), Color(GameColors.bad, 0.35))
			draw_rect(Rect2(0.0, y - 7.0, size.x, 15.0), GameColors.bad, false, 1.0)


func _move_bullets(delta: float) -> void:
	var kept: Array[Dictionary] = []
	var born: Array[Dictionary] = [] # the copies of a split
	var radius := float(_pattern["radius"])
	var kind := str(_pattern["kind"])
	for b in _bullets:
		if b.get("blob", false):
			if _blob_step(b, born, delta):
				continue # it came apart into pieces
		if b.has("target") and _drip_step(b, delta):
			continue # a held connection closed
		if b.has("frag") and not _held.is_empty() and float(_param("pull", 0.0)) > 0.0 and not _held.has(str(b["frag"])):
			b["vel"] = (b["vel"] as Vector2).lerp((_soul - (b["pos"] as Vector2)).normalized() * float(_param("speed")), float(_param("pull")) * delta) # the harder version: the partner of a held piece looks for you
		b["pos"] += b["vel"] * delta
		var pos: Vector2 = b["pos"]
		var from_left: bool = (b["vel"] as Vector2).x > 0.0 # the copy of a twin starts left of the box and flies right
		if pos.x < -20.0 and not from_left:
			_guess_missed()
			continue
		if pos.x > size.x + (20.0 if from_left else 300.0) or pos.y < -20.0 or pos.y > size.y + 20.0:
			continue
		if kind == "disguise" and not b["revealed"] and pos.x <= float(b["reveal_x"]):
			b["revealed"] = true # the mask comes off
		if kind == "split" and _split(b, born):
			continue # it broke into copies
		if b.get("bait", false) and b["real"] and pos.distance_to(_soul) < float(b.get("radius", radius)) + SOUL_RADIUS:
			_touch_real(b)
			continue # a real envelope is taken, and gone
		if b.has("frag"): # a piece never hurts by itself: the heart collects it
			if pos.distance_to(_soul) < float(b["radius"]) + SOUL_RADIUS:
				_collect(b)
				continue
			kept.append(b)
			continue
		var harmless: bool = (kind == "disguise" and not b["revealed"]) or (b.get("bait", false) and b["real"]) # a gift is harmless until it turns, and a real envelope never hurts
		if not harmless and _invincible <= 0.0 and pos.distance_to(_soul) < float(b.get("radius", radius)) + SOUL_RADIUS:
			_invincible = INVINCIBLE_TIME
			_burst(_soul)
			_on_bullet_hit(b)
			continue # the bullet that hit the heart bursts with it
		kept.append(b)
	_bullets = kept
	_bullets.append_array(born)
	if _locked > 0.0 and not _bullets.is_empty() and str(_pattern["kind"]) == "stream":
		_bullets.clear() # the lock stops the guesses that were already on their way


## The big package of the Big grab: it turns toward the heart (slowly) for the whole pattern. With the upgrade that
## counters it, it comes apart after "split_after" seconds into three small pieces that do not home. True when it did.
func _blob_step(b: Dictionary, born: Array[Dictionary], delta: float) -> bool:
	b["age"] = float(b["age"]) + delta
	if defenses.has(str(_pattern["counter"])) and float(b["age"]) >= float(_param("split_after", 1.1)):
		var direction: Vector2 = (b["vel"] as Vector2).normalized()
		for turn in [-0.5, 0.0, 0.5]:
			var piece := {"pos": b["pos"], "vel": direction.rotated(turn) * float(_pattern.get("piece_speed", 70.0)), "damage": int(_pattern.get("piece_damage", 4)),
					"wall": 0, "cracked": false, "piece": true, "radius": 3.0}
			born.append(piece)
		if not _announced:
			_announced = true
			note.emit("FLAGGED: it comes apart", true)
			defense_used.emit(str(_pattern["counter"]))
		return true
	if _time < float(_pattern["duration"]):
		var vel: Vector2 = b["vel"]
		var to_heart: Vector2 = ((_soul - (b["pos"] as Vector2))).normalized()
		var most := float(_param("turn", 1.0)) * delta
		b["vel"] = vel.rotated(clampf(vel.angle_to(to_heart), -most, most))
	return false


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
		"leak":
			var leak := 0 if defenses.has(str(_pattern["counter"])) else int(_param("leak", 1))
			if leak > 0:
				leaked.emit(leak)
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
			# The counter is the pattern's own (Two-step on Day 1, the Security Key on Day 7): its hits do only "reduced_damage".
			if defenses.has(str(_pattern["counter"])) and _pattern.has("reduced_damage"):
				damage = int(_pattern["reduced_damage"])
				note.emit(str(_pattern.get("hit_note", "CODE NEEDED: mostly blocked")), true)
				defense_used.emit(str(_pattern["counter"]))
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
	draw_rect(Rect2(Vector2.ZERO, size), GameColors.fill(&"bad") if is_harder and _running else BORDER, false, 1.0)
	if _running and is_harder:
		draw_string(FONT, Vector2(0, -4), "HARDER VERSION", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.bad) # above the box, like the lock counter
	elif _running and defenses.has("lockout") and str(_pattern["kind"]) == "stream":
		var text := "LOCKED OUT" if _locked > 0.0 else "FAILED TRIES %d / %d" % [_failed_tries, int(_pattern["lock_after"])]
		draw_string(FONT, Vector2(0, -4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.highlight) # above the box, so bullets never cover it
	if _running and str(_pattern["kind"]) == "inside":
		_draw_badges()
	elif _running and str(_pattern["kind"]) == "ramp":
		_draw_copied_bar()
	elif _running and str(_pattern["kind"]) == "carry":
		_draw_carry()
	elif _running and str(_pattern["kind"]) == "lanes":
		_draw_lanes()
	elif _running and str(_pattern["kind"]) == "flood":
		_draw_flood_side()
	elif _running and str(_pattern["kind"]) == "swarm":
		_draw_swarm()
	elif _running and str(_pattern["kind"]) == "inject":
		_draw_inject()
	if _running and str(_pattern["kind"]) == "creep":
		_draw_creep()
	elif _running and str(_pattern["kind"]) == "demand":
		_draw_demand()
	for w in _warnings:
		# A dashed line from the enemy to where the key will fly. It blinks.
		if int(float(w["time"]) * 14.0) % 2 == 0:
			var from: Vector2 = w["from"]
			var dir: Vector2 = w["dir"]
			for i in range(0, 60, 2):
				draw_rect(Rect2((from + dir * (i * 5.0)).floor(), Vector2(2, 2)), GameColors.fill(&"bad"))
	var rotate_bullets := bool(_pattern.get("rotate", false))
	var kind := str(_pattern["kind"])
	for b in _bullets:
		var angle: float = (b["vel"] as Vector2).angle() if rotate_bullets else 0.0
		var texture := _texture
		var tint := GameColors.bad if b["cracked"] else Color.WHITE
		if kind == "disguise" and b["revealed"]:
			texture = _texture_real
		elif kind == "split" and int(b["gen"]) > 0:
			texture = _texture_copy
		elif kind == "flicker" and not bullet_visible(b):
			tint = Color(1, 1, 1, 0.1) # out of sight: only a faint trace is left
		elif kind == "twin" and b.get("copy", false):
			texture = _texture_copy
		elif kind == "blob" and b.get("piece", false):
			texture = _texture_copy
		elif kind == "inject" and str(b["frag"]) == "code":
			texture = _texture_copy # the piece of code (the other one is a quote)
		elif kind == "inside" or kind == "ramp":
			texture = _texture_copy # the small bullets of a burst and of the trickle
		draw_bullet(self, texture, b["pos"], angle, float(_param("scale", 1)), tint)
		if b.get("bait", false):
			_draw_bait_label(b)
	for s in _sparks:
		draw_rect(Rect2((s["pos"] as Vector2).floor(), Vector2(2, 2)), SPARK)
	if _invincible <= 0.0 or int(_invincible * 12.0) % 2 == 0: # the heart blinks while it cannot be hit
		draw_texture(HEART, (_soul - Vector2(4.5, 4.5)).floor())


## The word on an envelope, above it; a fake one with the Check the Sender upgrade also has a warning mark.
func _draw_bait_label(b: Dictionary) -> void:
	var at: Vector2 = (b["pos"] as Vector2).floor()
	var text := str(b["label"])
	var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	var color := Color.WHITE if not b.get("marked", false) else GameColors.bad
	draw_string_outline(FONT, at + Vector2(-width / 2.0, -7.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, 1, FILL)
	draw_string(FONT, at + Vector2(-width / 2.0, -7.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, color)
	if b.get("marked", false):
		draw_rect(Rect2(at + Vector2(5, -6), Vector2(3, 5)), GameColors.bad)
		draw_rect(Rect2(at + Vector2(5, 0), Vector2(3, 2)), GameColors.bad)


## The locked cells (red, with a padlock), the cells that are about to lock (they blink) and the walls.
func _draw_creep() -> void:
	var cell := float(_pattern.get("cell", 16))
	for at: Vector2i in _cells:
		var rect := Rect2(Vector2(at) * cell, Vector2(cell, cell))
		var state: Dictionary = _cells[at]
		if state["locked"]:
			draw_rect(rect, Color(GameColors.fill(&"bad"), 0.6))
			draw_rect(rect, GameColors.fill(&"bad"), false, 1.0)
			draw_bullet(self, _texture, rect.get_center(), 0.0)
		elif int(float(state["time"]) * 10.0) % 2 == 0:
			draw_rect(rect.grow(-1.0), GameColors.bad, false, 1.0)
	if _walls_up():
		for column: Variant in _pattern["wall_cols"]:
			draw_rect(Rect2(float(column) * cell - 1.0, 0.0, 2.0, size.y), Color(GameColors.block, 0.9))


## The demand bar under the box: it fills, and says what it is, or why it will not.
func _draw_demand() -> void:
	var y := size.y + 3.0
	draw_rect(Rect2(0.0, y, size.x, 4.0), FILL)
	draw_rect(Rect2(0.0, y, size.x, 4.0), BORDER, false, 1.0)
	draw_rect(Rect2(1.0, y + 1.0, (size.x - 2.0) * _demand, 2.0), GameColors.bad if _demand >= 1.0 else GameColors.highlight)
	var label := "DEMAND"
	if defenses.has(str(_pattern["counter"])):
		label = "OFFLINE: NOTHING TO ASK FOR"
	elif _wall_sent:
		label = "PAY NOW"
	draw_string(FONT, Vector2(0.0, y + 12.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, GameColors.highlight)


## Draws one bullet sprite centred on pos. Used by the arena and by the icon of the next pattern.
static func draw_bullet(canvas: CanvasItem, texture: Texture2D, pos: Vector2, angle: float, scale: float = 1.0, tint: Color = Color.WHITE) -> void:
	canvas.draw_set_transform(pos.floor() if angle == 0.0 else pos, angle, Vector2.ONE * scale)
	canvas.draw_texture(texture, -texture.get_size() / 2.0, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
