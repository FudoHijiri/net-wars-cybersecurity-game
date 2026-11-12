extends Control
## The Book Archive: a book about the threats. The first spread is the table of contents: the left page lists the
## threats, and the right page shows the picture of the chosen one (its animated sprite) with a short description.
## The right arrow turns the page: the contents go away and the entry takes both pages, two topics to a spread
## (what it is, warning signs, how it attacks, ...). The left arrow turns back; the arrow keys work too.
## The text is in data/archive.json. A threat opens when the Investigation of its day is finished (it would
## give the case away before). A page of a threat can also list the game's attack patterns and recommended
## upgrades, read from the same data the game uses.

const DATA_PATH := "res://data/archive.json"
const PATTERNS_PATH := "res://AI generated/data/response_day1.json"
const UPGRADES_PATH := "res://data/upgrades.json"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const ARROW := "res://assets/ui/Page Arrow %s%s.png" # direction (Left or Right), state ("", " Hover", " Pressed", " Disabled")
const TITLE_SLACK := 4.0 # the title is centered and may pass its box by a few pixels, so a name that is 2px too wide does not drop a whole size
const FLIP_SPEED := 2.0 # the page animation is 0.8 s at normal speed: too slow for every click
const PLATE_RECT := Rect2(333, 66, 195, 112) # the picture of the threat on the right page
const LEFT_PAGE := Rect2(95, 65, 180, 220) # the text of the left page when it is not the contents
const INK := Color(0.1, 0.06, 0.03, 1)

var _data: Dictionary = {}
var _upgrades: Dictionary = {}
var _patterns: Array = [] # the attack patterns of the Response phase (Credential Abuse)
var _buttons: Array[Button] = [] # the threat buttons of the contents, in the order of the threats in the data
var _selected := -1 # the threat chosen in the contents, or -1
var _spread := 0 # 0 is the contents; spread N shows the topics 2N-2 and 2N-1 of the threat
var _busy := false # a page is turning
var _previous: TextureButton
var _next: TextureButton
var _left_info: RichTextLabel
var _left_number: Label
var _right_number: Label
var _plate: Panel
var _sprite: AnimatedSprite2D
var _summary: RichTextLabel

@onready var content: Control = $Content
@onready var book_animation: AnimatedSprite2D = $Node2D/BookAnimation
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var stage_select: Control = $"../StageSelect"
@onready var book_archive: Control = $"../BookArchive"
@onready var next_page_animation: AnimatedSprite2D = $Node2D/NextPageAnimation
@onready var _left_title: Label = $Content/Title
@onready var _contents: VBoxContainer = $Content/VBoxContainer
@onready var _threat_name: Label = $Content/ThreatName
@onready var _info: RichTextLabel = $Content/Info


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
	for child in _contents.get_children():
		if child is Button:
			_buttons.append(child)
	_left_title.anchor_left = 0.171875 # the left title is as wide as the page, from beside the back arrow, so a topic like WHAT IT IS keeps the big font
	_left_title.anchor_right = _contents.anchor_right
	_info.bbcode_enabled = true
	_info.add_theme_font_override("bold_font", BOLD)
	_info.add_theme_font_size_override("bold_font_size", 6)
	_build_left_page()
	_build_picture()
	_build_navigation()
	content.visibility_changed.connect(_on_content_visibility_changed)
	_refresh_list()
	_render()


func _on_back_button_pressed() -> void:
	if _busy:
		return
	content.hide()
	Music.play(&"stage_select")
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


func _chosen() -> Dictionary:
	return _threats()[_selected] if _selected >= 0 and _selected < _threats().size() else {}


## A threat opens when the Investigation of its day is finished in the save. With no save loaded
## (the scene run alone) everything is open.
func _is_unlocked(threat: Dictionary) -> bool:
	return SaveManager.current_slot < 0 or SaveManager.is_phase_complete(int(threat["day"]), "investigation")


