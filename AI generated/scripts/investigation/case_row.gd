class_name CaseRow
extends PanelContainer

## One table row of an evidence source. Add it to the tree, then call setup().
## The state is also written out: the tag column says FOUND or SEEN, and the button says
## Viewing, so nothing relies on color.

signal selected(row: CaseRow)

const MIN_HEIGHT := 14.0
const STYLE_NORMAL := &"RowPanel"
const STYLE_SELECTED := &"RowPanelSelected"

var entry: Dictionary = {}

@onready var _cells: HBoxContainer = %Cells
@onready var _tag: Label = %Tag
@onready var _select_button: Button = %SelectButton

var _select_text := ""
var _viewing_text := ""


func _ready() -> void:
	theme_type_variation = STYLE_NORMAL
	_select_button.pressed.connect(func() -> void: selected.emit(self))


## Fills the cell labels from entry["cells"], giving column i a fixed width of widths[i].
## `texts` carries the button and tag words from the case data: select, viewing and tags (every
## tag the row can show). Both columns reserve room for their longest text, so nothing moves
## when a row's state changes.
func setup(new_entry: Dictionary, widths: Array, texts: Dictionary) -> void:
	entry = new_entry
	_select_text = str(texts.get("select", ""))
	_viewing_text = str(texts.get("viewing", ""))
	var button_font := _select_button.get_theme_font(&"font")
	var button_font_size := _select_button.get_theme_font_size(&"font_size")
	var button_width := 0.0
	for text: String in [_select_text, _viewing_text]:
		button_width = maxf(button_width, button_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, button_font_size).x)
	var button_style := _select_button.get_theme_stylebox(&"normal")
	_select_button.custom_minimum_size.x = ceilf(button_width + button_style.get_minimum_size().x)
	var tag_font := _tag.get_theme_font(&"font")
	var tag_font_size := _tag.get_theme_font_size(&"font_size")
	var tag_width := 0.0
	for text: String in texts.get("tags", []):
		tag_width = maxf(tag_width, tag_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_font_size).x)
	_tag.custom_minimum_size.x = ceilf(tag_width) + 2.0
	var cells: Array = entry.get("cells", [])
	for i in cells.size():
		var label := Label.new()
		label.text = str(cells[i])
		label.custom_minimum_size.x = float(widths[i]) if i < widths.size() else 0.0
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cells.add_child(label)
	custom_minimum_size.y = MIN_HEIGHT
	set_selected(false)
	set_tag("")


## Width of everything after the cells. The table header adds a spacer of the same width.
func get_trailing_width() -> float:
	return _tag.custom_minimum_size.x + _select_button.custom_minimum_size.x + 4.0


func set_selected(value: bool) -> void:
	_select_button.text = _viewing_text if value else _select_text
	theme_type_variation = STYLE_SELECTED if value else STYLE_NORMAL


## "FOUND", "SEEN" or an empty text.
func set_tag(text: String) -> void:
	_tag.text = text


func focus_select() -> void:
	_select_button.grab_focus()
