extends RecoveryTask

## Give Anna her account back (the sign-in system). Layout: ResetPassword.tscn.
##   1. %IdentityStage: an HR record and RequestCards (content.identity). Approve the real person,
##      reject the thief. Skipped when the JSON has no identity block.
##   2. %PasswordStage: ChoiceCards (content.choices). Weak ones carry a "reason" and get crossed out
##      when picked; the one with "strong": true becomes the new password.
##   3. %FinalSwitch (content.final_switch, e.g. lock after 5 wrong tries) finishes the task.
## On success, report.password holds the chosen password, which Back to Work signs in with.

var request_cards: Dictionary = {}
var decided: Dictionary = {}
var choice_cards: Dictionary = {}
var chosen := ""
var _requests: Dictionary = {}
var _choices: Dictionary = {}

@onready var final_switch: CheckButton = %FinalSwitch
@onready var _identity_stage: Control = %IdentityStage
@onready var _password_stage: Control = %PasswordStage


func setup_task() -> void:
	final_switch.text = str(content.get("final_switch", "Turn on protection"))
	%ChoicePrompt.text = str(content.get("choice_label", "New password:"))
	var identity: Dictionary = content.get("identity", {})
	%HRRecord.text = str(identity.get("record", ""))
	var requests: Array = identity.get("requests", [])
	var cards := %Requests.get_children()
	for i in cards.size():
		var card := cards[i] as RecoveryRequestCard
		card.visible = i < requests.size()
		if not card.visible:
			continue
		var id := str(requests[i].get("id", i))
		card.show_request(requests[i])
		card.approve_button.pressed.connect(_decide.bind(id, true))
		card.reject_button.pressed.connect(_decide.bind(id, false))
		request_cards[id] = card
		_requests[id] = requests[i]
	var choices: Array = content.get("choices", [])
	var nodes := %Choices.get_children()
	for i in nodes.size():
		var card := nodes[i] as RecoveryChoiceCard
		card.visible = i < choices.size()
		if not card.visible:
			continue
		var id := str(choices[i].get("id", i))
		card.show_choice(id, str(choices[i].get("password", "")), str(choices[i].get("detail", "")))
		card.pressed.connect(_choose.bind(id))
		choice_cards[id] = card
		_choices[id] = choices[i]
	if choice_cards.size() < choices.size():
		push_warning("ResetPassword.tscn has fewer choice cards than the JSON lists.")


func reset_state() -> void:
	chosen = ""
	final_switch.set_pressed_no_signal(false)
	decided.clear()
	for id: String in request_cards:
		request_cards[id].set_state("pending")
	for id: String in choice_cards:
		choice_cards[id].set_state("pending")
	_show_password_stage(request_cards.is_empty())


func identity_checked() -> bool:
	return decided.size() >= request_cards.size()


func _show_password_stage(show: bool) -> void:
	_identity_stage.visible = not show
	_password_stage.visible = show
	final_switch.visible = show and not chosen.is_empty()
	set_feedback(str(content.get("choice_prompt" if show else "identity_prompt", "")))


## Approve or reject one recovery request. Only the real Anna may be approved.
func _decide(id: String, approve: bool) -> void:
	if solved or decided.has(id):
		return
	var request: Dictionary = _requests[id]
	if approve != bool(request.get("genuine", false)):
		request_cards[id].bounce()
		note_mistake(str(request.get("wrong", "")))
		return
	decided[id] = approve
	request_cards[id].set_state("approved" if approve else "rejected")
	if identity_checked():
		_show_password_stage(true)
		set_feedback(str(content.get("identity_done", content.get("choice_prompt", ""))), "good")
	else:
		set_feedback(str(request.get("right", "")), "good")
	RecoveryStyle.focus_loop(self)


## Pick one password card. Weak ones are crossed out with the reason; the strong one is kept.
func _choose(id: String) -> void:
	if solved or not chosen.is_empty():
		return
	var choice: Dictionary = _choices[id]
	var card: RecoveryChoiceCard = choice_cards[id]
	if not choice.get("strong", false):
		card.bounce()
		card.set_state("wrong", str(choice.get("short", "")))
		note_mistake(str(choice.get("reason", "")))
		RecoveryStyle.focus_loop(self)
		return
	chosen = str(choice.get("password", ""))
	card.set_state("picked", str(choice.get("short", "")))
	for other: String in choice_cards:
		choice_cards[other].disabled = true
	final_switch.show()
	final_switch.grab_focus()
	set_feedback(str(content.get("full", "")), "good")


func _on_final_switch_toggled(on: bool) -> void:
	if solved:
		return
	if on and chosen.is_empty():
		final_switch.set_pressed_no_signal(false)
		set_feedback(str(content.get("final_switch_locked", "")))
	elif on:
		report = {"password": chosen}
		succeed()
