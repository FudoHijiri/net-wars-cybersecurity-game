class_name RecoverySessionRow
extends PanelContainer

## One device signed in to an account. Layout: tasks/parts/SessionRow.tscn.

@onready var device_label: Label = %Device
@onready var place_label: Label = %Place
@onready var time_label: Label = %Time
@onready var status_label: Label = %Status
@onready var sign_out_button: Button = %SignOut


func show_session(session: Dictionary) -> void:
	device_label.text = str(session.get("device", ""))
	place_label.text = str(session.get("place", ""))
	time_label.text = str(session.get("time", ""))


## state: "active" or "signed_out".
func set_state(state: String, signed_out_text: String) -> void:
	var out := state == "signed_out"
	status_label.text = signed_out_text if out else ""
	status_label.visible = out
	sign_out_button.visible = not out
	device_label.theme_type_variation = &"RecoveryMuted" if out else &""
