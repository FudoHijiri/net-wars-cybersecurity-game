class_name RecoveryHUD
extends CanvasLayer

## Layout and styling live in RecoveryHUD.tscn and recovery_theme.tres.
## This script only fills in text.

@onready var root: Control = $Root
@onready var header: PanelContainer = %Header
@onready var practice_badge: Label = %PracticeBadge
@onready var objective: Label = %Objective
@onready var counter: Label = %Counter
@onready var pause_button: TextureButton = %PauseButton
@onready var hint: Label = %InteractionHint


## The objective line of the phase (GameState.objective()): what the player is here to do.
func set_objective(text: String) -> void:
	objective.text = text


func set_practice(enabled: bool) -> void:
	practice_badge.visible = enabled


func set_counter(text: String) -> void:
	counter.text = text


func set_hint(text: String) -> void:
	hint.text = text


func _on_pause_pressed() -> void:
	PauseMenu.open()
