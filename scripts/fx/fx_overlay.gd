extends CanvasLayer
## Autoload "Fx": a layer above the game (below the scene fade and the debug panel) that holds the shared
## pixel effects and the floating things of UiFx (numbers, icons in flight, badges). It never takes the mouse.

var pixels: PixelFx


func _ready() -> void:
	layer = 120 # SceneTransitions is 150, the colorblind filter and the debug panel are above
	pixels = PixelFx.new()
	pixels.name = "Pixels"
	add_child(pixels)
