extends RichTextLabel

## Shows the system's local date as MM/DD/YYYY, e.g. "10/02/2026".


func _ready() -> void:
	_refresh()
	# Polling lets the date roll over at midnight without any extra bookkeeping.
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.timeout.connect(_refresh)
	add_child(timer)
	timer.start()


func _refresh() -> void:
	var now := Time.get_datetime_dict_from_system()
	var current := "%02d/%02d/%04d" % [now.month, now.day, now.year]
	# Only touch the label when the shown date changes.
	if text != current:
		text = current
