class_name Credits
extends Control
## The credits, opened by the Credits button of the title menu. What it shows is data/credits.json: sections with
## their entries (name, link, license, note). The links open in the browser. BACK (or Escape) returns to the title,
## and the arrow keys scroll.

const DATA_PATH := "res://data/credits.json"
const TITLE_SCENE := "res://scenes/menus/TitleMenu.tscn"
const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const FONT_BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")
const GOLD := Color(1, 0.8039216, 0.45882353, 1)
const TEXT := Color(0.95686275, 0.95686275, 0.95686275, 1)
const LINK := "73eff7"
const SCROLL_STEP := 24

@onready var _list: VBoxContainer = %List
@onready var _scroll: ScrollContainer = %Scroll
@onready var _back: Button = %BackButton


func _ready() -> void:
	_back.pressed.connect(_go_back)
	_build(_load())
	_back.grab_focus()


func _load() -> Dictionary:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Credits: cannot open %s" % DATA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _build(data: Dictionary) -> void:
	for section: Dictionary in data.get("sections", []):
		var heading := Label.new()
		heading.text = str(section.get("title", ""))
		heading.add_theme_font_override("font", FONT_BOLD)
		heading.add_theme_font_size_override("font_size", 6)
		heading.add_theme_color_override("font_color", GOLD)
		_list.add_child(heading)
		for entry: Dictionary in section.get("entries", []):
			_list.add_child(_entry(entry))


## One entry as a text block: the name, the link, the license and what was used. A link opens in the browser.
func _entry(entry: Dictionary) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("normal_font", FONT)
	label.add_theme_font_override("bold_font", FONT_BOLD)
	label.add_theme_font_size_override("normal_font_size", 6)
	label.add_theme_font_size_override("bold_font_size", 6)
	label.add_theme_color_override("default_color", TEXT)
	var lines: Array[String] = ["[b]%s[/b]" % _plain(str(entry.get("name", "")))]
	if entry.has("link"):
		lines.append(_link(str(entry["link"]), str(entry["link"])))
	if entry.has("license"):
		var license := _plain(str(entry["license"]))
		lines.append("License: %s" % (_link(str(entry["license_link"]), license) if entry.has("license_link") else license))
	if entry.has("note"):
		lines.append(_plain(str(entry["note"])))
	label.text = "\n".join(lines)
	label.meta_clicked.connect(func(meta: Variant) -> void: OS.shell_open(str(meta)))
	return label


## Text with no brackets, so a name or note can never be read as a tag.
func _plain(text: String) -> String:
	return text.replace("[", "[lb]")


func _link(url: String, shown: String) -> String:
	return "[color=#%s][url=%s]%s[/url][/color]" % [LINK, url, shown]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_go_back()
	elif event.is_action_pressed("ui_down"):
		_scroll.scroll_vertical += SCROLL_STEP
	elif event.is_action_pressed("ui_up"):
		_scroll.scroll_vertical -= SCROLL_STEP


func _go_back() -> void:
	SceneManager.load_scene(TITLE_SCENE)
