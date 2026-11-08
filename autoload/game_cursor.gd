extends CanvasLayer
## Autoload that draws the mouse cursor inside the game. The Windows cursor is not part of
## the picture of the game window, so screen sharing and recording often miss it. This one is
## drawn by the game, so every recorder sees it.

const CURSOR := preload("res://assets/ui/Cursor.png")

var _sprite := TextureRect.new()


func _ready() -> void:
	layer = 512 # above everything, the transitions and the debug panel included
	process_mode = Node.PROCESS_MODE_ALWAYS # keeps following the mouse while the game is paused
	_sprite.texture = CURSOR
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _process(_delta: float) -> void:
	_sprite.position = get_viewport().get_mouse_position().floor()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		_sprite.hide()
	elif what == NOTIFICATION_WM_MOUSE_ENTER:
		_sprite.show()
