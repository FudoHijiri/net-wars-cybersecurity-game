extends RecoveryTask

## Turn the protection on, run a scan, and quarantine only what is really a threat. Layout: ScanClean.tscn (the
## controls are built here). content: {switch, scan, scan_locked, scanning, found, items[{id, label, detail, bad,
## reason}], quarantine, quarantined, ...}. Order: the switch first (the scan is locked while it is off), then the
## scan (a short progress bar), then the results: quarantine every item with "bad": true, leave the others.

var protection: CheckButton
var scan_button: Button
var scan_done := false
var quarantined: Array[String] = []
var _bar: ProgressBar
var _results: VBoxContainer
var _buttons: Dictionary = {}
var _scan_tween: Tween


func setup_task() -> void:
	protection = CheckButton.new()
	protection.text = str(content.get("switch", "Antivirus"))
	protection.toggled.connect(_protection_toggled)
	body.add_child(protection)
	var line := HBoxContainer.new()
	body.add_child(line)
	scan_button = Button.new()
	scan_button.theme_type_variation = &"RecoveryCard"
	scan_button.text = str(content.get("scan", "Run scan"))
	scan_button.custom_minimum_size = Vector2(110, 20)
	scan_button.pressed.connect(_scan)
	line.add_child(scan_button)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(0, 12)
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(_bar)
	_results = VBoxContainer.new()
	_results.add_theme_constant_override("separation", 3)
	body.add_child(_results)
	for item: Dictionary in content.get("items", []):
		var id := str(item["id"])
		var row := HBoxContainer.new()
		var text := Label.new()
		text.text = "%s   %s" % [item["label"], item.get("detail", "")]
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(text)
		var button := Button.new()
		button.theme_type_variation = &"RecoveryCard"
		button.text = str(content.get("quarantine", "Quarantine"))
		button.custom_minimum_size = Vector2(90, 20)
		button.pressed.connect(_quarantine.bind(id))
		row.add_child(button)
		_results.add_child(row)
		_buttons[id] = button


func reset_state() -> void:
	if _scan_tween:
		_scan_tween.kill()
	quarantined.clear()
	scan_done = false
	protection.set_pressed_no_signal(false)
	protection.disabled = false
	scan_button.disabled = false
	_bar.value = 0.0
	_results.hide()
	for id: String in _buttons:
		_buttons[id].disabled = false
		_buttons[id].text = str(content.get("quarantine", "Quarantine"))
		_buttons[id].theme_type_variation = &"RecoveryCard"
	set_feedback(str(content.get("pick", "")))


func _protection_toggled(on: bool) -> void:
	if solved:
		return
	if on:
		set_feedback(str(content.get("protection_on", "")), "good")
		UiFx.pop(protection)


func _scan() -> void:
	if solved or scan_done:
		return
	if not protection.button_pressed:
		UiFx.shake(scan_button)
		note_mistake(str(content.get("scan_locked", "")))
		return
	scan_button.disabled = true
	protection.disabled = true
	set_feedback(str(content.get("scanning", "")))
	_scan_tween = create_tween()
	_scan_tween.tween_property(_bar, "value", 100.0, 0.2 if UiFx.reduced() else 1.4)
	_scan_tween.tween_callback(_scan_finished)


func _scan_finished() -> void:
	scan_done = true
	_results.show()
	UiFx.stagger_fade(_results.get_children())
	set_feedback(str(content.get("found", "")), "good")
	RecoveryStyle.focus_loop(self)


func _quarantine(id: String) -> void:
	if solved or quarantined.has(id) or not scan_done:
		return
	var item: Dictionary = {}
	for candidate: Dictionary in content.get("items", []):
		if str(candidate["id"]) == id:
			item = candidate
	if not item.get("bad", false):
		UiFx.shake(_buttons[id])
		note_mistake(str(item.get("reason", "")))
		return
	quarantined.append(id)
	_buttons[id].text = str(content.get("quarantined", "[OK] ISOLATED"))
	_buttons[id].disabled = true
	_buttons[id].theme_type_variation = &"RecoveryCardGood"
	UiFx.pop(_buttons[id])
	set_feedback(str(item.get("reason", "")), "good")
	if _threats_left() == 0:
		succeed()


func _threats_left() -> int:
	var left := 0
	for item: Dictionary in content.get("items", []):
		if item.get("bad", false) and not quarantined.has(str(item["id"])):
			left += 1
	return left
