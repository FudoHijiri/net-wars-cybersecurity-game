class_name InvestigationRow
extends Control

## One table row of an investigation app. Add it to the tree before calling setup(). The row itself is what is
## clicked (there is no button in it): the pointed row is lighter, the shown row has a color and a bar at its
## left, and the shown entry is also named in the detail pane, so it is not only a color.

signal selected(entry: Dictionary)

const MIN_HEIGHT := 14.0
const SHOWN_FILL := Color(0.23137255, 0.3647059, 0.7882353, 0.55)
const HOVER_FILL := Color(0.23137255, 0.3647059, 0.7882353, 0.25)
const TAG_FOUND := "FOUND"
const TAG_READ := "READ"
const TAG_NEW := "NEW" # an answer that appeared after a question was sent

var entry: Dictionary = {}
var _shown := false
var _pointed := false

@onready var _columns: HBoxContainer = %HSplitContainer
@onready var _tag: Label = $HSplitContainer/Tag


func _ready() -> void:
	# The cells' HBox fills the row, but its minimum size is set before the row has
	# been sized. With "grow both ways" it would grow up and left and keep that offset,
	# drawing the row's content above and left of the row. Grow down and right only.
	_columns.grow_horizontal = Control.GROW_DIRECTION_END
	_columns.grow_vertical = Control.GROW_DIRECTION_END
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_entered.connect(func() -> void:
		_pointed = true
		queue_redraw())
	mouse_exited.connect(func() -> void:
		_pointed = false
		queue_redraw())
	# Same for the tag: reserve room for the longest tag word. Its font comes from
	# label_settings, not the theme.
	var tag_font := _tag.label_settings.font
	var tag_font_size := _tag.label_settings.font_size
	var tag_width := 0.0
	for text: String in [TAG_FOUND, TAG_READ, TAG_NEW]:
		tag_width = maxf(tag_width, tag_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, tag_font_size).x)
	# The label's own style (margins) adds to the width the text needs.
	var tag_style := _tag.get_theme_stylebox(&"normal")
	_tag.custom_minimum_size.x = ceilf(tag_width + tag_style.get_minimum_size().x) + 2.0
	_tag.text = ""


## Width of everything after the cells (the tag). The header adds a spacer of the same width.
func get_trailing_width() -> float:
	return _tag.custom_minimum_size.x


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


## What the player sees when this entry has just been investigated. A clue stamps its tag, glints and gets a
## star; a normal entry only fades its tag in, quietly: a different shape and motion, not just a color.
func celebrate(is_clue: bool) -> void:
	if not is_inside_tree():
		return
	var at := UiFx.center_of(_tag)
	Sfx.play(&"clue" if is_clue else &"select")
	if is_clue:
		UiFx.pop(_tag, 0.3, 0.3)
		UiFx.flash(self, UiFx.GOLD, 0.5)
		UiFx.sparkle(UiFx.center_of(self), UiFx.GOLD, 14)
		UiFx.badge(Glyph.Kind.STAR, UiFx.GOLD, at + Vector2(-_tag.size.x / 2.0 - 8.0, 0.0), 1, 1.0)
	else:
		UiFx.fade_in(_tag, 0.3)


func set_selected(value: bool) -> void:
	_shown = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Sfx.play(&"select")
		selected.emit(entry)
		accept_event()


func _draw() -> void:
	if _shown:
		draw_rect(Rect2(Vector2.ZERO, size), SHOWN_FILL)
		draw_rect(Rect2(0, 0, 2, size.y), GameColors.highlight)
	elif _pointed:
		draw_rect(Rect2(Vector2.ZERO, size), HOVER_FILL)
