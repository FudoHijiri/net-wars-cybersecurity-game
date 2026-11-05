class_name FadeText
extends RefCounted

## Fades a RichTextLabel's text in, character by character, with the [fade] BBCode effect.
## Shared by the visual novel Dialogue and the investigation Monologue.
##
## Usage: keep one FadeText per label, call show_text() for every new line and press() for
## every click, Space or Enter. press() returns true when the player wants the NEXT line.

## Characters revealed per second. Static, so a settings option can change it later.
static var chars_per_second := 90.0

## How many characters the soft edge of the fade spans.
const FADE_LENGTH := 8
## After a line starts or a press is used, presses are ignored for this long. A quick
## double click then can't finish the fade and skip the next line right away.
const PRESS_PAUSE_MSEC := 200

var _label: RichTextLabel
var _text := ""
var _tween: Tween
var _next_press_at := 0


func _init(label: RichTextLabel) -> void:
	_label = label


## Starts fading in `bbcode` (the label must have BBCode enabled).
func show_text(bbcode: String) -> void:
	_stop_tween()
	_text = bbcode
	_label.text = bbcode # parsed once, only to count the visible characters
	_next_press_at = Time.get_ticks_msec() + PRESS_PAUSE_MSEC
	var total := _label.get_total_character_count()
	if total == 0 or chars_per_second <= 0.0:
		return
	_set_fade_start(-FADE_LENGTH) # everything is still transparent
	_tween = _label.create_tween()
	_tween.tween_method(_set_fade_start, -FADE_LENGTH, total, float(total + FADE_LENGTH) / chars_per_second)
	_tween.finished.connect(_on_tween_finished)


func is_fading() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## Shows the whole text at once.
func finish() -> void:
	if is_fading():
		_stop_tween()
		_label.text = _text


## Handles one click/Space/Enter. Returns true only when the text is fully shown and the
## pause since the last press has passed: that press means "next line". A press during the
## fade just completes it; a press too soon after the last one does nothing.
func press() -> bool:
	var now := Time.get_ticks_msec()
	if now < _next_press_at:
		return false
	_next_press_at = now + PRESS_PAUSE_MSEC
	if is_fading():
		finish()
		return false
	return true


func _set_fade_start(start: float) -> void:
	_label.text = "[fade start=%d length=%d]%s[/fade]" % [roundi(start), FADE_LENGTH, _text]


func _on_tween_finished() -> void:
	_tween = null
	_label.text = _text # without the effect, so the finished line is plain text


func _stop_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
