extends RecoveryTask

## Patch the hole, then prove it, in six steps the player does by hand (Day 8). The picture is two small websites: a TEST COPY
## and the LIVE SITE, each with its version and a light. The steps, in order:
##   1. back up the live site;  2. download the update (from the maker, not a forum or an email);  3. check the download's
##   number against the maker's (the first download does not match: download it again);  4. install it on the TEST COPY;
##   5. try the attack string on the test copy (before the patch it returns 2,400 rows, after it is rejected);
##   6. install it on the live site and restart.
## A step done out of order bounces back with its reason and counts as a wrong move. The caption names the step to do next.
## Layout: SitePatch.tscn (everything is built here). content: {steps: [6 captions], backup, sources: [{id, label, ok, reason}],
## maker_number, download_numbers: [..], match, differ, differ_reasons, install_test, try_attack, install_live, versions {old, new},
## attack_string, results {before, after}, order_reasons {backup, download, check, install_test, try_attack, install_live}}.

const STEPS := ["backup", "download", "check", "install_test", "try_attack", "install_live"]

var step := 0 # the index in STEPS of the step to do next
var downloads := 0 # downloads done so far (each one has its own number)
var test_patched := false
var live_patched := false
var _caption: Label
var _test_panel: SitePanel
var _live_panel: SitePanel
var _number_label: Label
var _backup_button: Button
var _source_label: Label
var _source_row: HFlowContainer
var _source_buttons: Dictionary = {}
var _check_row: HBoxContainer
var _match_button: Button
var _differ_button: Button
var _install_test_button: Button
var _try_button: Button
var _install_live_button: Button
var _glow_tween: Tween
var _glowing: Control


func setup_task() -> void:
	_caption = Label.new()
	_caption.theme_type_variation = &"RecoveryAccent"
	body.add_child(_caption)
	var panels := HBoxContainer.new()
	panels.add_theme_constant_override("separation", 8)
	body.add_child(panels)
	_test_panel = SitePanel.new()
	_test_panel.title = str(content.get("test_title", "TEST COPY"))
	panels.add_child(_test_panel)
	_live_panel = SitePanel.new()
	_live_panel.title = str(content.get("live_title", "LIVE SITE"))
	panels.add_child(_live_panel)
	_backup_button = _button(str(content.get("backup", "1  BACK UP THE LIVE SITE")), do_backup)
	body.add_child(_backup_button)
	_source_label = Label.new()
	_source_label.theme_type_variation = &"RecoveryMuted"
	_source_label.text = str(content.get("sources_label", "2  DOWNLOAD THE UPDATE FROM:"))
	body.add_child(_source_label)
	_source_row = HFlowContainer.new()
	body.add_child(_source_row)
	for source: Dictionary in content.get("sources", []):
		var button := _button(str(source["label"]), choose_source.bind(str(source["id"])))
		_source_row.add_child(button)
		_source_buttons[str(source["id"])] = button
	_number_label = Label.new()
	_number_label.theme_type_variation = &"RecoveryMuted"
	body.add_child(_number_label)
	_check_row = HBoxContainer.new()
	body.add_child(_check_row)
	_match_button = _button(str(content.get("match", "3  THE NUMBERS MATCH")), check.bind(true))
	_check_row.add_child(_match_button)
	_differ_button = _button(str(content.get("differ", "3  THEY DIFFER: DOWNLOAD AGAIN")), check.bind(false))
	_check_row.add_child(_differ_button)
	var test_row := HBoxContainer.new()
	body.add_child(test_row)
	_install_test_button = _button(str(content.get("install_test", "4  INSTALL ON THE TEST COPY")), install_test)
	test_row.add_child(_install_test_button)
	_try_button = _button(str(content.get("try_attack", "5  TRY THE ATTACK ON THE COPY")), try_attack)
	test_row.add_child(_try_button)
	_install_live_button = _button(str(content.get("install_live", "6  INSTALL ON THE LIVE SITE AND RESTART")), install_live)
	body.add_child(_install_live_button)


func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(action)
	return button


func reset_state() -> void:
	step = 0
	downloads = 0
	test_patched = false
	live_patched = false
	var versions: Dictionary = content.get("versions", {})
	_test_panel.reset(str(versions.get("old", "ShopKit 2.1")), str(content.get("attack_string", "' OR 1=1 --")))
	_live_panel.reset(str(versions.get("old", "ShopKit 2.1")), "")
	_live_panel.light = "online"
	_number_label.text = ""
	for button: Button in [_backup_button, _install_test_button, _try_button, _install_live_button]:
		button.disabled = false
	_show_step()
	set_feedback(str(content.get("pick", "")))


func _show_step() -> void:
	var captions: Array = content.get("steps", [])
	_caption.text = str(captions[step]) if step < captions.size() else ""
	_backup_button.visible = step == 0 # a step that is done goes away, so the screen always fits
	_source_label.visible = step <= 1
	_source_row.visible = step <= 1
	_check_row.visible = step == 2
	_number_label.visible = step == 2
	_glow([_backup_button, null, null, _install_test_button, _try_button, _install_live_button][step] if step < STEPS.size() else null)


