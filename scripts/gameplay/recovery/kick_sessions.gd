extends RecoveryTask

## Kick Sessions, and any "act on the bad rows, keep the good ones" list. Layout: KickSessions.tscn.
## Also drives ChangeReusedPasswords.tscn (inherits it): only the JSON differs. Rows come from
## content.items (or content.sessions); a row with "known": true must be kept and bounces with its reason.
## Optional content.final_switch shows %FinalSwitch (e.g. "Turn on 2-step sign-in"): the task then
## finishes when the list is clean AND the switch is on. Without it, a clean list finishes the task.
## Each SessionRow under %Sessions shows one device signed in to the account, filled in
## order from the JSON. Signing out an unknown device removes it; signing out a known
## device bounces with its reason. The task finishes when no unknown device is left.

var sign_out_buttons: Dictionary = {}
var signed_out: Array[String] = []
var _rows: Dictionary = {}
var _sessions: Dictionary = {}

@onready var final_switch: CheckButton = %FinalSwitch


func setup_task() -> void:
	%AccountLabel.text = str(content.get("account_label", "Signed in to: {account}")).format({"account": content.get("account", "")})
	# Optional column headings (UndoChanges.tscn: %Column2 / %Column3 from content.columns).
	var columns: Dictionary = content.get("columns", {})
	for pair: Array in [["%Column2", "who"], ["%Column3", "what"]]:
		var heading := get_node_or_null(pair[0]) as Label
		if heading and columns.has(pair[1]):
			heading.text = str(columns[pair[1]])
	var sessions: Array = content.get("items", content.get("sessions", []))
	var rows := %Sessions.get_children()
	for i in rows.size():
		var row := rows[i] as RecoverySessionRow
		row.visible = i < sessions.size()
		if not row.visible:
			continue
		var session: Dictionary = sessions[i]
		var id := str(session["id"])
		row.show_session(session)
		row.sign_out_button.text = str(content.get("sign_out", "Sign out"))
		row.sign_out_button.pressed.connect(_sign_out.bind(id))
		_rows[id] = row
		_sessions[id] = session
		sign_out_buttons[id] = row.sign_out_button
	final_switch.visible = content.has("final_switch")
	final_switch.text = str(content.get("final_switch", ""))
	if _rows.size() < sessions.size():
		push_warning("KickSessions.tscn has fewer session rows than the JSON lists.")


func reset_state() -> void:
	signed_out.clear()
	final_switch.set_pressed_no_signal(false)
	for id: String in _rows:
		_rows[id].set_state("active", "")
	set_feedback(str(content.get("pick", "")))


func _sign_out(id: String) -> void:
	if solved or signed_out.has(id):
		return
	var session: Dictionary = _sessions[id]
	if session.get("known", false):
		var row: RecoverySessionRow = _rows[id]
		_wobble(row)
		note_mistake(str(session.get("reason", "")))
		return
	signed_out.append(id)
	_rows[id].set_state("signed_out", str(content.get("signed_out", "[OK] SIGNED OUT")))
	var left := _unknown_left()
	if left == 0 and final_switch.visible:
		set_feedback(str(content.get("final_prompt", "")))
		final_switch.grab_focus()
	elif left == 0:
		succeed()
	else:
		set_feedback(str(content.get("removed", "")) + " " + str(content.get("remaining", "")).format({"left": left}), "good")
		RecoveryStyle.focus_loop(self)


func _on_final_switch_toggled(on: bool) -> void:
	if solved:
		return
	if on and _unknown_left() > 0:
		final_switch.set_pressed_no_signal(false)
		set_feedback(str(content.get("final_switch_locked", "")))
	elif on:
		succeed()


func _unknown_left() -> int:
	var left := 0
	for id: String in _sessions:
		if not _sessions[id].get("known", false) and not signed_out.has(id):
			left += 1
	return left


func _wobble(row: Control) -> void:
	row.pivot_offset = row.size / 2.0
	var tween := create_tween()
	for offset in [3.0, -3.0, 2.0, 0.0]:
		tween.tween_property(row, "position:x", row.position.x + offset, 0.04)
