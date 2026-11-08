extends Control
## The Book Archive: a book about the threats. The left page lists them; the right page shows the pages of
## the chosen threat. NEXT and BACK (or the arrow keys) turn the pages with the book's page animation.
## The text is in data/archive.json. A threat opens when the Investigation of its day is finished (it would
## give the case away before), and the pages of Credential Abuse also list the game's attack patterns and
## recommended upgrades, read from the same data the game uses.

const DATA_PATH := "res://data/archive.json"
const PATTERNS_PATH := "res://AI generated/data/response_day1.json"
const UPGRADES_PATH := "res://data/upgrades.json"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const FLIP_SPEED := 2.0 # the page animation is 0.8 s at normal speed: too slow for every click

var _data: Dictionary = {}
var _upgrades: Dictionary = {}
var _patterns: Array = [] # the attack patterns of the Response phase (Credential Abuse)
var _buttons: Array[Button] = [] # the threat buttons, in the order of the threats in the data
var _selected := -1 # the threat on the right page, or -1 for the welcome page
var _page := 0
var _busy := false # a page is turning
var _previous: Button
var _next: Button
var _page_label: Label

@onready var content: Control = $Content
@onready var book_animation: AnimatedSprite2D = $Node2D/BookAnimation
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var stage_select: Control = $"../StageSelect"
@onready var book_archive: Control = $"../BookArchive"
@onready var next_page_animation: AnimatedSprite2D = $Node2D/NextPageAnimation
@onready var _threat_name: Label = $Content/ThreatName
@onready var _info: RichTextLabel = $Content/Info


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content.hide()
	book_animation.show()
	# The scene file is saved with the book open (the last frame). Start closed, like every visit after the first.
	book_animation.animation = &"default"
	book_animation.set_frame_and_progress(0, 0.0)
	next_page_animation.hide()

	_data = _load_json(DATA_PATH)
	_upgrades = _load_json(UPGRADES_PATH).get("upgrades", {})
	_patterns = _load_json(PATTERNS_PATH).get("patterns", [])
	for child in $Content/VBoxContainer.get_children():
		if child is Button:
			_buttons.append(child)
	_info.bbcode_enabled = true
	_info.add_theme_font_override("bold_font", BOLD)
	_info.add_theme_font_size_override("bold_font_size", 6)
	_build_navigation()
	content.visibility_changed.connect(_on_content_visibility_changed)
	_refresh_list()
	_render()


func _on_back_button_pressed() -> void:
	if _busy:
		return
	content.hide()
	book_animation.play_backwards("default")
	await book_animation.animation_finished
	stage_select.show()
	animation_player.play_backwards("book_archive_animation")
	await animation_player.animation_finished
	book_archive.hide()


func _on_credential_threat_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 0)


func _on_malware_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 1)


func _on_ransomware_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 2)


func _on_insider_threat_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 3)


func _on_data_exfiltration_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 4)


func _on_d_do_s_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 5)


func _on_phishing_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 6)


func _on_web_application_attack_toggled(toggled_on: bool) -> void:
	_on_threat_toggled(toggled_on, 7)


## The arrow keys turn the pages. Taken here, before the buttons use them to move the focus.
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not is_visible_in_tree() or not content.visible:
		return
	if key.keycode == KEY_RIGHT or key.keycode == KEY_LEFT:
		get_viewport().set_input_as_handled()
		_turn(1 if key.keycode == KEY_RIGHT else -1)


# --- the threats ---

func _threats() -> Array:
	return _data.get("threats", [])


## A threat opens when the Investigation of its day is finished in the save. With no save loaded
## (the scene run alone) everything is open.
func _is_unlocked(threat: Dictionary) -> bool:
	return SaveManager.current_slot < 0 or SaveManager.is_phase_complete(int(threat["day"]), "investigation")


## The names on the buttons: the threat, or ??? with its day while it is closed.
func _refresh_list() -> void:
	var threats := _threats()
	for i in mini(_buttons.size(), threats.size()):
		var threat: Dictionary = threats[i]
		_buttons[i].text = str(threat["name"]) if _is_unlocked(threat) else "???   (Day %d)" % int(threat["day"])


func _on_threat_toggled(toggled_on: bool, index: int) -> void:
	if toggled_on:
		_select(index)


func _select(index: int) -> void:
	if _busy or index == _selected or index >= _threats().size():
		return
	_selected = index
	_page = 0
	await _flip(&"NextPage")


## Turns one page: forward with step 1, back with step -1. Does nothing at the first or the last page.
func _turn(step: int) -> void:
	var target := _page + step
	if _busy or _selected < 0 or target < 0 or target >= _page_count():
		return
	_page = target
	await _flip(&"NextPage" if step > 0 else &"BackPage")


