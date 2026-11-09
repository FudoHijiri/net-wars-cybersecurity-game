extends Node

## Autoload that keeps the player's progress in 3 save slots on disk.
##
## A slot is one encrypted file. Its bytes are: the tag "NWSV", a random IV, the encrypted JSON of the
## slot's data, and an HMAC over all of that. Loading checks the HMAC first, so a file that was edited
## by hand never gets decrypted. This detects casual edits only: the key is inside the game, so it does
## not stop someone who reads the scripts.
##
## The slot being played is `data`. Change it, then call save() at the end of a phase. The slot screen asks
## slot_info() for what to show, then new_game() or load_slot().
##
## JSON hands every number back as a float, so read counts from `data` with int().

enum Status {
	OK,
	RECOVERED, ## the slot failed its check, so the previous save (.bak) was loaded instead
	EMPTY, ## no save in the slot
	CORRUPT, ## not a save file, or cut short
	TAMPERED, ## the check failed: the file was edited, or damaged
	NEWER, ## saved by a newer version of the game
}

const SLOT_COUNT := 3
const DAY_COUNT := 8
const SAVE_VERSION := 1

const _GameState := preload("res://autoload/game_state.gd")
## Keys that saves made before the key existed do not have, and what such a save gets for them. A new game
## gets the value of _new_data() instead: for "tutorial" that is the difference between a new save and an old one.
const _OLD_SAVE_DEFAULTS := {"tutorial": [], "found_clues": [], "phase_findings": {}, "recovery_runs": {}}
const _TAG := "NWSV"
const _IV_SIZE := 16
const _MAC_SIZE := 32
const _BLOCK_SIZE := 16
const _SECRET := "NetWars/save/v1/3f9c1d7a5e24b8a06c71d2e9f4b58a13"

## Where the slots are written. A variable so a test can point it somewhere else.
var save_dir := "user://saves"

## What is in the slot being played. Empty until new_game() or load_slot() succeeds.
var data: Dictionary = {}
## The slot being played, or -1.
var current_slot := -1

var _crypto := Crypto.new()
var _enc_key := (_SECRET + "enc").sha256_buffer()
var _mac_key := (_SECRET + "mac").sha256_buffer()
var _loaded_at_msec := 0


## What the slot screen shows for one slot (0 to SLOT_COUNT - 1): {"slot", "status", "meta"}. The meta
## ("day", "phase", "playtime" in seconds, "saved_at" as unix time) is empty unless the slot can be loaded.
func slot_info(slot: int) -> Dictionary:
	var result := _read_slot(slot)
	var meta: Dictionary = {}
	if result["status"] == Status.OK or result["status"] == Status.RECOVERED:
		var saved_meta: Dictionary = result["data"]["meta"]
		meta = {
			"day": int(saved_meta["day"]),
			"phase": str(saved_meta["phase"]),
			"playtime": int(saved_meta["playtime"]),
			"saved_at": int(saved_meta["saved_at"]),
		}
	return {"slot": slot, "status": result["status"], "meta": meta}


func list_slots() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for slot in SLOT_COUNT:
		slots.append(slot_info(slot))
	return slots


## Starts a fresh game in a slot, replacing what was there (the old save stays as the slot's .bak).
func new_game(slot: int) -> bool:
	if not _is_valid_slot(slot):
		return false
	data = _new_data()
	current_slot = slot
	_loaded_at_msec = Time.get_ticks_msec()
	return save()


## Loads a slot into `data`. The status says what happened; only OK and RECOVERED leave a slot loaded.
func load_slot(slot: int) -> Status:
	if not _is_valid_slot(slot):
		return Status.EMPTY
	var result := _read_slot(slot)
	var status: Status = result["status"]
	if status == Status.OK or status == Status.RECOVERED:
		data = result["data"]
		current_slot = slot
		_loaded_at_msec = Time.get_ticks_msec()
	return status


