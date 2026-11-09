class_name RecoveryRequestCard
extends PanelContainer

## One account-recovery request to approve or reject. Layout: tasks/parts/RequestCard.tscn.

@onready var title_label: Label = %Title
@onready var details_label: Label = %Details
@onready var status_label: Label = %Status
@onready var approve_button: Button = %Approve
@onready var reject_button: Button = %Reject


func show_request(request: Dictionary) -> void:
	title_label.text = str(request.get("title", "Recovery request"))
	var lines: Array[String] = []
	for field: Array in [["Name", "name"], ["Staff no.", "staff"], ["Phone", "phone"], ["Sent from", "from"]]:
		lines.append("%s: %s" % [field[0], request.get(field[1], "-")])
	details_label.text = "\n".join(lines)


## state: "pending", "approved" or "rejected".
func set_state(state: String) -> void:
	status_label.text = {"approved": "[OK] APPROVED", "rejected": "[X] REJECTED"}.get(state, "[?] WAITING")
	status_label.theme_type_variation = &"RecoverySuccess" if state != "pending" else &"RecoveryWarning"
	approve_button.visible = state == "pending"
	reject_button.visible = state == "pending"


func bounce() -> void:
	pivot_offset = size / 2.0
	var tween := create_tween()
	for angle in [0.04, -0.04, 0.02, 0.0]:
		tween.tween_property(self, "rotation", angle, 0.05)
