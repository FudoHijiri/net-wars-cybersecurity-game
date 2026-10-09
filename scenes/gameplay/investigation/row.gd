class_name InvestigationRow
extends Control

## One table row of an investigation app. Add it to the tree before calling setup().

signal selected(entry: Dictionary)

const MIN_HEIGHT := 14.0
const SELECT_TEXT := " Select "
const VIEWING_TEXT := " Viewing " # text, not just color, marks the shown entry

var entry: Dictionary = {}

@onready var _columns: HBoxContainer = %HSplitContainer
@onready var _select_button: Button = %Button


func _ready() -> void:
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


## Width of the Select column. The header adds a spacer of the same width.
func get_select_width() -> float:
	return _select_button.custom_minimum_size.x


## Fills the cell labels from entry["cells"], giving column i a fixed width of widths[i].
func setup(new_entry: Dictionary, widths: Array) -> void:
	entry = new_entry
	var cells: Array = entry.get("cells", [])
	var index := 0
	for child in _columns.get_children():
		var label := child as Label
		if label == null:
			continue
		if index < cells.size() and index < widths.size():
			label.text = str(cells[index])
			label.custom_minimum_size.x = float(widths[index])
			label.size_flags_horizontal = Control.SIZE_FILL
			label.clip_text = true
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
