class_name ReportPanel
extends Control

## The clue board: lists the marked evidence, lets the player pick a threat and confirm.
## A wrong or early confirm only shows a message. A correct one shows the result page and
## then the phase transition card. Call open() to show it, close() to hide it.

const TRANSITION_SCENE := preload("res://AI generated/scenes/transition/PhaseTransition.tscn")
const FONT_BODY := preload("res://assets/font/m3x6.ttf")
const FONT_BOLD := preload("res://assets/font/Minecraft Standard 6px/MinecraftStandardBold.otf")

const COLOR_DARK := Color("1a1c2c")
const COLOR_NAVY := Color("29366f")
const COLOR_LIGHT := Color("94b0c2")
const COLOR_WHITE := Color("f4f4f4")

var _data: Dictionary = {}
var _picked := ""
var _group := ButtonGroup.new()
var _threat_buttons: Array[Button] = []

@onready var _title_label: Label = %TitleLabel
@onready var _close_button: Button = %CloseButton
@onready var _board_page: Control = %BoardPage
@onready var _evidence_title: Label = %EvidenceTitle
@onready var _evidence_list: VBoxContainer = %EvidenceList
@onready var _threat_list: VBoxContainer = %ThreatList
@onready var _message_bar: PanelContainer = %MessageBar
@onready var _message_icon: Label = %MessageIcon
@onready var _message_text: Label = %MessageText
@onready var _back_button: Button = %BackButton
@onready var _confirm_button: Button = %ConfirmButton
@onready var _result_page: Control = %ResultPage
@onready var _result_evidence_title: Label = %ResultEvidenceTitle
@onready var _result_evidence_list: VBoxContainer = %ResultEvidenceList
@onready var _result_headline: Label = %ResultHeadline
@onready var _result_threat: Label = %ResultThreat
@onready var _what_happened_text: Label = %WhatHappenedText
@onready var _what_is_title: Label = %WhatIsTitle
@onready var _what_is_text: Label = %WhatIsText
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	_close_button.pressed.connect(close)
	_back_button.pressed.connect(close)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	if get_tree().current_scene == self: # run on its own (F6): open straight away
		open()


## Refreshes the evidence list, clears the pick and shows the board.
func open() -> void:
	if _data.is_empty():
		_data = ReportLogic.load_report_data()
		_build_threat_buttons()
	_picked = ""
	for button in _threat_buttons:
		button.set_pressed_no_signal(false)
	_refresh_threats()
	_refresh_confirm()
	_fill_evidence(_evidence_list, ReportLogic.get_marked_evidence(), _data.get("required_clues", 0))
	_evidence_title.text = "EVIDENCE COLLECTED (%d)" % ReportLogic.marked_ids().size()
	_title_label.text = "REPORT.exe  >  CLUE BOARD"
	_board_page.show()
	_result_page.hide()
	_show_message("pick")
	show()
	_back_button.grab_focus() # keyboard focus starts inside the panel, on a neutral button


func close() -> void:
	hide()


func _build_threat_buttons() -> void:
	for threat: String in _data.get("threats", []):
		var button := Button.new()
		button.theme_type_variation = &"ThreatButton"
		button.toggle_mode = true
		button.button_group = _group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(0, 14)
		button.set_meta(&"threat", threat)
		button.add_child(_make_pick_tag())
		button.toggled.connect(_on_threat_toggled)
		_threat_list.add_child(button)
		_threat_buttons.append(button)


func _make_pick_tag() -> Label:
	var tag := Label.new()
	tag.name = "PickTag"
	tag.text = "YOUR PICK"
	tag.visible = false
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE # decorative: clicks go to the button
	tag.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	tag.offset_left = -46.0
	tag.offset_right = -3.0
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color", COLOR_DARK)
	tag.add_theme_stylebox_override("normal", _make_style(COLOR_WHITE, Color.TRANSPARENT, 0, 1))
	return tag


func _refresh_threats() -> void:
	for button in _threat_buttons:
		var threat: String = button.get_meta(&"threat")
		button.text = ("> %s" if button.button_pressed else "[ ] %s") % threat.to_upper()
		button.get_node("PickTag").visible = button.button_pressed