## The names in the contents: the threat, or ??? with its day while it is closed.
func _refresh_list() -> void:
	var threats := _threats()
	for i in mini(_buttons.size(), threats.size()):
		var threat: Dictionary = threats[i]
		_buttons[i].text = str(threat["name"]) if _is_unlocked(threat) else "???   (Day %d)" % int(threat["day"])


func _on_threat_toggled(toggled_on: bool, index: int) -> void:
	if toggled_on:
		_select(index)


## Choosing a threat in the contents replaces the picture and the description on the right page at once.
func _select(index: int) -> void:
	if _busy or index == _selected or index >= _threats().size():
		return
	_selected = index
	_spread = 0
	_render()
	if _plate.visible:
		UiFx.pop(_plate, 0.06, 0.2)


## Turns the page: forward with step 1, back with step -1. Does nothing at the first spread going back, or at the
## last one going on. The contents only turn forward once a threat that is open is chosen.
func _turn(step: int) -> void:
	var target := _spread + step
	if _busy or target < 0 or target >= _spread_count():
		return
	_spread = target
	await _flip(&"NextPage" if step > 0 else &"BackPage")


## Both pages are blank while the book's page animation plays, then show the new spread.
func _flip(animation: StringName) -> void:
	_busy = true
	_show_pages(false)
	book_animation.speed_scale = FLIP_SPEED
	book_animation.play(animation)
	await book_animation.animation_finished
	book_animation.speed_scale = 1.0
	_render()
	_busy = false


func _on_content_visibility_changed() -> void:
	if content.visible:
		_refresh_list() # a threat may have opened since the book was last open
		_render()


# --- the spreads ---

## The contents, plus two topics to a spread of the chosen threat. A threat that is not open has only the contents.
func _spread_count() -> int:
	var threat := _chosen()
	if threat.is_empty() or not _is_unlocked(threat):
		return 1
	return 1 + ceili(threat["pages"].size() / 2.0)


func _render() -> void:
	var threat := _chosen()
	var open := not threat.is_empty() and _is_unlocked(threat)
	_show_pages(true)
	_render_left(threat)
	_render_right(threat, open)
	_fit_title(_left_title, _left_page_box())
	_fit_title(_threat_name, _right_page_box())
	_previous.disabled = _spread <= 0
	_next.disabled = _spread >= _spread_count() - 1


## The left page: the contents, or the first topic of the spread.
func _render_left(threat: Dictionary) -> void:
	var contents := _spread == 0
	_contents.visible = contents
	_left_info.visible = not contents
	_left_number.text = "1" if contents else "%s   %d" % [threat.get("short", threat.get("name", "")), 2 * _spread + 1]
	if contents:
		_left_title.text = "Contents"
		return
	var page := _topic(threat, 2 * (_spread - 1))
	_left_title.text = str(page.get("title", ""))
	_left_info.text = _page_text(page)
	_left_info.scroll_to_line(0)


## The right page: on the contents, the picture and short description of the chosen threat (a dark shape and a
## hint while it is closed, a welcome before anything is chosen); after it, the second topic of the spread.
func _render_right(threat: Dictionary, open: bool) -> void:
	var contents := _spread == 0
	_right_number.text = "2" if contents else "%d   %s" % [2 * _spread + 2, threat.get("short", threat.get("name", ""))]
	_plate.visible = false
	_summary.visible = false
	_info.visible = false
	if contents:
		if threat.is_empty():
			_threat_name.text = "Archive"
			_info.visible = true
			var count := 0
			for entry: Dictionary in _threats():
				count += 1 if _is_unlocked(entry) else 0
			_info.text = "%s\n\nThreats open: %d of %d." % [_data.get("intro", ""), count, _threats().size()]
		else:
			_show_picture(threat, open)
			_summary.visible = true
			_summary.text = _summary_text(threat) if open else str(_data.get("locked", "")).replace("{day}", str(int(threat["day"])))
			_threat_name.text = str(threat.get("short", threat["name"])) if open else "???"
		_info.scroll_to_line(0)
		return
	var index := 2 * (_spread - 1) + 1
	if index < threat["pages"].size():
		var page := _topic(threat, index)
		_threat_name.text = str(page.get("title", ""))
		_info.visible = true
		_info.text = _page_text(page)
		_info.scroll_to_line(0)
	else: # an odd number of topics: the last right page is the picture again
		_threat_name.text = str(threat.get("short", threat["name"]))
		_show_picture(threat, true)


