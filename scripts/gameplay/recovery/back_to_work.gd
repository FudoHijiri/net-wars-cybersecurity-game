extends RecoveryTask

## Back to Work: the Day 1 Final Check, run on the file server. Layout: BackToWork.tscn.
## Anna's normal morning proves the repairs worked, one step at a time:
##   1. sign_in   - sign in with the password the player picked in the password task
##                  (content.memory.password.password, else content.default_password),
##   2. code      - type the 2-step code shown on her phone,
##   3. test_file - open the payroll report (files are ChoiceCards).
## A step whose outcome.verification flag is false fails with its reason and recovery stays open.

const STEPS := ["sign_in", "code", "test_file"]
## Which Response verification flag each step checks.
const FLAGS := {"sign_in": "sign_in", "code": "recovery_contact", "test_file": "test_file"}

var password := ""
var digit_buttons: Dictionary = {}
var file_buttons: Dictionary = {}
var entered_code := ""
var step := 0
var failed := false

@onready var sign_in_button: Button = %SignInButton
@onready var _stages: Array[Control] = [%SignInStage, %CodeStage, %FileStage]
@onready var _step_labels: Array[Label] = [%Step1, %Step2, %Step3]


func setup_task() -> void:
	var memory: Dictionary = content.get("memory", {})
	password = str(memory.get("password", {}).get("password", content.get("default_password", "")))
	%Account.text = str(content.get("account", "Account: Anna Reyes"))
	%PasswordField.text = str(content.get("password_label", "Password: {password}")).format({"password": "*".repeat(mini(password.length(), 24))})
	sign_in_button.text = str(content.get("sign_in", "Sign in"))
	%PhoneLabel.text = str(content.get("phone_label", "Anna's phone"))
	%PhoneCode.text = str(content.get("code", "0000"))
	for digit in %Keypad.get_children():
		var button := digit as Button
		button.pressed.connect(_enter_digit.bind(button.text))
		digit_buttons[button.text] = button
	var files: Array = content.get("files", [])
	var nodes := %Files.get_children()
	for i in nodes.size():
		var card := nodes[i] as RecoveryChoiceCard
		card.visible = i < files.size()
		if card.visible:
			var id := str(files[i]["id"])
			card.show_choice(id, str(files[i].get("label", id)), str(files[i].get("detail", "")))
			card.pressed.connect(_open_file.bind(id))
			file_buttons[id] = card
	for i in STEPS.size():
		_step_labels[i].set_meta("text", str(content.get("steps", {}).get(STEPS[i], STEPS[i])))


func reset_state() -> void:
	entered_code = ""
	failed = false
	for card: RecoveryChoiceCard in file_buttons.values():
		card.set_state("pending")
	%CodeEntry.text = _code_text()
	%FilePreview.text = str(content.get("file_hint", ""))
	%FilePreview.theme_type_variation = &"RecoveryMuted"
	_go_to(0)


func _go_to(index: int) -> void:
	step = index
	for i in _stages.size():
		_stages[i].visible = i == mini(index, _stages.size() - 1)
	for i in _step_labels.size():
		var mark := "[OK]" if i < index else ("[>]" if i == index else "[ ]")
		_step_labels[i].text = "%s %s" % [mark, _step_labels[i].get_meta("text", "")]
		_step_labels[i].theme_type_variation = &"RecoverySuccess" if i < index else (&"RecoveryWarning" if i == index else &"RecoveryMuted")
	if index < STEPS.size():
		set_feedback(str(content.get("prompts", {}).get(STEPS[index], "")))
	RecoveryStyle.focus_loop(self)


## Finishes the current step: passes it, or fails it when Response's verification says it cannot work.
func _complete_step() -> void:
	var id: String = STEPS[step]
	if runtime_outcome.get("verification", {}).get(FLAGS[id], false) != true:
		failed = true
		_step_labels[step].text = "[!] %s" % _step_labels[step].get_meta("text", "")
		_step_labels[step].theme_type_variation = &"RecoveryDanger"
		set_feedback(str(content.get("fails", {}).get(id, "")), "bad")
		return
	if step + 1 >= STEPS.size():
		_go_to(STEPS.size())
		succeed()
	else:
		_go_to(step + 1)


func _on_sign_in_pressed() -> void:
	if solved or failed or step != 0:
		return
	_complete_step()


func _enter_digit(digit: String) -> void:
	if solved or failed or step != 1:
		return
	var code := str(content.get("code", "0000"))
	if code[entered_code.length()] != digit:
		entered_code = ""
		%CodeEntry.text = _code_text()
		note_mistake(str(content.get("wrong_digit", "")))
		return
	entered_code += digit
	%CodeEntry.text = _code_text()
	if entered_code.length() >= code.length():
		_complete_step()


func _code_text() -> String:
	var code := str(content.get("code", "0000"))
	var shown := ""
	for i in code.length():
		shown += (entered_code[i] if i < entered_code.length() else "_") + " "
	return str(content.get("code_label", "Code: {entry}")).format({"entry": shown.strip_edges()})


func _open_file(id: String) -> void:
	if solved or failed or step != 2:
		return
	if id != str(content.get("test_file", "")):
		file_buttons[id].bounce()
		note_mistake(str(content.get("wrong_file", "")))
		return
	file_buttons[id].set_state("picked")
	%FilePreview.text = str(content.get("file_opened", ""))
	%FilePreview.theme_type_variation = &"RecoverySuccess"
	_complete_step()
