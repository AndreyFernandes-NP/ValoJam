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

# TODO:
#1. Separar entre dois arquivos, um pra diálogos e o outro pra eventos
#1.1 Eventos teria o nome do arquivo original _events.json
#1.2 Modificar o arquivo original pra conter apenas o id/speaker/texto
#1.3 Garante que eventos sejam 'secretos' mas não hardcoded
#1.4 Se tiver um _events-language.json carregará esse ao invés do padrão, permitindo até mods
#2. Arquivo _events.json será a coletânea de eventos como wps, wait, effects e etc
#2.1 Ele será executado assim que um diálogo com o mesmo id for carregado no jogo
#3.1 Lista de Eventos:
#3.1.1 type 				// tipo do evento ("choice" é o único tipo usado)
#3.1.2 next 				// id da próxima mensagem a ir
#3.1.3 choices 				// todas as escolhas do id atual (precisam conter texto e next)
#3.1.4 condition 			// condições à serem cumpridas
#3.1.4.1 flag 				// flag comparada à um valor para ser cumprida
#3.1.5 else_effects 		// efeitos ativados caso conds não forem cumpridas
#3.1.6 start_effects  		// efeitos ativados assim que der load num diálogo (precisa passar cond)
#3.1.7 effects 		  		// efeitos ativados quando terminar um diálogo
#3.1.8 cancel_effects 		// efeitos ativados após o impatience_timer
#3.1.9 wps 					// palavras por segundo (timer de escrever)
#3.1.10 wait 				// tempo de espera após mostrar a mensagem
#3.1.11 pauses 				// uma "pausa" de escrita (ex de uso: efeito de apagar e escrever dnv)
#3.1.11.1 at 				// % do tempo a ser esperado que dará o trigger (word_count / wps)
#3.1.11.2 duration 			// tempo total que vai esperar antes de continuar
#3.1.12 choice_timeout 		// tempo limite pro player escolher antes que cancel_effects dê trigger
#3.2 Lista de efeitos:
#3.2.1 flag 				// seta uma flag específica um valor específico
#3.2.2 delete_flag 			// deleta uma flag completamente do jogo
#3.2.3 increment_flag 		// incrementa uma flag por x valor
#3.2.4 skip_to 				// pular pra algum id específico de mensagem (serve como next)
#3.2.5 skip_to_load 		// pula pra algum id + carrega todas as mensagens puladas (de >> para)
#3.2.6 close_chat 			// fecha a janela do chat (mas mantém o diálogo atual carregado)
#3.2.7 close_unload_chat 	// fecha a janela + dá unload no chat
#3.2.8 create_file 			// cria um arquivo de certo tipo no local especificado
#3.2.8.1 filename 			// nome do arquivo
#3.2.8.2 type 				// tipo do arquivo (txt, json, bat, etc)
#3.2.8.3 path 				// local específico a ser criado ("user" = user:// e "origin" = pasta do jogo)
# END OF TO-DO
