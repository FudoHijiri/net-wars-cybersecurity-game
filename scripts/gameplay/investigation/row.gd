class_name InvestigationRow
extends Control

## One table row of an investigation app. Add it to the tree before calling setup().

signal selected(entry: Dictionary)

const MIN_HEIGHT := 14.0
const SELECT_TEXT := " SELECT "
const VIEWING_TEXT := " VIEWING " # text, not just color, marks the shown entry
const TAG_FOUND := "FOUND"
const TAG_READ := "READ"

var entry: Dictionary = {}

@onready var _columns: HBoxContainer = %HSplitContainer
@onready var _select_button: Button = %Button
@onready var _tag: Label = $HSplitContainer/Tag


func _ready() -> void:
	# The cells' HBox fills the row, but its minimum size is set before the row has
	# been sized. With "grow both ways" it would grow up and left and keep that offset,
	# drawing the row's content above and left of the row. Grow down and right only.
	_columns.grow_horizontal = Control.GROW_DIRECTION_END
	_columns.grow_vertical = Control.GROW_DIRECTION_END
	# Reserve room for the longer of the two button texts so the column never
	# changes width when a row becomes the selected one.
	var font := _select_button.get_theme_font(&"font")
	var font_size := _select_button.get_theme_font_size(&"font_size")
	var text_width := 0.0
	for text: String in [SELECT_TEXT, VIEWING_TEXT]:
		text_width = maxf(text_width, font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var style := _select_button.get_theme_stylebox(&"normal")
	_select_button.custom_minimum_size.x = ceilf(text_width + style.get_minimum_size().x)
	_select_button.text = SELECT_TEXT
	_select_button.pressed.connect(_on_select_pressed)
	# Same for the tag: reserve room for the longest tag word. Its font comes from
	# label_settings, not the theme.
	var tag_font := _tag.label_settings.font
	var tag_font_size := _tag.label_settings.font_size
	var tag_width := 0.0
	for text: String in [TAG_FOUND, TAG_READ]:
		tag_width = maxf(tag_width, tag_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_font_size).x)
	# The label's own style (margins) adds to the width the text needs.
	var tag_style := _tag.get_theme_stylebox(&"normal")
	_tag.custom_minimum_size.x = ceilf(tag_width + tag_style.get_minimum_size().x) + 2.0
	_tag.text = ""


## Width of everything after the cells (tag and Select). The header adds a spacer of the same width.
func get_trailing_width() -> float:
	return _tag.custom_minimum_size.x + _select_button.custom_minimum_size.x


## TAG_FOUND, TAG_READ or an empty text. Text, not just color, shows the state.
func set_tag(text: String) -> void:
	_tag.text = text


## Fills the cell labels from entry["cells"], giving column i a fixed width of widths[i].
func setup(new_entry: Dictionary, widths: Array) -> void:
	entry = new_entry
	var cells: Array = entry.get("cells", [])
	var index := 0
	for child in _columns.get_children():
		var label := child as Label
		if label == null or label == _tag: # the tag is not a data cell
			continue
		if index < cells.size():
			label.text = str(cells[index])
		index += 1
	set_widths(widths)


## Resizes the columns. Called again when the pane changes size; cell text that no
## longer fits ends in "..." instead of running under the next column.
func set_widths(widths: Array) -> void:
	var cells: Array = entry.get("cells", [])
	var index := 0
	for child in _columns.get_children():
		var label := child as Label
		if label == null or label == _tag:
			continue
		if index < cells.size() and index < widths.size():
			label.custom_minimum_size.x = float(widths[index])
			label.size_flags_horizontal = Control.SIZE_FILL
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.show()
		else:
			label.hide()
		index += 1
	# The inner HBox is anchored full rect, so the row itself has to report its size.
	var columns_size := _columns.get_combined_minimum_size()
	custom_minimum_size = Vector2(columns_size.x, maxf(MIN_HEIGHT, columns_size.y))


func set_selected(value: bool) -> void:
	_select_button.text = VIEWING_TEXT if value else SELECT_TEXT


func _on_select_pressed() -> void:
	selected.emit(entry)
