class_name CaseAppView
extends Control

## One table view reused by every evidence source (the tabs). show_source() swaps in a source's
## title, columns and rows; selecting a row fills the detail pane. The "investigate" button only
## asks: the Investigation decides what the player's thoughts about the entry are.

signal investigate_requested(entry: Dictionary)

const ROW_SCENE := preload("res://AI generated/scenes/investigation/CaseRow.tscn")
const STATE_FOUND := "found"
const STATE_SEEN := "seen"

var _case: Dictionary = {}
var _states: Dictionary = {} # entry id -> STATE_FOUND / STATE_SEEN, shared with the Investigation
var _selected_row: CaseRow

@onready var _title: Label = %Title
@onready var _guide: Label = %Guide
@onready var _header: HBoxContainer = %Header
@onready var _rows: VBoxContainer = %Rows
@onready var _detail_title: Label = %DetailTitle
@onready var _detail_body: RichTextLabel = %DetailBody
@onready var _investigate_button: Button = %InvestigateButton


func _ready() -> void:
	_investigate_button.pressed.connect(_on_investigate_pressed)
	_refresh_button()


## `states` is kept by reference: change it, then call refresh().
func setup(case_data: Dictionary, states: Dictionary) -> void:
	_case = case_data
	_states = states
	_guide.text = CaseData.ui(_case, "guide")


func show_source(source_id: String) -> void:
	var source := CaseData.get_source(_case, source_id)
	var widths: Array = source.get("widths", [])
	_title.text = str(source.get("title", ""))
	_set_header(source.get("columns", []), widths)
	_clear_rows()

	var texts := {
		"select": CaseData.ui(_case, "select"),
		"viewing": CaseData.ui(_case, "viewing"),
		"tags": [CaseData.ui(_case, "tag_found"), CaseData.ui(_case, "tag_seen")],
	}
	var trailing := 0.0
	for entry: Dictionary in source.get("entries", []):
		var row := ROW_SCENE.instantiate() as CaseRow
		_rows.add_child(row) # in the tree first: the row's @onready nodes must exist
		row.setup(entry, widths, texts)
		row.selected.connect(_select_row)
		trailing = row.get_trailing_width()
	_header_spacer(trailing)
	refresh()

	if _rows.get_child_count() > 0:
		_select_row(_rows.get_child(0) as CaseRow)
	else:
		_selected_row = null
		_detail_title.text = ""
		_detail_body.text = ""
		_refresh_button()


## Re-reads the shared states: the FOUND / SEEN tags and the investigate button.
func refresh() -> void:
	for row: CaseRow in _rows.get_children():
		row.set_tag(_tag_for(str(row.entry.get("id", ""))))
	_refresh_button()


func get_investigate_button() -> Button:
	return _investigate_button


func get_selected_entry() -> Dictionary:
	return _selected_row.entry if is_instance_valid(_selected_row) else {}


## Selects the row of an entry in the shown source. Returns false when it is not in this source.
func select_entry(entry_id: String) -> bool:
	for row: CaseRow in _rows.get_children():
		if row.entry.get("id", "") == entry_id:
			_select_row(row)
			return true
	return false


func _set_header(columns: Array, widths: Array) -> void:
	for child in _header.get_children():
		_header.remove_child(child)
		child.queue_free()
	for i in columns.size():
		var label := Label.new()
		label.text = str(columns[i])
		label.custom_minimum_size.x = float(widths[i]) if i < widths.size() else 0.0
		label.clip_text = true
		_header.add_child(label)


## Empty space at the end of the header, as wide as a row's tag and select button.
func _header_spacer(width: float) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size.x = width
	_header.add_child(spacer)


func _clear_rows() -> void:
	_selected_row = null
	for row in _rows.get_children():
		# Remove now so the old rows don't share the container with the new ones.
		_rows.remove_child(row)
		row.queue_free()


func _select_row(row: CaseRow) -> void:
	if is_instance_valid(_selected_row):
		_selected_row.set_selected(false)
	_selected_row = row
	row.set_selected(true)
	_detail_title.text = str(row.entry.get("title", ""))
	_detail_body.text = str(row.entry.get("detail", ""))
	_refresh_button()


func _tag_for(entry_id: String) -> String:
	match _states.get(entry_id, ""):
		STATE_FOUND:
			return CaseData.ui(_case, "tag_found")
		STATE_SEEN:
			return CaseData.ui(_case, "tag_seen")
	return ""


func _refresh_button() -> void:
	if not is_instance_valid(_selected_row):
		_investigate_button.disabled = true
		_investigate_button.text = CaseData.ui(_case, "investigate_none") if not _case.is_empty() else ""
		return
	_investigate_button.disabled = false
	match _states.get(str(_selected_row.entry.get("id", "")), ""):
		STATE_FOUND:
			_investigate_button.text = CaseData.ui(_case, "investigate_found") # words, not just a color
		STATE_SEEN:
			_investigate_button.text = CaseData.ui(_case, "investigate_again")
		_:
			_investigate_button.text = CaseData.ui(_case, "investigate")


func _on_investigate_pressed() -> void:
	if is_instance_valid(_selected_row):
		investigate_requested.emit(_selected_row.entry)
