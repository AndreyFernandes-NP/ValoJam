extends Control

var _pending_node: Dictionary = {}
var _typing_tween: Tween = null
var _impatience_timer: SceneTreeTimer = null

func _ready() -> void:
	$VBoxContainer/ScrollContainer/MessagesBox.add_theme_constant_override("separation", 12)
	$VBoxContainer/ScrollContainer.get_v_scroll_bar().changed.connect(_scroll_to_bottom)
	$VBoxContainer/ChoicesContainer.add_theme_constant_override("separation", 8)
	
	DialogueManager.node_ready.connect(_on_node_ready)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	DialogueManager.load_dialogue("dl_test")
	DialogueManager.start()
		

func _on_node_ready(node: Dictionary) -> void:
	if DialogueManager.is_choice(node):
		_pending_node = node
		_show_choices(node.get("choices", []))
	else:
		await _show_message(node)
		DialogueManager.confirm_node(node)

func _scroll_to_bottom() -> void:
	var scroll = $VBoxContainer/ScrollContainer
	scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _show_message(node: Dictionary) -> void:
	var is_user: bool = node.get("speaker", "") == "user"
	var read_time: float = node.get("wait", 0.0)
	
	if not is_user:
		await _simulate_typing(node)
	
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
	label.text = "%s" % node.get("text", "")
	
	if is_user:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(spacer)
		row.add_child(label)
	else:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(label)
		row.add_child(spacer)
	
	$VBoxContainer/ScrollContainer/MessagesBox.add_child(row)
	if read_time > 0:
		await get_tree().create_timer(read_time).timeout

func _show_choices(choices: Array) -> void:
	for i in choices.size():
		var btn = Button.new()
		btn.text = choices[i]["text"]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		
		var current_node = _pending_node
		btn.pressed.connect(func():
			_impatience_timer = null
			_clear_choices()
			DialogueManager.pick_choice(current_node, i))
		$VBoxContainer/ChoicesContainer.add_child(btn)

func _clear_choices() -> void:
	for child in $VBoxContainer/ChoicesContainer.get_children():
		if child is Button:
			child.queue_free()

func _simulate_typing(node: Dictionary) ->  void:
	var text: String = node.get("text", "")
	var wps: float = node.get("wps", 6.0)
	var pauses: Array = node.get("pauses", [])
	
	var word_count = text.length()
	var total_time = max(0.0, word_count / (1.0 if wps == 0.0 else wps))
	
	var indicator = _show_typing_indicator()
	var elapsed = 0.0
	var step = 0.05
	
	while elapsed < total_time:
		for pause in pauses:
			var at_time = pause["at"] * total_time
			if elapsed >= at_time and elapsed < at_time + step:
				indicator.hide()
				await get_tree().create_timer(pause["duration"]).timeout
				indicator.show()
		
		await get_tree().create_timer(step).timeout
		elapsed += step
	
	if _typing_tween:
		_typing_tween.kill()
		_typing_tween = null
	indicator.queue_free()

func _show_typing_indicator() -> Label:
	var indicator = Label.new()
	var anim_arr: Array = ["· . .", ". · .", ". . ·"]
	var idx = [0]
	
	indicator.text = ". . ."
	$VBoxContainer/ScrollContainer/MessagesBox.add_child(indicator)
	
	_typing_tween = get_tree().create_tween().set_loops()
	_typing_tween.tween_callback(func():
		if is_instance_valid(indicator):
			indicator.text = anim_arr[idx[0]]
			idx[0] = (idx[0]+1) % anim_arr.size()
		).set_delay(0.15)
	
	return indicator

func _start_impatience_timer(node: Dictionary) -> void:
	var timeout = node.get("choice_timeout", 0.0)
	var curr_id = node.get("id", "")
	if timeout <= 0.0 or curr_id == "":
		return
	
	_impatience_timer = get_tree().create_timer(timeout)
	await _impatience_timer.timeout
	
	if _pending_node.get("id", "") != curr_id or _pending_node.is_empty():
		return
	
	_clear_choices()
	_pending_node = {}
	#DialogueManager.apply_effects("cancel_effects", [])
	DialogueManager.advance_to(node.get("cancel_next", "END"))

func _on_dialogue_ended() -> void:
	_pending_node = {}
