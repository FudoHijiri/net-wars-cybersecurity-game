extends Node

## Autoload (Music): the looping music. The tracks and which scene starts which one are in data/music.json.
##
##   Music.play(&"hope")          change the music (a crossfade); nothing happens when it already plays
##   Music.stop()                 fade out
##   Music.set_intensity(0.5)     for a track in stages (the Response fight): 0..1, moves to the next stage at each
##                                threshold of the track and keeps the place in the loop, so only an instrument is added
##   Music.current()              the name of the track that plays
##
## A scene opened from the "scenes" list of music.json starts its track by itself (the autoload watches the scene
## changes). A script calls play() only to change it, e.g. the day select inside the title scene.
## Every track loops. The music is quieter, and muffled, while the game is paused. Played on the Music bus.

const DATA_PATH := "res://data/music.json"
const FOLDER := "res://assets/audio/music/"
const SILENT := -60.0 # dB; at or under this a fading track is stopped
const MUFFLED_CUTOFF := 1400.0 # Hz, the low-pass filter while the game is paused

class Slot:
	var player: AudioStreamPlayer
	var level := SILENT # dB, the fade
	var target := SILENT
	var speed := 60.0 # dB per second
	var gain := 0.0 # dB of the track on it (measured, so every track is equally loud)

var _tracks: Dictionary = {}
var _scenes: Dictionary = {}
var _fade := 1.0
var _paused_db := -9.0
var _slots: Array[Slot] = []
var _live: Slot # the slot that plays the current track
var _key: StringName = &""
var _stage := 0
var _gain := 0.0 # the dB of the current track
var _duck := 0.0 # dB, lower while paused
var _filter := -1 # index of the low-pass filter on the Music bus


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # the fades and the muffling go on while the game is paused
	_load()
	var bus: StringName = &"Music" if AudioServer.get_bus_index(&"Music") != -1 else &"Master"
	for i in 2:
		var slot := Slot.new()
		slot.player = AudioStreamPlayer.new()
		slot.player.bus = bus
		slot.player.volume_db = SILENT
		add_child(slot.player)
		_slots.append(slot)
	var bus_index := AudioServer.get_bus_index(bus)
	var filter := AudioEffectLowPassFilter.new()
	filter.cutoff_hz = MUFFLED_CUTOFF
	AudioServer.add_bus_effect(bus_index, filter)
	_filter = AudioServer.get_bus_effect_count(bus_index) - 1
	AudioServer.set_bus_effect_enabled(bus_index, _filter, false)
	get_tree().node_added.connect(_on_node_added)


func _load() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("Music: cannot read %s" % DATA_PATH)
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return
	_fade = float(data.get("fade", 1.0))
	_paused_db = float(data.get("paused_db", -9.0))
	_scenes = data.get("scenes", {})
	_tracks = data.get("tracks", {})


func current() -> StringName:
	return _key


## The stage of the current track (0 for a track without stages).
func stage() -> int:
	return _stage


func has_track(key: StringName) -> bool:
	return _tracks.has(String(key))


## Changes the music to the track `key` with a crossfade. The same track again is left alone. An unknown name
## fades the music out.
func play(key: StringName, fade: float = -1.0) -> void:
	if key == _key and _live != null and _live.target > SILENT:
		return
	var info: Dictionary = _tracks.get(String(key), {})
	if info.is_empty():
		stop(fade)
		return
	_key = key
	_stage = 0
	_gain = float(info.get("volume", 0.0))
	_start(_stream_of(info, 0), 0.0, fade if fade >= 0.0 else _fade, _gain)


func stop(fade: float = -1.0) -> void:
	_key = &""
	_stage = 0
	_release_all(fade if fade >= 0.0 else _fade)
	_live = null


## For a track in stages: 0 (calm) to 1 (the most intense). The stage is the number of thresholds of the track
## that `amount` has reached. The new stage starts at the place of the old one, so the tune goes on.
func set_intensity(amount: float) -> void:
	var info: Dictionary = _tracks.get(String(_key), {})
	var files: Array = info.get("files", [])
	if files.size() < 2 or _live == null:
		return
	var new_stage := 0
	for threshold in info.get("thresholds", []):
		if amount >= float(threshold):
			new_stage += 1
	new_stage = mini(new_stage, files.size() - 1)
	if new_stage == _stage:
		return
	_stage = new_stage
	var position := _live.player.get_playback_position() + AudioServer.get_time_since_last_mix()
	_start(_stream_of(info, new_stage), position, minf(_fade, 0.5), _gain)


func _stream_of(info: Dictionary, index: int) -> AudioStream:
	var files: Array = info.get("files", [])
	if index >= files.size():
		return null
	var stream := load(FOLDER + str(files[index])) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


## The new stream fades in on the free slot while the others fade out.
func _start(stream: AudioStream, from: float, fade: float, gain: float) -> void:
	if stream == null:
		return
	_release_all(fade)
	var slot := _free_slot()
	slot.player.stream = stream
	slot.player.volume_db = SILENT
	slot.level = SILENT
	slot.target = 0.0
	slot.gain = gain
	slot.speed = absf(SILENT) / maxf(fade, 0.01)
	slot.player.play(from)
	_live = slot


func _release_all(fade: float) -> void:
	for slot in _slots:
		if slot.player.playing:
			slot.target = SILENT
			slot.speed = absf(SILENT) / maxf(fade, 0.01)


func _free_slot() -> Slot:
	for slot in _slots:
		if not slot.player.playing:
			return slot
	for slot in _slots: # both busy: take the one that is fading out
		if slot != _live:
			return slot
	return _slots[0]


func _process(delta: float) -> void:
	var paused := get_tree().paused
	_duck = move_toward(_duck, _paused_db if paused else 0.0, 40.0 * delta)
	if _filter != -1:
		var bus_index := AudioServer.get_bus_index(_slots[0].player.bus)
		var want := paused
		if AudioServer.is_bus_effect_enabled(bus_index, _filter) != want:
			AudioServer.set_bus_effect_enabled(bus_index, _filter, want)
	for slot in _slots:
		if not slot.player.playing:
			continue
		slot.level = move_toward(slot.level, slot.target, slot.speed * delta)
		if slot.target <= SILENT and slot.level <= SILENT:
			slot.player.stop()
			continue
		slot.player.volume_db = slot.level + slot.gain + _duck


# --- the scenes start their own music ---

func _on_node_added(node: Node) -> void:
	if node.get_parent() != get_tree().root or node.scene_file_path.is_empty():
		return
	var key: String = _scenes.get(node.scene_file_path, "")
	if not key.is_empty():
		play(StringName(key))
