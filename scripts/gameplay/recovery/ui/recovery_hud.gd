class_name RecoveryHUD
extends CanvasLayer

## Layout and styling live in RecoveryHUD.tscn and recovery_theme.tres.
## This script only fills in text.

@export var day_format := "Day {day} / Recovery"

@onready var root: Control = $Root
@onready var header: PanelContainer = %Header
@onready var day_label: Label = %DayLabel
@onready var practice_badge: Label = %PracticeBadge
@onready var counter: Label = %Counter
@onready var pause_button: Button = %PauseButton
@onready var hint: Label = %InteractionHint


func set_day(day: Variant) -> void:
	day_label.text = day_format.format({"day": str(day)})


func set_practice(enabled: bool) -> void:
	practice_badge.visible = enabled


func set_counter(text: String) -> void:
	counter.text = text


func set_hint(text: String) -> void:
	hint.text = text


func _on_pause_pressed() -> void:
	PauseMenu.open()
