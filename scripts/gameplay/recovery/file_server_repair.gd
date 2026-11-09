extends RecoveryTask

## Legacy component ID retained; this is now the final access-verification lesson.
## Layout: FileServerRepair.tscn. Each CheckCard under %Cards is filled in order
## from the JSON checks; the "recovery_contact" check uses the Match/Different row.

var results: Dictionary = {}
var check_buttons: Dictionary = {}
var status_labels: Dictionary = {}
var mismatch_button: Button
var _cards: Dictionary = {}

@onready var test_button: Button = %TestButton
@onready var _card_row: HBoxContainer = %Cards


func setup_task() -> void:
	var checks: Array = content.get("checks", [])
	var cards := _card_row.get_children()
	for i in cards.size():
		var card := cards[i] as RecoveryCheckCard
		card.visible = i < checks.size()
		if not card.visible:
			continue
		var check_data: Dictionary = checks[i]
		var id := str(check_data["id"])
		_cards[id] = card
		card.art.mode = str(check_data.get("icon", "file"))
		card.name_label.text = str(check_data["label"])
		var expected_text := str(check_data["expected"])
		if id == "recovery_contact":
			expected_text = str(check_data.get("comparison", "")).format({"observed": _observed_contact(check_data)})
		card.expected_label.text = expected_text
		card.use_comparison(id == "recovery_contact")
		status_labels[id] = card.status_label
		if id == "recovery_contact":
			card.match_button.text = str(content.get("matches", "Match"))
			card.different_button.text = str(content.get("differs", "Different"))
			card.match_button.pressed.connect(_compare_contact.bind(true))
			card.different_button.pressed.connect(_compare_contact.bind(false))
			check_buttons[id] = card.match_button
			mismatch_button = card.different_button
		else:
			card.run_button.text = str(content.get("run", "Run check"))
			card.run_button.pressed.connect(_run_check.bind(id))
			check_buttons[id] = card.run_button
	if _cards.size() < checks.size():
		push_warning("FileServerRepair.tscn has fewer check cards than the JSON lists.")


func reset_state() -> void:
	results.clear()
	for card: RecoveryCheckCard in _cards.values():
		card.set_state("unchecked")


func _observed_contact(check_data: Dictionary) -> String:
	var supplied: Dictionary = runtime_outcome.get("verification_details", {})
	if supplied.has("recovery_contact"):
		return str(supplied["recovery_contact"])
	if runtime_outcome.get("verification", {}).get("recovery_contact", false) == true:
		return str(check_data.get("trusted_contact", ""))
	return str(check_data.get("untrusted_contact", ""))


func _compare_contact(player_says_match: bool) -> void:
	if solved:
		return
	for check_data: Dictionary in content.get("checks", []):
		if str(check_data["id"]) != "recovery_contact":
			continue
		var matches := _observed_contact(check_data) == str(check_data.get("trusted_contact", ""))
		if player_says_match != matches:
			results["recovery_contact"] = false
			_cards["recovery_contact"].set_state("retry")
			set_feedback(str(content.get("compare_again", "")))
			return
		# Recognizing a mismatch is correct reasoning, but still leaves recovery open.
		_run_check("recovery_contact", matches)


func _run_check(id: String, details_match: bool = true) -> void:
	if solved:
		return
	var passed: bool = details_match and runtime_outcome.get("verification", {}).get(id, false) == true
	results[id] = passed
	_cards[id].set_state("passed" if passed else "failed")
	for check_data: Dictionary in content.get("checks", []):
		if str(check_data["id"]) == id:
			var text := str(check_data.get("passed" if passed else "failed", ""))
			set_feedback(str(content.get("passed" if passed else "failed_result", "")).format({"result": text}))


func _confirm_results() -> void:
	if results.size() != check_buttons.size() or check_buttons.is_empty():
		set_feedback(str(content.get("all_checks", "")))
		return
	for passed: bool in results.values():
		if not passed:
			set_feedback(str(content.get("failed", "")))
			return
	succeed()