## The right page is blank while the book's page animation plays, then shows the new page.
func _flip(animation: StringName) -> void:
	_busy = true
	_show_right_page(false)
	book_animation.speed_scale = FLIP_SPEED
	book_animation.play(animation)
	await book_animation.animation_finished
	book_animation.speed_scale = 1.0
	_render()
	_show_right_page(true)
	_busy = false


func _on_content_visibility_changed() -> void:
	if content.visible:
		_refresh_list() # a threat may have opened since the book was last open
		_render()


# --- the right page ---

func _page_count() -> int:
	if _selected < 0 or not _is_unlocked(_threats()[_selected]):
		return 0
	return _threats()[_selected]["pages"].size()


func _render() -> void:
	_threat_name.text = "Archive"
	_page_label.text = ""
	if _selected < 0:
		var open := 0
		for threat: Dictionary in _threats():
			open += 1 if _is_unlocked(threat) else 0
		_info.text = "%s\n\nThreats open: %d of %d." % [_data.get("intro", ""), open, _threats().size()]
	else:
		var threat: Dictionary = _threats()[_selected]
		if _is_unlocked(threat):
			var page: Dictionary = threat["pages"][_page]
			_threat_name.text = str(threat.get("short", threat["name"]))
			_page_label.text = "PAGE %d / %d" % [_page + 1, _page_count()]
			_info.text = "[b]%s[/b]\n\n%s" % [page["title"], _page_text(page)]
		else:
			_threat_name.text = "???"
			_info.text = str(_data.get("locked", "")).replace("{day}", str(int(threat["day"])))
	_fit_title()
	_info.scroll_to_line(0)
	_previous.disabled = _page <= 0 or _page_count() == 0
	_next.disabled = _page >= _page_count() - 1


## The title is as big as the box allows: a long name like Distributed Denial-of-Service gets a smaller font.
func _fit_title() -> void:
	_threat_name.remove_theme_font_size_override("font_size")
	var font := _threat_name.get_theme_font("font")
	var size := _threat_name.get_theme_font_size("font_size")
	var width := (_threat_name.anchor_right - _threat_name.anchor_left) * content.size.x # the label grows with its text, so its anchors give the box
	while size > 8 and font.get_string_size(_threat_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
		size -= 1
	_threat_name.add_theme_font_size_override("font_size", size)


## A page's text, plus what the game itself adds to it: the attack patterns, the recommended upgrades.
func _page_text(page: Dictionary) -> String:
	var text := str(page.get("text", ""))
	if page.get("patterns", false):
		for pattern: Dictionary in _patterns:
			var fix := str(_upgrades.get(str(pattern.get("counter", "")), {}).get("name", ""))
			text += "[b]In the game: %s.[/b] %s Stopped by: %s.\n\n" % [pattern.get("name", ""), pattern.get("teach", ""), fix]
	if page.has("upgrades"):
		text += "[b]Recommended upgrades[/b]\n"
		for id: String in page["upgrades"]:
			var upgrade: Dictionary = _upgrades.get(id, {})
			text += "\n[b]%s[/b] (load %d): %s" % [upgrade.get("name", id), int(upgrade.get("load", 0)), upgrade.get("text", "")]
	return text


func _show_right_page(visible_now: bool) -> void:
	for node: CanvasItem in [_threat_name, _info, _page_label, _previous, _next]:
		node.visible = visible_now


## NEXT, BACK and the page number sit under the right page. The scene can have its own (nodes named
## NextPageButton, PreviousPageButton and PageLabel under Content); without them these are made here.
func _build_navigation() -> void:
	_previous = _navigation_button("PreviousPageButton", "< BACK", Vector2(333, 288))
	_previous.pressed.connect(_turn.bind(-1))
	_next = _navigation_button("NextPageButton", "NEXT >", Vector2(476, 288))
	_next.pressed.connect(_turn.bind(1))
	_page_label = content.get_node_or_null("PageLabel") as Label
	if _page_label == null:
		_page_label = Label.new()
		_page_label.name = "PageLabel"
		_page_label.position = Vector2(386, 288)
		_page_label.size = Vector2(88, 14)
		_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_page_label.add_theme_font_override("font", FONT)
		_page_label.add_theme_font_size_override("font_size", 6)
		_page_label.add_theme_color_override("font_color", Color.BLACK)
		content.add_child(_page_label)


func _navigation_button(node_name: String, text: String, at: Vector2) -> Button:
	var existing := content.get_node_or_null(node_name) as Button
	if existing != null:
		return existing
	var button: Button = _buttons[0].duplicate() # the look of the threat buttons
	button.name = node_name
	button.button_group = null
	button.toggle_mode = false
	button.text = text
	button.position = at
	button.size = Vector2(52, 14)
	button.add_theme_color_override("font_disabled_color", Color(0, 0, 0, 0.3))
	content.add_child(button)
	return button


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
