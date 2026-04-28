extends Control
@onready var DM := DialogueManager

var _pending_node: Dictionary = {}
var _waiting_choice: bool = false # Temporário

func _ready() -> void:
	$VBoxContainer/ScrollContainer/MessagesBox.add_theme_constant_override("separation", 12)
	$VBoxContainer/ScrollContainer.get_v_scroll_bar().changed.connect(_scroll_to_bottom)
	$VBoxContainer/ChoicesContainer.add_theme_constant_override("separation", 8)
	
	DialogueManager.node_ready.connect(_on_node_ready)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.load_dialogue("dl_test")
	DialogueManager.start()
	for i in DialogueManager._nodes_by_id.size()-2:
		while _waiting_choice:
			await get_tree().process_frame
		await get_tree().create_timer(2.5).timeout
		DialogueManager.advance_to(_pending_node.get("next", "END"))

func _on_node_ready(node: Dictionary) -> void:
	if DialogueManager.is_choice(node):
		_pending_node = node
		_show_choices(node.get("choices", []))
	else:
		_pending_node = node
		_show_message(node.get("speaker", "user"), node.get("text", ""))

func _scroll_to_bottom() -> void:
	var scroll = $VBoxContainer/ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _show_message(speaker: String, text: String) -> void:
	var is_user = speaker == "user"
	
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_FILL
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text_direction = Control.TEXT_DIRECTION_LTR
	label.custom_minimum_size.x = 100
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s" % text
	
	if is_user:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(spacer)
		row.add_child(label)
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(label)
		row.add_child(spacer)
	
	$VBoxContainer/ScrollContainer/MessagesBox.add_child(row)

func _show_choices(choices: Array) -> void:
	_waiting_choice = true
	for i in choices.size():
		var btn = Button.new()
		btn.text = choices[i]["text"]
		
		var current_node = _pending_node
		btn.pressed.connect(func():
			_clear_choices()
			DialogueManager.pick_choice(current_node, i))
		$VBoxContainer/ChoicesContainer.add_child(btn)

func _clear_choices() -> void:
	_waiting_choice = false
	for child in $VBoxContainer/ChoicesContainer.get_children():
		if child is Button:
			child.queue_free()

func _on_dialogue_ended() -> void:
	_pending_node = {}
