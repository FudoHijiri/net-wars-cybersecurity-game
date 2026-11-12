extends Node

## Autoload for the Display settings: a border or none, and the size of the window.
##
## The game is drawn at 640x360 and scaled up by whole numbers (project.godot: stretch mode
## "viewport", scale mode "integer"), so the sizes offered are 1x, 2x, 3x ... of that, and only the
## ones that fit the player's screen. Until the player chooses a size, the window is the biggest one
## that fits the screen (default_size()), not the project's window_width/height_override (1280x720),
## which is only where the engine first puts the window.
##
## There is no separate fullscreen setting. A borderless window as big as the screen is the engine's
## fullscreen mode (a window that merely covers the screen is a state Windows does not let go of when
## it is resized), and every other size is a plain window.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "display"
const KEY_BORDERLESS := "borderless"
const KEY_WIDTH := "window_width"
const KEY_HEIGHT := "window_height"

const BASE_SIZE := Vector2i(640, 360)
const MAX_SCALE := 6

## No title bar (the project starts that way: display/window/size/borderless).
var borderless: bool = true
## The window size, or Vector2i.ZERO while the player has not chosen one.
var window_size: Vector2i = Vector2i.ZERO

var _apply_count := 0
var _busy := false # _apply() is changing the window right now
var _settled_at := 0 # when the last change finished (msec): the window may still be settling right after it
var _check_in := 0.3


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		borderless = bool(config.get_value(SECTION, KEY_BORDERLESS, true))
		window_size = Vector2i(int(config.get_value(SECTION, KEY_WIDTH, 0)), int(config.get_value(SECTION, KEY_HEIGHT, 0)))
	_apply.call_deferred() # after the window has been created by the engine


## The window is only meant to have the size chosen in Settings. Windows still offers the title bar's maximize
## button (the engine keeps it on a window that cannot be resized), and a window made bigger that way is drawn
## wrongly (cut off, with the picture and the window no longer matching). So a few times a second the window is
## compared with the size it should have, and put back when it is not. (The engine's own size signal does not
## fire for a window changed by the title bar, so it is checked this way.)
func _process(delta: float) -> void:
	_check_in -= delta
	if _check_in > 0.0:
		return
	_check_in = 0.3
	_check_window()


func _check_window() -> void:
	if _busy or Time.get_ticks_msec() - _settled_at < 800:
		return
	var window := get_window()
	if window.mode == Window.MODE_MINIMIZED:
		return
	if fills_screen():
		if window.mode != Window.MODE_FULLSCREEN:
			_apply()
		return
	var got := DisplayServer.window_get_size()
	var wanted := current_size()
	if window.mode != Window.MODE_WINDOWED or absi(got.x - wanted.x) > 4 or absi(got.y - wanted.y) > 4:
		_apply()


## The room a window may take on the screen it is on. A window without a border may cover the whole
## screen; one with a title bar has to leave room for the taskbar and its own bar.
func screen_room(with_border: bool) -> Vector2i:
	var screen := DisplayServer.window_get_current_screen()
	if with_border:
		return DisplayServer.screen_get_usable_rect(screen).size - Vector2i(0, 40)
	return DisplayServer.screen_get_size(screen)


## The window sizes that fit the screen this window is on.
func available_sizes(with_border: bool = false) -> Array[Vector2i]:
	var room := screen_room(with_border)
	var sizes: Array[Vector2i] = []
	for scale in range(1, MAX_SCALE + 1):
		var candidate := BASE_SIZE * scale
		if candidate.x <= room.x and candidate.y <= room.y:
			sizes.append(candidate)
	if sizes.is_empty():
		sizes.append(BASE_SIZE)
	return sizes


## The size the window has when the player has not chosen one: the biggest that fits the screen.
func default_size(with_border: bool = false) -> Vector2i:
	return available_sizes(with_border).back()


## The size the window has now.
func current_size() -> Vector2i:
	return window_size if window_size != Vector2i.ZERO else default_size(not borderless)


## True when the window fills the whole screen: without a border and as big as the screen.
func fills_screen() -> bool:
	var screen_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	var size := current_size()
	return borderless and size.x >= screen_size.x and size.y >= screen_size.y


## Changes the window now. It is only kept (saved) by save(), so that Settings can ask the player
## first and go back with another set_display() if the player cannot see the result.
func set_display(new_borderless: bool, new_size: Vector2i) -> void:
	borderless = new_borderless
	window_size = new_size
	_apply()


func _apply() -> void:
	_apply_count += 1
	var this_apply := _apply_count
	_busy = true
	await _apply_steps(this_apply)
	if this_apply == _apply_count: # not replaced by a later change
		_busy = false
		_settled_at = Time.get_ticks_msec()


func _apply_steps(this_apply: int) -> void:
	var window := get_window()
	window.unresizable = true # the player picks the size in Settings; dragging an edge would not match the list
	if fills_screen():
		window.borderless = true
		window.mode = Window.MODE_FULLSCREEN
		return
	if window.mode != Window.MODE_WINDOWED:
		# Leaving fullscreen (or a maximized window): let the engine finish the change before the size is set.
		window.mode = Window.MODE_WINDOWED
		await get_tree().process_frame
		if this_apply != _apply_count:
			return # another change came while waiting; that one finishes the job
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	if DisplayServer.window_get_size().x >= screen_size.x and DisplayServer.window_get_size().y >= screen_size.y:
		# A window that covers the whole screen does not always shrink on Windows when it is only resized.
		# Taking it through "maximized" lets go of that state.
		window.mode = Window.MODE_MAXIMIZED
		await get_tree().process_frame
		if this_apply != _apply_count:
			return
		window.mode = Window.MODE_WINDOWED
		await get_tree().process_frame
		if this_apply != _apply_count:
			return
	window.borderless = borderless
	var size := current_size()
	var area := Rect2i(DisplayServer.screen_get_position(screen), screen_size) if borderless else DisplayServer.screen_get_usable_rect(screen)
	@warning_ignore("integer_division") # a pixel less on one side is fine
	window.position = area.position + (area.size - size) / 2
	window.size = size
	# Right after a change of border or mode Windows can give a window a pixel or two less than asked, and then
	# the picture is drawn a whole step smaller (the scale is a whole number). So the size is checked and asked again.
	for attempt in 3:
		await get_tree().process_frame
		await get_tree().process_frame
		if this_apply != _apply_count:
			return
		var got := DisplayServer.window_get_size()
		if got == size:
			return
		window.size = size + (size - got) if attempt > 0 else size


func save() -> void:
	# Load first so other saved settings are kept.
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.erase_section_key(SECTION, "fullscreen") # an older build had a fullscreen setting
	config.set_value(SECTION, KEY_BORDERLESS, borderless)
	config.set_value(SECTION, KEY_WIDTH, window_size.x)
	config.set_value(SECTION, KEY_HEIGHT, window_size.y)
	config.save(SETTINGS_PATH)
