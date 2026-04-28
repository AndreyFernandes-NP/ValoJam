extends Control

func _ready() -> void:
	DialogueManager.node_ready.connect(_on_node_ready)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.load_dialogue("dl_test")
	DialogueManager.start()
	await get_tree().create_timer(2.0).timeout
	DialogueManager.advance_to("response1")
	await get_tree().create_timer(2.0).timeout
	DialogueManager.advance_to("response2")
	await get_tree().create_timer(2.0).timeout
	DialogueManager.advance_to("response3")

func _on_node_ready(node: Dictionary) -> void:
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = _resolve_direction(node)
	
	var text = node.get("text", "")
	label.text = "%s" % text
	
	$VBoxContainer/ScrollContainer/MessageBox.add_child(label)
	
	await get_tree().process_frame
	$VBoxContainer/ScrollContainer.scroll_vertical = INF
	
func _resolve_direction(node: Dictionary) -> HorizontalAlignment:
	if node.get("speaker", "user") == "user":
		return HORIZONTAL_ALIGNMENT_RIGHT
		
	return HORIZONTAL_ALIGNMENT_LEFT

func _on_dialogue_ended() -> void:
	pass
