class_name RecoveryDialog
extends Control

## Layout lives in RecoveryDialog.tscn. Paragraphs and action buttons are copies of
## the hidden templates in that scene, so restyling a template restyles every copy.

var buttons: Dictionary = {}
var _heading := ""
var _paragraphs: Array[String] = []
var _actions: Array[Dictionary] = []

@onready var _title: Label = %Title
@onready var _scroll_hint: Label = %ScrollHint
@onready var _scroll: ScrollContainer = %Scroll
@onready var _content: VBoxContainer = %Content
@onready var _paragraph_template: Label = %ParagraphTemplate
@onready var _footer: HBoxContainer = %Footer
@onready var _action_template: Button = %ActionTemplate


func configure(heading: String, paragraphs: Array[String], actions: Array[Dictionary]) -> void:
	_heading = heading
	_paragraphs = paragraphs
	_actions = actions


func _ready() -> void:
	_title.text = _heading
	for text in _paragraphs:
		var paragraph := _paragraph_template.duplicate() as Label
		paragraph.unique_name_in_owner = false
		paragraph.text = text
		paragraph.show()
		_content.add_child(paragraph)
	for action in _actions:
		var button := _action_template.duplicate() as Button
		button.unique_name_in_owner = false
		button.text = str(action["label"])
		button.pressed.connect(action["callback"])
		button.show()
		_footer.add_child(button)
		buttons[str(action["id"])] = button
	RecoveryStyle.focus_loop(self)
	_update_scroll_hint.call_deferred()


func _update_scroll_hint() -> void:
	await get_tree().process_frame
	var bar := _scroll.get_v_scroll_bar()
	_scroll_hint.visible = bar.max_value > bar.page


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode in [KEY_PAGEDOWN, KEY_PAGEUP]:
		_scroll.scroll_vertical += 130 if event.keycode == KEY_PAGEDOWN else -130
		get_viewport().set_input_as_handled()
