extends RecoveryTask

## Layout: BackupRepair.tscn. Each CartridgeCard under %Choices is filled in
## order from the JSON backups.

var selected_backup := ""
var verified_backup := ""
var backup_buttons: Dictionary = {}
var _arts: Dictionary = {}

@onready var details: Label = %Details
@onready var test_button: Button = %TestButton
@onready var restore_button: Button = %RestoreButton
@onready var _choices: HBoxContainer = %Choices


func setup_task() -> void:
	var backups: Array = content.get("backups", [])
	var group := ButtonGroup.new()
	var cards := _choices.get_children()
	for i in cards.size():
		var card := cards[i] as RecoveryCartridgeCard
		card.visible = i < backups.size()
		if not card.visible:
			continue
		var id := str(backups[i]["id"])
		card.select_button.text = str(backups[i]["label"])
		card.select_button.button_group = group
		card.select_button.pressed.connect(_select_backup.bind(id))
		backup_buttons[id] = card.select_button
		_arts[id] = card.art
	if backup_buttons.size() < backups.size():
		push_warning("BackupRepair.tscn has fewer cartridge cards than the JSON lists.")


func reset_state() -> void:
	selected_backup = ""
	verified_backup = ""
	for button: Button in backup_buttons.values():
		button.set_pressed_no_signal(false)
	for art: RecoveryMachineArt in _arts.values():
		art.checked = false
	details.text = str(content.get("choose", ""))


func _select_backup(id: String) -> void:
	if solved:
		return
	selected_backup = id
	verified_backup = ""
	for art: RecoveryMachineArt in _arts.values():
		art.checked = false
	details.text = str(_selected_data().get("detail", ""))
	set_feedback(str(content.get("choose", "")))


func _selected_data() -> Dictionary:
	for backup: Dictionary in content.get("backups", []):
		if backup.get("id", "") == selected_backup:
			return backup
	return {}


func _test_backup() -> void:
	verified_backup = ""
	var backup := _selected_data()
	if backup.is_empty():
		set_feedback(str(content.get("select_first", "")))
	elif not backup.get("complete", false):
		set_feedback(str(content.get("incomplete", "")))
	elif not backup.get("checked", false):
		set_feedback(str(content.get("too_recent" if not backup.get("before_incident", false) else "unchecked", "")))
	elif not backup.get("before_incident", false):
		set_feedback(str(content.get("too_recent", "")))
	else:
		verified_backup = selected_backup
		_arts[selected_backup].checked = true
		set_feedback(str(content.get("tested", "")))
		restore_button.grab_focus()


func _restore_database() -> void:
	if selected_backup.is_empty() or verified_backup != selected_backup:
		set_feedback(str(content.get("test_first", "")))
		return
	succeed()