func _refresh_confirm() -> void:
	var has_pick := not _picked.is_empty()
	_confirm_button.disabled = not has_pick
	_confirm_button.text = "CONFIRM REPORT" if has_pick else "CONFIRM REPORT (pick a threat)"


## Evidence rows for the marked entries, padded with empty slots up to `min_rows`.
func _fill_evidence(list: VBoxContainer, evidence: Array[Dictionary], min_rows: int) -> void:
	PhaseTransition.clear_children(list)
	for item in evidence:
		list.add_child(_make_evidence_row("[x] %s" % item["label"], "Found in: %s" % item["source"], false))
	for i in range(evidence.size(), min_rows):
		list.add_child(_make_evidence_row("[ ] ... not found yet", "Keep looking in the apps", true))


func _make_evidence_row(headline: String, detail: String, empty: bool) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	var border := Color(COLOR_LIGHT, 0.5) if empty else Color.TRANSPARENT
	row.add_theme_stylebox_override("panel", _make_style(COLOR_DARK if empty else COLOR_NAVY, border, 1, 2))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	row.add_child(column)
	var top := Label.new()
	top.text = headline
	top.clip_text = true
	top.add_theme_font_override("font", FONT_BODY)
	top.add_theme_font_size_override("font_size", 16)
	top.add_theme_color_override("font_color", COLOR_LIGHT if empty else COLOR_WHITE)
	column.add_child(top)
	var bottom := Label.new()
	bottom.text = detail
	bottom.add_theme_color_override("font_color", COLOR_LIGHT)
	column.add_child(bottom)
	return row


func _make_style(fill: Color, border: Color, border_width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_content_margin_all(margin)
	return style


## kind: "pick" (the prompt), "not_enough" or "mismatch". A "!" icon and a border mark a refusal.
func _show_message(kind: String) -> void:
	var messages: Dictionary = _data.get("messages", {})
	var text := str(messages.get(kind, messages.get("pick", "")))
	_message_text.text = text.replace("{threat}", _picked.to_upper())
	var refused := kind != "pick"
	_message_icon.text = "!" if refused else "?"
	var border := COLOR_WHITE if refused else Color.TRANSPARENT
	_message_bar.add_theme_stylebox_override("panel", _make_style(COLOR_DARK, border, 2, 5))


func _on_threat_toggled(_toggled_on: bool) -> void:
	var pressed := _group.get_pressed_button()
	_picked = str(pressed.get_meta(&"threat")) if pressed else ""
	_refresh_threats()
	_refresh_confirm()
	_show_message("pick") # a new pick starts fresh: the old refusal no longer applies


func _on_confirm_pressed() -> void:
	var result := ReportLogic.evaluate(_picked)
	if not result["ok"]:
		_show_message(str(result["reason"]))
		return
	GameState.investigation_evidence = ReportLogic.marked_ids()
	GameState.identified_threat = _picked
	_show_result()


func _show_result() -> void:
	var result: Dictionary = _data.get("result", {})
	var required: int = _data.get("required_clues", 0)
	_title_label.text = "REPORT.exe  >  RESULT"
	_result_evidence_title.text = "YOUR EVIDENCE (%d of %d)" % [mini(ReportLogic.real_clue_count(), required), required]
	_fill_evidence(_result_evidence_list, ReportLogic.get_marked_evidence(), 0)
	_result_headline.text = str(result.get("headline", ""))
	_result_threat.text = _picked.to_upper()
	_what_happened_text.text = str(result.get("what_happened", ""))
	_what_is_title.text = "WHAT IS %s?" % _picked.to_upper()
	_what_is_text.text = str(result.get("what_is_it", ""))
	_board_page.hide()
	_result_page.show()
	_continue_button.grab_focus()


func _on_continue_pressed() -> void:
	close()
	var card := TRANSITION_SCENE.instantiate() as PhaseTransition
	get_parent().add_child(card) # in the tree first, then setup
	card.setup(ReportLogic.build_transition_data(_picked))
