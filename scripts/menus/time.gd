extends RichTextLabel

## Shows the system's local time as a 12-hour clock, e.g. "03:07 PM".


func _ready() -> void:
	_refresh()
	# Checking once a second keeps the display within a second of the system clock.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_refresh)
	add_child(timer)
	timer.start()


func _refresh() -> void:
	var now := Time.get_datetime_dict_from_system()
	var hour_12: int = now.hour % 12
	if hour_12 == 0:
		hour_12 = 12
	var meridiem := "AM" if now.hour < 12 else "PM"
	var current := "%02d:%02d %s" % [hour_12, now.minute, meridiem]
	# Only touch the label when the shown time changes.
	if text != current:
		text = current
