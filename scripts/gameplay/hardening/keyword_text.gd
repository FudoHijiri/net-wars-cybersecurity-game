class_name KeywordText
extends RefCounted
## The colored, hoverable words of the card texts (data/keywords.json, see Keywords) for the Hardening screens, the
## same ones the Response fight shows: Block, Dodge, Exposed... Pointing at a colored word of a text shows what it
## means in a small panel; a card (its picture) gets the same explanations as its tooltip.

const FONT := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandard.otf")
const PANEL_WIDTH := 150.0
const HINT := "[color=#94b0c2]Point at a colored word.[/color]"


## "Block: what it does" for each keyword in a text, one per line. Empty when the text has none.
static func card_tooltip(text: String) -> String:
	var lines: Array[String] = []
	for id in Keywords.ids_in(text):
		var entry := Keywords.explain(id)
		lines.append("%s: %s" % [entry.get("name", id), entry.get("text", "")])
	return "\n".join(lines)


## Puts a text in a RichTextLabel with its keywords colored. `hint` adds the line that says the colored words can be
## pointed at (only when the text has any).
static func set_text(label: RichTextLabel, text: String, prefix: String = "", hint: bool = false) -> void:
	label.bbcode_enabled = true
	var body := prefix + Keywords.highlight(text)
	if hint and not Keywords.ids_in(text).is_empty():
		body += "\n" + HINT
	label.text = body


## A RichTextLabel that takes the place of a Label (same place, size and look), for the text that has keywords.
## The Label stays in the scene, hidden.
static func replace_label(label: Label, min_width: float = 0.0) -> RichTextLabel:
	var rich := RichTextLabel.new()
	rich.name = label.name + "Rich"
	rich.bbcode_enabled = true
	rich.scroll_active = false
	rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rich.mouse_filter = Control.MOUSE_FILTER_PASS
	rich.layout_mode = label.layout_mode
	rich.size_flags_horizontal = label.size_flags_horizontal
	rich.size_flags_vertical = label.size_flags_vertical
	rich.fit_content = true # as tall as its text (a Label is)
	rich.custom_minimum_size = Vector2(maxf(label.custom_minimum_size.x, min_width), label.custom_minimum_size.y)
	var settings := label.label_settings
	var font: Font = settings.font if settings != null and settings.font != null else FONT
	rich.add_theme_font_override("normal_font", font)
	rich.add_theme_font_override("bold_font", font)
	rich.add_theme_font_size_override("normal_font_size", settings.font_size if settings != null else 6)
	rich.add_theme_font_size_override("bold_font_size", settings.font_size if settings != null else 6)
	rich.add_theme_color_override("default_color", settings.font_color if settings != null else Color.WHITE)
	var parent := label.get_parent()
	parent.add_child(rich)
	parent.move_child(rich, label.get_index() + 1)
	if label.layout_mode == 1 or label.layout_mode == 0:
		rich.anchor_left = label.anchor_left
		rich.anchor_top = label.anchor_top
		rich.anchor_right = label.anchor_right
		rich.anchor_bottom = label.anchor_bottom
		rich.offset_left = label.offset_left
		rich.offset_top = label.offset_top
		rich.offset_right = label.offset_right
		rich.offset_bottom = label.offset_bottom
	label.hide()
	attach(rich)
	return rich


## Pointing at a colored word of the label shows what it means in a small panel above (or under) the label.
static func attach(label: RichTextLabel) -> void:
	label.bbcode_enabled = true
	var tip := PanelContainer.new()
	tip.name = "KeywordTip"
	tip.top_level = true # placed in screen coordinates, over the other controls
	tip.z_index = 200
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.hide()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.101960786, 0.10980392, 0.17254902)
	style.set_border_width_all(1)
	style.border_color = Color(0.3372549, 0.42352942, 0.5254902)
	style.set_content_margin_all(4)
	tip.add_theme_stylebox_override("panel", style)
	var words := Label.new()
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	words.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	words.add_theme_font_override("font", FONT)
	words.add_theme_font_size_override("font_size", 6)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(words)
	label.add_child(tip)
	label.meta_hover_started.connect(func(meta: Variant) -> void: _show_tip(label, tip, words, str(meta)))
	label.meta_hover_ended.connect(func(_meta: Variant) -> void: tip.hide())
	label.visibility_changed.connect(func() -> void: tip.hide())


static func _show_tip(label: RichTextLabel, tip: PanelContainer, words: Label, id: String) -> void:
	var entry := Keywords.explain(id)
	if entry.is_empty():
		return
	words.text = "%s: %s" % [entry.get("name", id), entry.get("text", "")]
	words.add_theme_color_override("font_color", Keywords.color_of(id))
	tip.reset_size()
	var rect := label.get_global_rect()
	var at := rect.position + Vector2(0, -tip.size.y - 2.0)
	if rect.position.x > 400.0: # the info panel on the right: the panel goes to its left, at the height of the word
		at = Vector2(rect.position.x - tip.size.x - 4.0, label.get_global_mouse_position().y - tip.size.y / 2.0)
	elif at.y < 26.0: # no room above: under the text
		at.y = rect.end.y + 2.0
	at.x = clampf(at.x, 2.0, 638.0 - tip.size.x)
	at.y = clampf(at.y, 26.0, 358.0 - tip.size.y)
	tip.global_position = at
	tip.show()