func _topic(threat: Dictionary, index: int) -> Dictionary:
	var pages: Array = threat["pages"]
	return pages[index] if index < pages.size() else {}


func _summary_text(threat: Dictionary) -> String:
	return "[b]%s[/b]\n\n%s" % [threat["name"], threat.get("summary", "")]


## The animated sprite of the threat in the plate, as big as whole multiples of its pixels allow. A threat that is
## not open is only a dark shape.
func _show_picture(threat: Dictionary, open: bool) -> void:
	_plate.visible = true
	var frames := load(str(threat.get("frames", ""))) as SpriteFrames if threat.has("frames") else null
	_sprite.visible = frames != null
	if frames == null:
		return
	_sprite.sprite_frames = frames
	var animation: StringName = &"idle" if frames.has_animation(&"idle") else StringName(frames.get_animation_names()[0])
	_sprite.play(animation)
	var frame_size := frames.get_frame_texture(animation, 0).get_size()
	var fit := maxf(1.0, floorf(minf((PLATE_RECT.size.x - 12.0) / frame_size.x, (PLATE_RECT.size.y - 12.0) / frame_size.y)))
	_sprite.scale = Vector2.ONE * fit
	_sprite.position = (PLATE_RECT.size / 2.0).floor()
	_sprite.modulate = Color.WHITE if open else Color(0.05, 0.03, 0.02, 0.85)


## The title is as big as the box allows: a long name like Distributed Denial-of-Service gets a smaller font.
## It only steps down by whole multiples of the font's pixel size (6 for Minecraft Standard), because any
## other size blurs the text.
func _fit_title(label: Label, box: float) -> void:
	label.remove_theme_font_size_override("font_size")
	var font := label.get_theme_font("font")
	var font_px := label.get_theme_font_size("font_size")
	var step := 6
	while font_px > step and font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_px).x > box:
		font_px -= step
	label.add_theme_font_size_override("font_size", font_px)


func _left_page_box() -> float:
	return (_left_title.anchor_right - _left_title.anchor_left) * content.size.x + TITLE_SLACK # the label grows with its text, so its anchors give the box


func _right_page_box() -> float:
	return (_threat_name.anchor_right - _threat_name.anchor_left) * content.size.x + TITLE_SLACK


## A page's text, plus what the game itself adds to it: the attack patterns, the recommended upgrades.
func _page_text(page: Dictionary) -> String:
	var text := str(page.get("text", ""))
	if page.get("patterns", false):
		# true: the patterns of Day 1's fight; a path: the fight of that day's file
		var patterns: Array = _patterns if page["patterns"] is bool else _load_json(str(page["patterns"])).get("patterns", [])
		for pattern: Dictionary in patterns:
			var fix := str(_upgrades.get(str(pattern.get("counter", "")), {}).get("name", ""))
			text += "[b]In the game: %s.[/b] %s Stopped by: %s.\n\n" % [pattern.get("name", ""), pattern.get("teach", ""), fix]
	if page.has("upgrades"):
		text += "[b]Recommended upgrades[/b]\n"
		for id: String in page["upgrades"]:
			var upgrade: Dictionary = _upgrades.get(id, {})
			text += "\n[b]%s[/b] (load %d): %s" % [upgrade.get("name", id), int(upgrade.get("load", 0)), upgrade.get("text", "")]
	return text


## Everything on the two pages that changes with the spread: hidden while a page turns.
func _show_pages(visible_now: bool) -> void:
	for node: CanvasItem in [_left_title, _contents, _left_info, _threat_name, _info, _plate, _summary, _left_number, _right_number, _previous, _next]:
		node.visible = visible_now