## Writes `data` to the slot being played. Call it when a phase is over, so a quit mid-phase
## goes back to the start of that phase.
func save() -> bool:
	if current_slot < 0:
		push_error("SaveManager: save() with no slot loaded")
		return false
	var now := Time.get_ticks_msec()
	var meta: Dictionary = data["meta"]
	meta["playtime"] = float(meta["playtime"]) + (now - _loaded_at_msec) / 1000.0
	_loaded_at_msec = now
	var point := resume_point()
	meta["day"] = point["day"]
	meta["phase"] = point["phase"]
	meta["saved_at"] = int(Time.get_unix_time_from_system())
	return _write_slot(current_slot, data)


func delete_slot(slot: int) -> void:
	if not _is_valid_slot(slot):
		return
	for path in [_path(slot), _path(slot) + ".bak", _path(slot) + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	if slot == current_slot:
		current_slot = -1
		data = {}


## Notes that a phase was finished. It does not save: the caller pays out the phase, then calls save().
func complete_phase(day: int, phase: String) -> void:
	var completed: Dictionary = data["completed"]
	var phases: Array = completed.get(str(day), [])
	if not phases.has(phase):
		phases.append(phase)
	completed[str(day)] = phases


func is_phase_complete(day: int, phase: String) -> bool:
	var completed: Dictionary = data["completed"]
	var phases: Array = completed.get(str(day), [])
	return phases.has(phase)


## The first phase not finished yet, as {"day", "phase"}. Once everything is done: the last phase of the last day.
func resume_point() -> Dictionary:
	for day in range(1, DAY_COUNT + 1):
		for phase: String in _GameState.PHASES:
			if not is_phase_complete(day, phase):
				return {"day": day, "phase": phase}
	return {"day": DAY_COUNT, "phase": _GameState.PHASES[-1]}


## Everything a fresh slot holds. The shape of a loaded slot is checked against this.
func _new_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"meta": {"day": 1, "phase": _GameState.PHASES[0], "playtime": 0.0, "saved_at": 0},
		"completed": {}, # day number as text -> the phases finished that day
		"security_points": 0,
		"unlocked_passives": [],
		"equipped_passives": [],
		"owned_cards": [],
		"deck": [],
		"consumables": {},
		"found_clues": [], # ids of the Investigation clues the player found, kept when Investigation ends
		"phase_findings": {}, # day -> submitted Investigation/Monitoring context (Recovery briefing)
		"recovery_runs": {}, # day -> Response handoff and Recovery progress
		"tutorial": [ # the tutorials still to come: a phase, or a view inside it (see data/tutorials.json)
			"investigation", "investigation_report", "monitoring", "hardening",
			"hardening_shop", "hardening_deck_editor", "hardening_upgrade_editor", "response",
		],
	}


func _is_valid_slot(slot: int) -> bool:
	return slot >= 0 and slot < SLOT_COUNT


func _path(slot: int) -> String:
	return "%s/slot_%d.sav" % [save_dir, slot]


## {"status", "data"} of a slot: the file if it checks out, else the previous save.
func _read_slot(slot: int) -> Dictionary:
	var path := _path(slot)
	var main := _read_file(path)
	if main["status"] == Status.OK or main["status"] == Status.NEWER:
		return main # a newer save is never replaced by an older one
	var backup := _read_file(path + ".bak")
	if backup["status"] == Status.OK:
		backup["status"] = Status.RECOVERED
		return backup
	return main


func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": Status.EMPTY}
	return _decode(FileAccess.get_file_as_bytes(path))


