class_name AppViewPanel
extends Control

## One table view reused by every investigation tab. load_app() swaps in an app's
## title, columns and rows from GameState; selecting a row fills the detail pane.

const ROW_SCENE := preload("res://scenes/gameplay/investigation/row.tscn")
const MARK_TEXT := "[  ] MARK AS CLUE"
const MARKED_TEXT := "[X] MARKED AS CLUE" # text, not just color, shows the state
const MAX_RELATED_SHOWN := 3
const RELATED_LABEL_CHARS := 46

var _selected_row: InvestigationRow

@onready var _title: RichTextLabel = %Title
# These two keep their original scene names, which are not unique in this scene
# otherwise: the header HBox and the rows VBox.
@onready var _header: HBoxContainer = %HSplitContainer
@onready var _rows: VBoxContainer = %VBoxContainer
@onready var _select_spacer: Control = %SelectSpacer
@onready var _detail_title: RichTextLabel = %RightTitle
@onready var _detail_body: RichTextLabel = %"Main Content"
@onready var _hints: RichTextLabel = %EvidenceHints
@onready var _mark_button: Button = %MarkClueButton


func _ready() -> void:
	_refresh_mark_button()


func load_app(app_id: String) -> void:
	if not is_node_ready():
		await ready
	var app := GameState.get_app(app_id)
	if app.is_empty():
		push_warning("AppViewPanel: no data for app '%s'" % app_id)

	var widths: Array = app.get("widths", [])
	_title.text = str(app.get("title", ""))
	_set_header(app.get("columns", []), widths)
	_clear_rows()

	var entries: Array = app.get("entries", [])
	for entry_data: Dictionary in entries:
		var row := ROW_SCENE.instantiate() as InvestigationRow
		_rows.add_child(row) # in the tree first: the row's @onready nodes must exist
		row.setup(entry_data, widths)
		row.selected.connect(_on_row_selected.bind(row))
		_select_spacer.custom_minimum_size.x = row.get_select_width()

	if _rows.get_child_count() > 0:
		_select_row(_rows.get_child(0) as InvestigationRow)
	else:
		_detail_title.text = ""
		_detail_body.text = ""
		_refresh_hints()
		_refresh_mark_button()


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
			label.clip_text = true
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
	_refresh_mark_button()


## The two evidence lines under the detail text. They describe how ordinary the entry
## is and what else mentions the same things; they never say whether it is a clue.
func _refresh_hints() -> void:
	var entry_id := _selected_entry_id()
	_hints.visible = not entry_id.is_empty()
	_hints.text = _hint_text(_selected_row.entry, entry_id) if _hints.visible else ""


func _hint_text(entry: Dictionary, entry_id: String) -> String:
	var lines: Array[String] = []
	var baseline := str(entry.get("baseline", ""))
	if not baseline.is_empty():
		lines.append(("[!] " if baseline.begins_with("NEW:") else "[=] ") + baseline)
	var related := GameState.related_entries(entry_id)
	lines.append("RELATED: %d other %s" % [related.size(), "entry" if related.size() == 1 else "entries"])
	for item: Dictionary in related.slice(0, MAX_RELATED_SHOWN):
		lines.append("  - " + _related_label(item))
	return "\n".join(lines)


## Short label such as "LOGIN: Sign-in from Germany (02:43)": the app name, the entry's
## title and its first column.
func _related_label(item: Dictionary) -> String:
	var entry: Dictionary = item["entry"]
	var cells: Array = entry.get("cells", [])
	var label := "%s: %s" % [str(item["app_id"]).to_upper(), str(entry.get("title", ""))]
	if not cells.is_empty():
		label += " (%s)" % str(cells[0])
	return label if label.length() <= RELATED_LABEL_CHARS else label.left(RELATED_LABEL_CHARS - 2) + ".."


## Shows the selected entry's own marked state without triggering a change.
func _refresh_mark_button() -> void:
	var entry_id := _selected_entry_id()
	_mark_button.disabled = entry_id.is_empty()
	var marked := not entry_id.is_empty() and GameState.is_marked(entry_id)
	_mark_button.set_pressed_no_signal(marked)
	_mark_button.text = MARKED_TEXT if marked else MARK_TEXT


func _selected_entry_id() -> String:
	if not is_instance_valid(_selected_row):
		return ""
	return str(_selected_row.entry.get("id", ""))


func _on_row_selected(_entry: Dictionary, row: InvestigationRow) -> void:
	_select_row(row)


# Connected to MarkClueButton.toggled in AppViewPanel.tscn.
func _on_mark_clue_button_toggled(toggled_on: bool) -> void:
	var entry_id := _selected_entry_id()
	if entry_id.is_empty():
		return
	GameState.set_marked(entry_id, toggled_on)
	_mark_button.text = MARKED_TEXT if toggled_on else MARK_TEXT
