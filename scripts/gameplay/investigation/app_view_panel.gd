class_name AppViewPanel
extends Control

## One table view reused by every investigation tab. load_app() swaps in an app's
## title, columns and rows from GameState; selecting a row fills the detail pane.
##
## The Investigate button plays the entry's short monologue. The first time, that also
## records the entry as investigated: a real clue is marked and tagged FOUND, anything
## else is tagged READ. The summary under the detail text shows once it was investigated.

const ROW_SCENE := preload("res://scenes/gameplay/investigation/row.tscn")
const INVESTIGATE_TEXT := "INVESTIGATE LOG"
const INVESTIGATE_AGAIN_TEXT := "INVESTIGATE AGAIN"
# Text, not just color, tells a clue from a normal entry.
const CLUE_SUMMARY_PREFIX := "[!] CLUE: "
const NORMAL_SUMMARY_PREFIX := "[=] NORMAL: "

## Emitted once the player has found every clue and the closing monologue is over.
signal all_clues_found

var _selected_row: InvestigationRow
var _app_widths: Array = [] # the app's own column widths, before fitting
var _app_columns: Array = []
var _trailing_width := 0.0 # tag + Select button, after the cells
var _fitted_widths: Array = []
## The Monologue node of Investigation.tscn, handed over by investigation.gd.
var monologue: Monologue

@onready var _title: RichTextLabel = %Title
# These two keep their original scene names, which are not unique in this scene
# otherwise: the header HBox and the rows VBox.
@onready var _header: HBoxContainer = %HSplitContainer
@onready var _rows: VBoxContainer = %VBoxContainer
@onready var _select_spacer: Control = %SelectSpacer
@onready var _rows_scroll: ScrollContainer = _rows.get_parent()
@onready var _left: Control = $HSplitContainer/Left
@onready var _detail_title: RichTextLabel = %RightTitle
@onready var _detail_body: RichTextLabel = %"Main Content"
@onready var _hints: RichTextLabel = %EvidenceHints
@onready var _investigate_button: Button = %MarkClueButton


func _ready() -> void:
	_refresh_investigate_button()
	# The pane may not have its final size yet, and a scroll bar appearing takes width,
	# so fit the columns again whenever either changes.
	_left.resized.connect(_fit_columns)
	_rows_scroll.get_v_scroll_bar().visibility_changed.connect(_fit_columns)


func load_app(app_id: String) -> void:
	if not is_node_ready():
		await ready
	var app := GameState.get_app(app_id)
	if app.is_empty():
		push_warning("AppViewPanel: no data for app '%s'" % app_id)

	_app_widths = app.get("widths", [])
	_app_columns = app.get("columns", [])
	_title.text = str(app.get("title", ""))
	_clear_rows()

	var entries: Array = app.get("entries", [])
	for entry_data: Dictionary in entries:
		var row := ROW_SCENE.instantiate() as InvestigationRow
		_rows.add_child(row) # in the tree first: the row's @onready nodes must exist
		row.setup(entry_data, _app_widths)
		row.selected.connect(_on_row_selected.bind(row))
		_trailing_width = row.get_trailing_width()
		row.set_tag(_tag_for(str(entry_data.get("id", ""))))

	_fitted_widths = []
	_fit_columns()

	if _rows.get_child_count() > 0:
		_select_row(_rows.get_child(0) as InvestigationRow)
	else:
		_detail_title.text = ""
		_detail_body.text = ""
		_refresh_hints()
		_refresh_investigate_button()


## Shrinks the columns in proportion so cells, tag and Select button fit the pane
## instead of running under the detail pane. Cell text is trimmed with "..." to match.
func _fit_columns() -> void:
	# Measure the Left pane, not the scroll container: with horizontal scrolling off the
	# scroll container reports the rows' width as its own minimum, so it never shrinks.
	var rows_frame := _rows_scroll.get_parent_control()
	var available := _left.size.x - _trailing_width
	available -= rows_frame.get_theme_stylebox(&"panel").get_minimum_size().x
	var scroll_bar := _rows_scroll.get_v_scroll_bar()
	if scroll_bar.visible:
		available -= scroll_bar.get_combined_minimum_size().x
	var total := 0.0
	for width in _app_widths:
		total += float(width)
	var fitted: Array = []
	for width in _app_widths:
		var fitted_width := float(width)
		if available > 0.0 and total > available:
			fitted_width = floorf(fitted_width * available / total)
		fitted.append(fitted_width)
	if fitted == _fitted_widths:
		return
	_fitted_widths = fitted

	_set_header(_app_columns, fitted)
	_select_spacer.custom_minimum_size.x = _trailing_width
	for row: InvestigationRow in _rows.get_children():
		row.set_widths(fitted)


