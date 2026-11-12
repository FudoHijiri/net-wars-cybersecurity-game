extends RecoveryTask

## A grid of who may open which folder: take away the access a person does not need, and keep what their job
## needs (taking that away bounces back with its reason). Layout: PermissionGrid.tscn (the grid is built here from
## content.columns [{id, label}] and content.rows [{id, label, needs: [column ids], start: [column ids], reason}]).
## The task finishes when every row has exactly the access it needs. Used for "Reopen the shared folders" (Day 3).

var _cells: Dictionary = {} # "row|column" -> CheckButton
var _rows: Array = []
var _columns: Array = []


func setup_task() -> void:
	_rows = content.get("rows", [])
	_columns = content.get("columns", [])
	var heading := Label.new()
	heading.theme_type_variation = &"RecoveryAccent"
	heading.text = str(content.get("heading", ""))
	body.add_child(heading)
	var grid := GridContainer.new()
	grid.columns = _columns.size() + 1
	grid.add_theme_constant_override("h_separation", 12)
	body.add_child(grid)
	grid.add_child(Label.new())
	for column: Dictionary in _columns:
		var title := Label.new()
		title.theme_type_variation = &"RecoveryMuted"
		title.text = str(column["label"])
		grid.add_child(title)
	for row: Dictionary in _rows:
		var name_label := Label.new()
		name_label.text = str(row["label"])
		name_label.custom_minimum_size = Vector2(110, 0)
		grid.add_child(name_label)
		for column: Dictionary in _columns:
			var cell := CheckButton.new()
			cell.text = str(content.get("can_open", "May open"))
			cell.toggled.connect(_toggled.bind(str(row["id"]), str(column["id"])))
			grid.add_child(cell)
			_cells[_key(str(row["id"]), str(column["id"]))] = cell


func reset_state() -> void:
	for row: Dictionary in _rows:
		for column: Dictionary in _columns:
			_cells[_key(str(row["id"]), str(column["id"]))].set_pressed_no_signal(row.get("start", []).has(column["id"]))
	set_feedback(str(content.get("pick", "")))


func _key(row_id: String, column_id: String) -> String:
	return "%s|%s" % [row_id, column_id]


func _toggled(on: bool, row_id: String, column_id: String) -> void:
	if solved:
		return
	var row := _row(row_id)
	var needed: bool = row.get("needs", []).has(column_id)
	var cell: CheckButton = _cells[_key(row_id, column_id)]
	if not on and needed: # takes away what the job needs
		cell.set_pressed_no_signal(true)
		UiFx.shake(cell)
		note_mistake(str(row.get("reason", "")))
		return
	if on and not needed:
		set_feedback(str(content.get("extra", "")), "hint")
		return
	if not on:
		set_feedback(str(content.get("removed", "")).format({"who": row["label"]}), "good")
	if _all_right():
		succeed()


func _row(row_id: String) -> Dictionary:
	for row: Dictionary in _rows:
		if str(row["id"]) == row_id:
			return row
	return {}


func _all_right() -> bool:
	for row: Dictionary in _rows:
		for column: Dictionary in _columns:
			var open: bool = _cells[_key(str(row["id"]), str(column["id"]))].button_pressed
			if open != row.get("needs", []).has(column["id"]):
				return false
	return true
