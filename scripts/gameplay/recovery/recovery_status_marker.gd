@tool
class_name RecoveryStatusMarker
extends Marker2D

@export var bubble: Node2D
@export var outline: Polygon2D
@export var face: Polygon2D
@export var glyph: Label
@export var check_mark: Line2D
@export var animate_attention := true

var _status := "needs_repair"
var _nearby := false
var _terminal := false
var _elapsed := 0.0
var _shown_status := "" # the status last drawn, so a repair that has just been done gets its moment

func _ready() -> void:
	_refresh()

func configure_status(value: String, nearby: bool, terminal: bool) -> void:
	_status = value
	_nearby = nearby
	_terminal = terminal
	_refresh()

func _refresh() -> void:
	if not is_instance_valid(glyph):
		return
	visible = _terminal or _status != "working"
	var attention := _status == "needs_repair" and not _terminal
	var restored := _status == "restored" and not _terminal
	glyph.text = "" if restored else ("!" if attention else ("E" if _terminal else ("?" if _status == "waiting" else "..")))
	if is_instance_valid(check_mark):
		check_mark.visible = restored
	face.color = RecoveryStyle.YELLOW if attention else (RecoveryStyle.CYAN if _terminal else RecoveryStyle.SLATE)
	if _status == "restored":
		face.color = RecoveryStyle.GREEN
	glyph.add_theme_color_override("font_color", RecoveryStyle.DARK if attention or _terminal else RecoveryStyle.WHITE)
	outline.color = RecoveryStyle.CYAN if _nearby else RecoveryStyle.DARK
	if restored and _shown_status != "" and _shown_status != "restored" and not Engine.is_editor_hint() and is_inside_tree():
		UiFx.pop(bubble, 0.5, 0.4) # the `!` turns into a check
		UiFx.sparkle(get_global_transform_with_canvas().origin + Vector2(0, -4), UiFx.GREEN, 12)
	_shown_status = _status
	_elapsed = 0.0
	bubble.position.y = 0
	set_process(visible and attention and animate_attention and not Engine.is_editor_hint())

func _process(delta: float) -> void:
	_elapsed += delta
	# Whole-pixel movement keeps the small indicator crisp at every integer scale.
	bubble.position.y = [0, -1, -2, -1][int(_elapsed / 0.24) % 4]
