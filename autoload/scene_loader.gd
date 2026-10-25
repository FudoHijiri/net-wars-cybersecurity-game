extends Node

## Autoload (SceneManager). Changes scenes with a loading screen:
## `SceneManager.load_scene("res://...")` fades to black, loads the scene on a background
## thread, switches to it and fades back in. `load_finished` fires once the switch is made.

signal progress_changed(progress)
signal load_finished

var loading_screen: PackedScene = preload("uid://c5627tpl7bb7i")
var loaded_resource: PackedScene
var scene_path: String
var progress: Array = []
var use_sub_threads: bool = true
var is_loading: bool = false # a second request during a load is ignored


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # keeps loading while the game is paused
	set_process(false)


func load_scene(_scene_path: String) -> void:
	if is_loading:
		return
	if not ResourceLoader.exists(_scene_path):
		push_error("SceneManager: scene not found: %s" % _scene_path)
		return
	is_loading = true
	scene_path = _scene_path

	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)

	await new_load_screen.loading_screen_ready

	start_load()


## For things that cover the whole screen without changing scene (the settings): fades to black,
## calls `action` while the screen is black, then fades back in.
func fade_through(action: Callable) -> void:
	if is_loading:
		return
	is_loading = true
	var screen = loading_screen.instantiate()
	add_child(screen)
	await screen.loading_screen_ready
	action.call()
	screen._on_load_finished()
	await screen.tree_exited
	is_loading = false


func start_load() -> void:
	var state = ResourceLoader.load_threaded_request(scene_path, "", use_sub_threads)
	if state == OK:
		set_process(true)
	else:
		_finish_failed()


func _process(_delta: float) -> void:
	var load_status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	if not progress.is_empty():
		progress_changed.emit(progress[0])
	match load_status:
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, ResourceLoader.THREAD_LOAD_FAILED:
			_finish_failed()
		ResourceLoader.THREAD_LOAD_LOADED:
			set_process(false)
			loaded_resource = ResourceLoader.load_threaded_get(scene_path)
			get_tree().change_scene_to_packed(loaded_resource)
			is_loading = false
			load_finished.emit()


## Loading failed: stay on the current scene and take the loading screen away.
func _finish_failed() -> void:
	push_error("SceneManager: could not load %s" % scene_path)
	set_process(false)
	is_loading = false
	load_finished.emit()
