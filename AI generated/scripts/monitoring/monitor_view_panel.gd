class_name MonitorViewPanel
extends Control

## One table of live events, reused for every Monitoring view. The menu owns the event
## dictionaries and sets their `seen` / `reported` flags; this panel only displays them.

signal report_requested(event: Dictionary)

const ROW_SCENE := preload("res://scenes/gameplay/investigation/row.tscn")
const REPORT_TEXT := "REPORT ANOMALY"
const REPORTED_TEXT := "REPORTED"
const NEW_TEXT := "NEW"
const NO_EVENT_TEXT := "No events yet. They show up here as they happen."

var _views: Dictionary = {}   # view id -> {title, columns, widths}
var _events: Dictionary = {}  # view id -> Array of event dictionaries, newest first
var _view_id := ""
var _selected_row: InvestigationRow

@onready var _title: RichTextLabel = %Title
@onready var _guide: RichTextLabel = %Guide
@onready var _header: HBoxContainer = %HeaderRow
@onready var _select_spacer: Control = %SelectSpacer
@onready var _rows: VBoxContainer = %RowsList
@onready var _detail_title: RichTextLabel = %DetailTitle
@onready var _detail_body: RichTextLabel = %DetailBody
@onready var _report_button: Button = %ReportButton


func _ready() -> void:
	_report_button.pressed.connect(_on_report_pressed)
	_refresh_detail()


## views: the "views" block of the monitoring data (title, columns, widths per view id).
func configure(views: Dictionary) -> void:
	_views = views


func set_guide_text(text: String) -> void:
	_guide.text = text


func show_view(view_id: String) -> void:
	if not _views.has(view_id):
		push_warning("MonitorViewPanel: unknown view '%s'" % view_id)
		return
	_view_id = view_id
	var view: Dictionary = _views[view_id]
	_title.text = str(view.get("title", ""))
	_set_header(view.get("columns", []), view.get("widths", []))
	_selected_row = null
	PhaseTransition.clear_children(_rows)
	for event: Dictionary in _events.get(view_id, []):
		_add_row(event, _rows.get_child_count())
	if _rows.get_child_count() > 0:
		_select_row(_rows.get_child(0) as InvestigationRow)
	else:
		_refresh_detail()


## New events go to the top of their view's list.
func add_event(event: Dictionary) -> void:
	var view_id := str(event.get("view", ""))
	if not _events.has(view_id):
		_events[view_id] = []
	_events[view_id].insert(0, event)
	if view_id != _view_id:
		return
	_add_row(event, 0)
	if _selected_row == null: # first event of an empty view: show it
		_select_row(_rows.get_child(0) as InvestigationRow)


## Redraws the STATUS cells and the detail pane after an event's flags changed.
func refresh_status() -> void:
	var widths: Array = _views.get(_view_id, {}).get("widths", [])
	for row: InvestigationRow in _rows.get_children():
		var event: Dictionary = row.entry["event"]
		row.setup(_display_entry(event), widths)
	_refresh_detail()


func _add_row(event: Dictionary, index: int) -> void:
	var row := ROW_SCENE.instantiate() as InvestigationRow
	_rows.add_child(row) # in the tree first: the row's @onready nodes must exist
	_rows.move_child(row, index)
	row.setup(_display_entry(event), _views[_view_id].get("widths", []))
	row.selected.connect(_on_row_selected.bind(row))
	_select_spacer.custom_minimum_size.x = row.get_select_width()


## The row's entry: the event's cells plus the STATUS cell, and the event itself.
func _display_entry(event: Dictionary) -> Dictionary:
	var cells: Array = event.get("cells", []).duplicate()
	cells.append(_status_text(event))
	return {"id": event.get("id", ""), "cells": cells, "event": event}


func _status_text(event: Dictionary) -> String:
	if event.get("reported", false):
		return REPORTED_TEXT
	return "" if event.get("seen", false) else NEW_TEXT


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


func _select_row(row: InvestigationRow) -> void:
	if is_instance_valid(_selected_row):
		_selected_row.set_selected(false)
	_selected_row = row
	row.set_selected(true)
	_refresh_detail()


func _selected_event() -> Dictionary:
	if not is_instance_valid(_selected_row):
		return {}
	return _selected_row.entry["event"]


func _refresh_detail() -> void:
	var event := _selected_event()
	if event.is_empty():
		_detail_title.text = ""
		_detail_body.text = NO_EVENT_TEXT
		_report_button.disabled = true
		_report_button.text = REPORT_TEXT
		return
	var reported: bool = event.get("reported", false)
	_detail_title.text = str(event.get("title", ""))
	var body := str(event.get("detail", ""))
	if reported: # the answer is only shown once the player has decided
		body += "\n\nWHY: %s" % str(event.get("explain", ""))
	_detail_body.text = body
	_report_button.disabled = reported
	_report_button.text = REPORTED_TEXT if reported else REPORT_TEXT


func _on_row_selected(_entry: Dictionary, row: InvestigationRow) -> void:
	_select_row(row)


func _on_report_pressed() -> void:
	var event := _selected_event()
	if not event.is_empty():
		report_requested.emit(event)