func _write_slot(slot: int, save_data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(save_dir)
	var path := _path(slot)
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s (error %d)" % [temp, FileAccess.get_open_error()])
		return false
	file.store_buffer(_encode(save_data))
	file.flush()
	file.close()
	if FileAccess.file_exists(path):
		# Only a save that checks out becomes the backup, so a bad file never replaces a good .bak.
		if _read_file(path)["status"] == Status.OK:
			DirAccess.copy_absolute(path, path + ".bak")
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(temp, path) == OK


func _encode(save_data: Dictionary) -> PackedByteArray:
	var iv := _crypto.generate_random_bytes(_IV_SIZE)
	var cipher := _aes(AESContext.MODE_CBC_ENCRYPT, iv, _pad(JSON.stringify(save_data).to_utf8_buffer()))
	var bytes := _TAG.to_ascii_buffer()
	bytes.append_array(iv)
	bytes.append_array(cipher)
	bytes.append_array(_crypto.hmac_digest(HashingContext.HASH_SHA256, _mac_key, bytes))
	return bytes


## {"status", "data"}. The data is there only when the status is OK.
func _decode(bytes: PackedByteArray) -> Dictionary:
	var header_size := _TAG.length() + _IV_SIZE
	var cipher_size := bytes.size() - header_size - _MAC_SIZE
	if cipher_size <= 0 or cipher_size % _BLOCK_SIZE != 0 \
			or bytes.slice(0, _TAG.length()).get_string_from_ascii() != _TAG:
		return {"status": Status.CORRUPT}

	var signed_part := bytes.slice(0, bytes.size() - _MAC_SIZE)
	var expected := _crypto.hmac_digest(HashingContext.HASH_SHA256, _mac_key, signed_part)
	if not _crypto.constant_time_compare(expected, bytes.slice(bytes.size() - _MAC_SIZE)):
		return {"status": Status.TAMPERED}

	var iv := bytes.slice(_TAG.length(), header_size)
	var plain := _unpad(_aes(AESContext.MODE_CBC_DECRYPT, iv, bytes.slice(header_size, header_size + cipher_size)))
	var parsed: Variant = JSON.parse_string(plain.get_string_from_utf8())
	if not parsed is Dictionary or not parsed.has("version") or typeof(parsed["version"]) != TYPE_FLOAT:
		return {"status": Status.CORRUPT}
	if int(parsed["version"]) > SAVE_VERSION:
		return {"status": Status.NEWER}
	for key: String in _OLD_SAVE_DEFAULTS:
		if not parsed.has(key):
			parsed[key] = _OLD_SAVE_DEFAULTS[key].duplicate()
	if not _has_shape(parsed, _new_data()):
		return {"status": Status.CORRUPT}
	return {"status": Status.OK, "data": parsed}


## True when `loaded` has every key of `template` with the same kind of value. It checks the shape
## only, not the values: add range checks (no negative points, only known card ids) when those exist.
func _has_shape(loaded: Dictionary, template: Dictionary) -> bool:
	for key: String in template:
		if not loaded.has(key):
			return false
		var want := typeof(template[key])
		var got := typeof(loaded[key])
		var both_numbers := (want == TYPE_INT or want == TYPE_FLOAT) and (got == TYPE_INT or got == TYPE_FLOAT)
		if want != got and not both_numbers:
			return false
		if want == TYPE_DICTIONARY and template[key].size() > 0 and not _has_shape(loaded[key], template[key]):
			return false
	return true


func _aes(mode: AESContext.Mode, iv: PackedByteArray, input: PackedByteArray) -> PackedByteArray:
	var aes := AESContext.new()
	aes.start(mode, _enc_key, iv)
	var output := aes.update(input)
	aes.finish()
	return output


## PKCS7: fills the last block with the number of bytes added.
func _pad(bytes: PackedByteArray) -> PackedByteArray:
	var count := _BLOCK_SIZE - bytes.size() % _BLOCK_SIZE
	var padded := bytes.duplicate()
	for i in count:
		padded.append(count)
	return padded


func _unpad(bytes: PackedByteArray) -> PackedByteArray:
	if bytes.is_empty():
		return bytes
	var count := bytes[bytes.size() - 1]
	if count < 1 or count > _BLOCK_SIZE or count > bytes.size():
		return PackedByteArray()
	return bytes.slice(0, bytes.size() - count)
