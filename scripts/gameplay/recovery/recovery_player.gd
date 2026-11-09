class_name RecoveryPlayer
extends CharacterBody2D

@export var speed := 90.0
var movement_enabled := true
@export var sprite: AnimatedSprite2D
var _facing := "down"

func _ready() -> void:
	var keys := {
		"recovery_left": [KEY_A, KEY_LEFT], "recovery_right": [KEY_D, KEY_RIGHT],
		"recovery_up": [KEY_W, KEY_UP], "recovery_down": [KEY_S, KEY_DOWN],
	}
	for action: String in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	sprite.animation = _facing

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	if movement_enabled:
		direction = Input.get_vector("recovery_left", "recovery_right", "recovery_up", "recovery_down")
	velocity = direction * speed
	move_and_slide()
	if direction.is_zero_approx():
		sprite.stop()
		sprite.animation = _facing
		sprite.frame = 0
	else:
		if absf(direction.x) > absf(direction.y):
			_facing = "right" if direction.x > 0 else "left"
		else:
			_facing = "down" if direction.y > 0 else "up"
		sprite.play(_facing)

func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		if is_instance_valid(sprite):
			sprite.stop()
			sprite.frame = 0
