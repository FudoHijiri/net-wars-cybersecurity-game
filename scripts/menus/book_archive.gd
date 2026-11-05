extends Control

@onready var content: Control = $Content
@onready var book_animation: AnimatedSprite2D = $Node2D/BookAnimation
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"
@onready var stage_select: Control = $"../StageSelect"
@onready var book_archive: Control = $"../BookArchive"
@onready var next_page_animation: AnimatedSprite2D = $Node2D/NextPageAnimation


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content.hide()
	book_animation.show()
	# The scene file is saved with the book open (the last frame). Start closed, like every visit after the first.
	book_animation.animation = &"default"
	book_animation.set_frame_and_progress(0, 0.0)
	next_page_animation.hide()

func _on_back_button_pressed() -> void:
	content.hide()
	book_animation.play_backwards("default")
	await book_animation.animation_finished
	stage_select.show()
	animation_player.play_backwards("book_archive_animation")
	await animation_player.animation_finished
	book_archive.hide()


func _on_credential_threat_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_malware_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_ransomware_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_insider_threat_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_data_exfiltration_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_d_do_s_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_phishing_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.


func _on_web_application_attack_toggled(toggled_on: bool) -> void:
	pass # Replace with function body.