func _set_header(columns: Array, widths: Array) -> void:
	var index := 0
	for child in _header.get_children():
		var label := child as Label
		if label == null:
			continue
		if index < columns.size() and index < widths.size():
			label.text = str(columns[index])
			label.custom_minimum_size.x = float(widths[index])
			label.size_flags_horizontal = Control.SIZE_FILL
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.show()
		else:
			label.hide()
		index += 1


func _clear_rows() -> void:
	_selected_row = null
	for row in _rows.get_children():
		# Remove now so the old rows don't share the container with the new ones.
		_rows.remove_child(row)
		row.queue_free()


func _select_row(row: InvestigationRow) -> void:
	if is_instance_valid(_selected_row):
		_selected_row.set_selected(false)
	_selected_row = row
	row.set_selected(true)
	_detail_title.text = str(row.entry.get("title", ""))
	_detail_body.text = str(row.entry.get("detail", ""))
	_refresh_hints()
	_refresh_investigate_button()


## TAG_FOUND for a clue the player found, TAG_READ for an investigated normal entry,
## an empty text for an entry not investigated yet.
func _tag_for(entry_id: String) -> String:
	if GameState.is_marked(entry_id):
		return InvestigationRow.TAG_FOUND
	if GameState.is_investigated(entry_id):
		return InvestigationRow.TAG_READ
	return ""


## The summary of the monologue under the detail text. It only shows once the entry
## has been investigated, so it never gives the answer away early.
func _refresh_hints() -> void:
	var entry_id := _selected_entry_id()
	_hints.visible = GameState.is_investigated(entry_id)
	if not _hints.visible:
		_hints.text = ""
		return
	var entry := _selected_row.entry
	var prefix := CLUE_SUMMARY_PREFIX if entry.get("is_clue", false) else NORMAL_SUMMARY_PREFIX
	_hints.text = prefix + str(entry.get("summary", ""))


func _refresh_investigate_button() -> void:
	var entry_id := _selected_entry_id()
	_investigate_button.disabled = entry_id.is_empty()
	_investigate_button.text = INVESTIGATE_AGAIN_TEXT if GameState.is_investigated(entry_id) else INVESTIGATE_TEXT


func _selected_entry_id() -> String:
	if not is_instance_valid(_selected_row):
		return ""
	return str(_selected_row.entry.get("id", ""))


func _on_row_selected(_entry: Dictionary, row: InvestigationRow) -> void:
	_select_row(row)


# Connected to MarkClueButton.pressed in Investigation.tscn.
func _on_mark_clue_button_pressed() -> void:
	if not is_instance_valid(_selected_row) or monologue.is_open():
		return
	var row := _selected_row
	var entry := row.entry
	var entry_id := str(entry.get("id", ""))
	var first_time := not GameState.is_investigated(entry_id)

	var lines: Array = entry.get("monologue", [])
	if not lines.is_empty(): # play() with no lines finishes before there is anything to await
		monologue.play(lines, _speaker())
		await monologue.finished
	if not first_time:
		return

	GameState.set_investigated(entry_id)
	var is_clue: bool = entry.get("is_clue", false)
	if is_clue:
		GameState.set_marked(entry_id, true)
	if is_instance_valid(row):
		row.set_tag(_tag_for(entry_id))
	if _selected_row == row:
		_refresh_hints()
		_refresh_investigate_button()

	# The last clue also tells the player what to do next.
	if is_clue and GameState.marked_count() == GameState.clues_required():
		var closing: Array = GameState.scenario.get("all_clues_monologue", [])
		if not closing.is_empty():
			monologue.play(closing, _speaker())
			await monologue.finished
		all_clues_found.emit()


func _speaker() -> String:
	return str(GameState.scenario.get("speaker", ""))