func _glow(target: Control) -> void:
	if _glow_tween:
		_glow_tween.kill()
	if is_instance_valid(_glowing):
		_glowing.modulate = Color.WHITE
	_glowing = target
	if target == null or not is_inside_tree():
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(target, "modulate", Color(1.5, 1.4, 0.85), 0.45)
	_glow_tween.tween_property(target, "modulate", Color.WHITE, 0.45)


## A step done in the wrong place: say why, and count it.
func _too_early(id: String) -> bool:
	if solved:
		return true
	if STEPS[mini(step, STEPS.size() - 1)] == id:
		return false
	note_mistake(str(content.get("order_reasons", {}).get(id, "")))
	return true


func do_backup() -> void:
	if _too_early("backup"):
		return
	step = 1
	_backup_button.disabled = true
	set_feedback(str(content.get("backup_done", "")), "good")
	_show_step()


func choose_source(id: String) -> void:
	if _too_early("download"):
		return
	for source: Dictionary in content.get("sources", []):
		if str(source["id"]) == id:
			if not source.get("ok", false):
				note_mistake(str(source.get("reason", "")))
				return
	step = 2
	_number_label.text = _number_text()
	set_feedback(str(content.get("download_done", "")), "good")
	_show_step()


func _download_number() -> String:
	var numbers: Array = content.get("download_numbers", [])
	return str(numbers[mini(downloads, numbers.size() - 1)])


func _number_text() -> String:
	return str(content.get("number_format", "The maker says: %s     Your download: %s")) % [content.get("maker_number", ""), _download_number()]


func check(says_match: bool) -> void:
	if _too_early("check"):
		return
	var really_matches := _download_number() == str(content.get("maker_number", ""))
	if says_match != really_matches:
		note_mistake(str(content.get("match_reason" if says_match else "differ_reason", "")))
		return
	if really_matches:
		step = 3
		set_feedback(str(content.get("check_done", "")), "good")
	else: # a download that does not match is thrown away, and the update is downloaded again
		downloads += 1
		step = 1
		set_feedback(str(content.get("differ_done", "")), "good")
	_show_step()


func install_test() -> void:
	if _too_early("install_test"):
		return
	test_patched = true
	_test_panel.version = str(content.get("versions", {}).get("new", "ShopKit 2.4"))
	step = 4
	_install_test_button.disabled = true
	set_feedback(str(content.get("install_test_done", "")), "good")
	_show_step()


## Typing the attack string into the test copy: allowed at any time (before the patch it shows why the patch is needed),
## but it only counts as the test once the copy is patched.
func try_attack() -> void:
	if solved:
		return
	var results: Dictionary = content.get("results", {})
	_test_panel.result = str(results.get("after" if test_patched else "before", ""))
	_test_panel.light = "good" if test_patched else "bad"
	_test_panel.queue_redraw()
	if not test_patched:
		set_feedback(str(content.get("try_before", "")))
		return
	if step == 4:
		step = 5
		set_feedback(str(content.get("try_done", "")), "good")
		_show_step()


func install_live() -> void:
	if _too_early("install_live"):
		return
	live_patched = true
	_live_panel.version = str(content.get("versions", {}).get("new", "ShopKit 2.4"))
	_live_panel.queue_redraw()
	step = 6
	succeed()


## One small website: a title, the version it runs, a login form (the test copy shows the attack string typed into it), a light.
class SitePanel extends Control:
	const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
	const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
	var title := ""
	var version := ""
	var typed := ""
	var result := ""
	var light := "online" # online, good, bad

	func _init() -> void:
		custom_minimum_size = Vector2(150, 50)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL

	func reset(new_version: String, new_typed: String) -> void:
		version = new_version
		typed = new_typed
		result = ""
		light = "online"
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.9372549, 0.9372549, 0.9529412, 1))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.3372549, 0.42352942, 0.5254902, 1), false, 1.0)
		draw_rect(Rect2(1, 1, size.x - 2, 10), Color(0.16078432, 0.21176471, 0.43529412, 1))
		draw_string(BOLD, Vector2(4, 8), title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, 6, Color(0.9568627, 0.9568627, 0.9568627, 1))
		var color := {"online": Color(0.22, 0.72, 0.39), "good": Color(0.22, 0.72, 0.39), "bad": Color(0.69, 0.24, 0.33)}.get(light, Color(0.22, 0.72, 0.39)) as Color
		draw_circle(Vector2(size.x - 8.0, 6.0), 3.0, color)
		var ink := Color(0.101960786, 0.10980392, 0.17254902, 1)
		draw_string(FONT, Vector2(4, 20), version, HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, ink)
		draw_rect(Rect2(4, 24, size.x - 8.0, 9), Color(1, 1, 1, 1))
		draw_rect(Rect2(4, 24, size.x - 8.0, 9), Color(0.58, 0.69, 0.76, 1), false, 1.0)
		draw_string(FONT, Vector2(7, 31), typed if not typed.is_empty() else "name: ...", HORIZONTAL_ALIGNMENT_LEFT, size.x - 14.0, 6, ink if not typed.is_empty() else Color(0.58, 0.69, 0.76, 1))
		if not result.is_empty():
			draw_string(FONT, Vector2(4, 44), ("Answer: " + result) if light == "bad" else ("Answer: " + result + " [OK]"), HORIZONTAL_ALIGNMENT_LEFT, size.x - 8.0, 6, color)
