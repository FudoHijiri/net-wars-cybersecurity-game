class_name SaveSelect
extends Control

## The save slot screen, reached with Play on the title menu. It shows the slots of SaveManager: an empty
## slot starts a new game, a slot with progress is continued, and the small DELETE button of a slot asks
## before erasing it. A slot whose file failed the integrity check is not loaded; the screen says why
## and leaves the file alone.
##
## The title menu owns the slide animations, so this screen only reports what the player chose.

## A slot is ready to play: it was created or loaded into SaveManager. The title menu slides to the day select.
signal slot_chosen(slot: int)
## The Exit button was pressed. The title menu slides back to the title.
signal exit_requested

@onready var _slot_list: VBoxContainer = $NinePatchRect/VBoxContainer
@onready var _message: Label = $NinePatchRect/MessageLabel
@onready var _exit_button: TextureButton = $NinePatchRect/Exit
@onready var _confirm: Control = $ConfirmDelete
@onready var _confirm_label: Label = $ConfirmDelete/Panel/Label
@onready var _yes_button: Button = $ConfirmDelete/Panel/YesButton
@onready var _no_button: Button = $ConfirmDelete/Panel/NoButton

var _busy := false # a slot was chosen and the screen is sliding away
var _delete_slot := -1 # the slot the confirmation is about


func _ready() -> void:
	for slot in SaveManager.SLOT_COUNT:
		var button: Button = _slot_list.get_child(slot)
		button.pressed.connect(_on_slot_pressed.bind(slot))
		button.get_node("DeleteButton").pressed.connect(_on_delete_pressed.bind(slot))
	_exit_button.pressed.connect(_on_exit_pressed)
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)
	visibility_changed.connect(_on_visibility_changed)
	_confirm.hide()
	refresh()


## Reads the slots again and rewrites the buttons.
func refresh() -> void:
	for info in SaveManager.list_slots():
		var button: Button = _slot_list.get_child(info["slot"])
		button.text = _slot_text(info)
		button.get_node("DeleteButton").visible = info["status"] != SaveManager.Status.EMPTY


## Called by the title menu once the slide to the day select is over, so the slots work again
## when the player comes back.
func unlock() -> void:
	_busy = false


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	_message.text = ""
	_confirm.hide()
	refresh()


func _on_slot_pressed(slot: int) -> void:
	if _busy:
		return
	_message.text = ""
	var status: SaveManager.Status = SaveManager.slot_info(slot)["status"]
	if status == SaveManager.Status.EMPTY:
		if SaveManager.new_game(slot):
			_enter(slot)
		else:
			_message.text = "COULD NOT WRITE THE SAVE FILE. IS THE DISK FULL OR READ-ONLY?"
		refresh()
		return
	# Load it even when the info above said it was fine: loading is what checks the file.
	status = SaveManager.load_slot(slot)
	if status == SaveManager.Status.OK or status == SaveManager.Status.RECOVERED:
		_enter(slot)
	else:
		_message.text = _failure_text(slot, status)
		refresh()


## The slot is in SaveManager; start the day select from a clean run.
func _enter(slot: int) -> void:
	GameState.reset_progress()
	_busy = true
	slot_chosen.emit(slot)


func _on_exit_pressed() -> void:
	if not _busy:
		exit_requested.emit()


func _on_delete_pressed(slot: int) -> void:
	if _busy:
		return
	_delete_slot = slot
	_confirm_label.text = "DELETE SLOT %d? ALL ITS PROGRESS WILL BE LOST." % (slot + 1)
	_confirm.show()
	_no_button.grab_focus() # the safe answer is the one under the keyboard


func _on_yes_pressed() -> void:
	SaveManager.delete_slot(_delete_slot)
	_message.text = "SLOT %d DELETED." % (_delete_slot + 1)
	_confirm.hide()
	refresh()


func _on_no_pressed() -> void:
	_confirm.hide()


func _slot_text(info: Dictionary) -> String:
	var head := "SLOT %d" % (int(info["slot"]) + 1)
	var status: SaveManager.Status = info["status"]
	match status:
		SaveManager.Status.EMPTY:
			return "%s - EMPTY\nSTART A NEW GAME" % head
		SaveManager.Status.OK, SaveManager.Status.RECOVERED:
			var meta: Dictionary = info["meta"]
			var progress := "%s - DAY %d %s" % [head, meta["day"], str(meta["phase"]).to_upper()]
			var played := _format_playtime(meta["playtime"])
			if status == SaveManager.Status.RECOVERED:
				return "%s\nRESTORED FROM BACKUP - %s" % [progress, played]
			return "%s\n%s PLAYED - %s" % [progress, played, _format_saved_at(meta["saved_at"])]
		SaveManager.Status.TAMPERED:
			return "%s - CANNOT BE LOADED\nFAILED THE INTEGRITY CHECK" % head
		SaveManager.Status.NEWER:
			return "%s - CANNOT BE LOADED\nSAVED BY A NEWER VERSION" % head
	return "%s - CANNOT BE LOADED\nTHE FILE IS UNREADABLE" % head


func _failure_text(slot: int, status: SaveManager.Status) -> String:
	var head := "SLOT %d" % (slot + 1)
	match status:
		SaveManager.Status.TAMPERED:
			return "%s FAILED THE INTEGRITY CHECK: THE FILE WAS EDITED OR DAMAGED. IT WAS NOT LOADED. DELETE IT TO START OVER." % head
		SaveManager.Status.NEWER:
			return "%s WAS SAVED BY A NEWER VERSION OF THE GAME. UPDATE THE GAME TO PLAY IT." % head
		SaveManager.Status.EMPTY:
			return "%s HAS NO SAVE ANY MORE." % head
	return "%s IS NOT A READABLE SAVE FILE. DELETE IT TO START OVER." % head


func _format_playtime(seconds: int) -> String:
	return "%dH %02dM" % [floori(seconds / 3600.0), floori((seconds % 3600) / 60.0)]


## Local time as "2026-11-03 14:20".
func _format_saved_at(unix: int) -> String:
	var local := unix + int(Time.get_time_zone_from_system()["bias"]) * 60
	return Time.get_datetime_string_from_unix_time(local, true).left(16)