# --- built here ---

## The text of the left page when it is not the contents: the same look as the right page's.
func _build_left_page() -> void:
	_left_info = RichTextLabel.new()
	_left_info.name = "LeftInfo"
	_left_info.bbcode_enabled = true
	_left_info.position = LEFT_PAGE.position
	_left_info.size = LEFT_PAGE.size
	_left_info.add_theme_color_override("default_color", Color.BLACK)
	_left_info.add_theme_font_override("normal_font", FONT)
	_left_info.add_theme_font_override("bold_font", BOLD)
	_left_info.add_theme_font_size_override("normal_font_size", 6)
	_left_info.add_theme_font_size_override("bold_font_size", 6)
	content.add_child(_left_info)


## The plate with the picture of the threat (its sprite is animated) and the short description under it.
func _build_picture() -> void:
	_plate = Panel.new()
	_plate.name = "Plate"
	_plate.position = PLATE_RECT.position
	_plate.size = PLATE_RECT.size
	_plate.pivot_offset = PLATE_RECT.size / 2.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.45, 0.3, 0.18, 0.28)
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.19, 0.1, 1)
	_plate.add_theme_stylebox_override("panel", style)
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(_plate)
	_sprite = AnimatedSprite2D.new()
	_plate.add_child(_sprite)
	_summary = RichTextLabel.new()
	_summary.name = "Summary"
	_summary.bbcode_enabled = true
	_summary.position = Vector2(PLATE_RECT.position.x, PLATE_RECT.end.y + 8.0)
	_summary.size = Vector2(PLATE_RECT.size.x, 90.0)
	_summary.add_theme_color_override("default_color", Color.BLACK)
	_summary.add_theme_font_override("normal_font", FONT)
	_summary.add_theme_font_override("bold_font", BOLD)
	_summary.add_theme_font_size_override("normal_font_size", 6)
	_summary.add_theme_font_size_override("bold_font_size", 6)
	content.add_child(_summary)


## The two pixel arrows under the pages and the page numbers between them. The scene can have its own (nodes named
## PreviousArrow, NextArrow, LeftNumber and RightNumber under Content); without them these are made here.
func _build_navigation() -> void:
	_previous = _arrow("PreviousArrow", "Left", Vector2(94, 288))
	_previous.pressed.connect(_turn.bind(-1))
	_next = _arrow("NextArrow", "Right", Vector2(498, 288))
	_next.pressed.connect(_turn.bind(1))
	_left_number = _number("LeftNumber", Rect2(130, 287, 140, 14), HORIZONTAL_ALIGNMENT_CENTER)
	_right_number = _number("RightNumber", Rect2(333, 287, 160, 14), HORIZONTAL_ALIGNMENT_CENTER)


func _arrow(node_name: String, direction: String, at: Vector2) -> TextureButton:
	var existing := content.get_node_or_null(node_name) as TextureButton
	if existing != null:
		return existing
	var button := TextureButton.new()
	button.name = node_name
	button.texture_normal = load(ARROW % [direction, ""])
	button.texture_hover = load(ARROW % [direction, " Hover"])
	button.texture_pressed = load(ARROW % [direction, " Pressed"])
	button.texture_disabled = load(ARROW % [direction, " Disabled"])
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.position = at
	button.size = Vector2(32, 28) # twice the pixels of the arrow (the image has a pixel of room above and below for its outline)
	button.focus_mode = Control.FOCUS_NONE # the arrow keys turn the pages
	button.tooltip_text = "Previous page" if direction == "Left" else "Next page"
	content.add_child(button)
	return button


func _number(node_name: String, rect: Rect2, align: HorizontalAlignment) -> Label:
	var existing := content.get_node_or_null(node_name) as Label
	if existing != null:
		return existing
	var label := Label.new()
	label.name = node_name
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", 6)
	label.add_theme_color_override("font_color", Color(0, 0, 0, 0.6))
	content.add_child(label)
	return label


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
