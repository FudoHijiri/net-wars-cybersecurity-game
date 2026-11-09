class_name RecoveryCheckCard
extends VBoxContainer

## One access check. Layout: tasks/parts/CheckCard.tscn.
## A plain check uses RunButton; a comparison check uses the Match/Different row.

@onready var art: RecoveryMachineArt = $Art
@onready var name_label: Label = $NameLabel
@onready var expected_label: Label = $ExpectedLabel
@onready var status_label: Label = $StatusLabel
@onready var run_button: Button = $RunButton
@onready var compare_row: HBoxContainer = $CompareRow
@onready var match_button: Button = $CompareRow/MatchButton
@onready var different_button: Button = $CompareRow/DifferentButton


func use_comparison(enabled: bool) -> void:
	run_button.visible = not enabled
	compare_row.visible = enabled


## state: "unchecked", "passed", "failed" or "retry".
func set_state(state: String) -> void:
	match state:
		"passed":
			status_label.text = "[OK] PASS"
			status_label.theme_type_variation = &"RecoverySuccess"
		"failed":
			status_label.text = "[!] NEEDS HELP"
			status_label.theme_type_variation = &"RecoveryWarning"
		"retry":
			status_label.text = "[!] COMPARE AGAIN"
			status_label.theme_type_variation = &"RecoveryWarning"
		_:
			status_label.text = "[?] NOT CHECKED"
			status_label.theme_type_variation = &"RecoveryWarning"
	art.checked = state == "passed"
