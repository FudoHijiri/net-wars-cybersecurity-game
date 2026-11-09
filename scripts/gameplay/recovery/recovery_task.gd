class_name RecoveryTask
extends Control

## Shared repair-screen frame. RecoveryTask.tscn holds the layout and styling: the screen of the
## machine the player opened, with its name and system in the title bar (content.machine from the room,
## content.system from the Day JSON).
## Each task scene inherits it and authors its own controls under Body and Footer;
## its script fills them with JSON content in setup_task() and restores their
## starting state in reset_state().

signal completed(component_id: String)
signal closed
@export var component_id: String = ""
@export_file("*.json") var data_path: String = RecoveryData.DEFAULT_PATH
## Title-bar icon per machine group (access, monitoring, servers, backup, network; "default" otherwise).
@export var group_icons: Dictionary = {}
var content: Dictionary = {}
var ui: Dictionary = {}
var runtime_outcome: Dictionary = {}
var practice_mode := false
var solved := false
## Wrong moves this attempt. Only lowers the clean bonus; never fails the task.
var mistakes := 0
## What this task leaves for later tasks (e.g. the passphrase the player built). Saved with the run
## when the task completes; later tasks read it from content.memory[component_id].
var report: Dictionary = {}

@onready var body: VBoxContainer = %Body
@onready var feedback: Label = %Feedback
@onready var back_button: Button = %BackButton
@onready var retry_button: Button = %RetryButton
@onready var _title: Label = %Title
@onready var _status: Label = %Status
@onready var _instruction: Label = %Instruction
@onready var _footer: HBoxContainer = %Footer
@onready var _machine: Label = %Machine
@onready var _system: Label = %System
@onready var _machine_icon: TextureRect = %MachineIcon
@onready var _stamp: Control = %Stamp
var _shake_tween: Tween
var _stamp_tween: Tween


func configure(task_content: Dictionary, task_ui: Dictionary, outcome: Dictionary = {}) -> void:
	content = task_content.duplicate(true)
	ui = task_ui
	runtime_outcome = outcome.duplicate(true)


func _ready() -> void:
	if content.is_empty():
		var data := RecoveryData.load_data(data_path)
		content = data.get("components", {}).get(component_id, {})
		ui = data.get("task_ui", {})
		runtime_outcome = RecoveryContext.sample_outcome()
		practice_mode = true
	_title.text = str(content.get("title", component_id))
	_instruction.text = str(content.get("instruction", ""))
	_show_machine()
	back_button.text = "Reset practice" if _standalone() else "Back"
	setup_task()
	reset_task()


func _show_machine() -> void:
	var machine: Dictionary = content.get("machine", {})
	_machine.text = str(machine.get("name", ui.get("machine_default", "Workstation"))).to_upper()
	var system := str(content.get("system", "")).to_upper()
	# Skip the system when it only repeats the machine's name (e.g. Network switch / NETWORK SWITCH).
	_system.text = "/ " + system if not system.is_empty() and system != _machine.text else ""
	var group := str(machine.get("group", content.get("group", "")))
	_machine_icon.texture = group_icons.get(group, group_icons.get("default"))


## Override: bind JSON content to the authored controls. Runs once.
func setup_task() -> void:
	pass


## Override: return the authored controls to their starting state.
func reset_state() -> void:
	pass


func reset_task() -> void:
	solved = false
	mistakes = 0
	report = {}
	_status.text = "Practice" if practice_mode else ""
	if _stamp_tween:
		_stamp_tween.kill()
	_stamp.hide()
	_status.theme_type_variation = &"RecoveryMuted"
	_set_buttons_disabled(body, false)
	_set_buttons_disabled(_footer, false)
	set_feedback(str(ui.get("hint", "")))
	reset_state()
	RecoveryStyle.focus_loop(self)


## kind: "hint" (what to do next), "good" (a right move) or "bad" (a mistake).
func set_feedback(text: String, kind := "hint") -> void:
	feedback.text = text
	feedback.theme_type_variation = {"good": &"FeedbackGood", "bad": &"FeedbackBad"}.get(kind, &"FeedbackHint")


## A wrong move: explain why and count it. The move itself is undone by the caller.
func note_mistake(reason: String) -> void:
	mistakes += 1
	set_feedback(reason, "bad")
	_shake()


func succeed() -> void:
	if solved or not RecoveryContext.is_cleared(runtime_outcome):
		return
	solved = true
	_status.text = "[OK] Complete"
	_status.theme_type_variation = &"RecoverySuccess"
	set_feedback(str(content.get("success", "")), "good")
	_show_stamp()
	_set_buttons_disabled(body, true)
	_set_buttons_disabled(_footer, true)
	back_button.disabled = false
	back_button.grab_focus()
	completed.emit(component_id)


func close_task() -> void:
	if _standalone():
		reset_task()
	else:
		closed.emit()


func _standalone() -> bool:
	return get_tree().current_scene == self


func _set_buttons_disabled(parent: Node, disabled: bool) -> void:
	for child in parent.get_children():
		if child is BaseButton:
			child.disabled = disabled
		_set_buttons_disabled(child, disabled)


## A small sideways shake of the screen when the player makes a mistake.
func _shake() -> void:
	if not is_inside_tree():
		return
	if _shake_tween:
		_shake_tween.kill()
	position.x = 0.0
	_shake_tween = create_tween()
	for x: float in [3.0, -3.0, 2.0, -1.0, 0.0]:
		_shake_tween.tween_property(self, "position:x", x, 0.04)


## The REPAIRED stamp pops in over the screen, then fades so the result stays readable.
func _show_stamp() -> void:
	if not is_inside_tree():
		return
	%StampLabel.text = str(ui.get("stamp", "REPAIRED"))
	var panel := %StampLabel.get_parent() as Control
	panel.pivot_offset = panel.get_combined_minimum_size() / 2.0
	panel.scale = Vector2(1.6, 1.6)
	panel.rotation = -0.06
	_stamp.modulate.a = 0.0
	_stamp.show()
	if _stamp_tween:
		_stamp_tween.kill()
	_stamp_tween = create_tween()
	_stamp_tween.tween_property(_stamp, "modulate:a", 1.0, 0.12)
	_stamp_tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_stamp_tween.tween_interval(1.0)
	_stamp_tween.tween_property(_stamp, "modulate:a", 0.0, 0.35)
	_stamp_tween.tween_callback(_stamp.hide)
