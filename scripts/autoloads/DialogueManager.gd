extends Node

var _nodes_by_id: Dictionary = {}
var _events_by_id: Dictionary = {}
var _current: Dictionary = {}
var _events: Dictionary = {}
var _exe_dir: String = OS.get_executable_path().get_base_dir()

signal node_ready(node: Dictionary)
signal dialogue_ended

func load_dialogue(scene_id: String) -> bool:
	var data = _load_dialogue(scene_id)
	var events = _load_events(scene_id, data)
	if data.is_empty():
		push_error("DialogueManager: falha ao carregar '%s'" % scene_id)
		return false
	
	_current = data
	_events = events
	_build_index()

	return true

func _load_dialogue(scene_id: String) -> Dictionary:
	var lang = GameState.get_flag("language", "")
	
	# Tenta carregar da pasta de tradução primeiro
	if lang != "":
		var translated = _read_file(
			_exe_dir.path_join("translations/%s/data/dialogues/%s.json" %[lang, scene_id])
		)
		if not translated.is_empty():
			return translated
			
	# Fallback pro diálogo embutido no .pck (o original)
	return _read_file("res://data/dialogues/%s.json" % scene_id)

func _load_events(scene_id: String, data: Dictionary) -> Dictionary:
	var lang = GameState.get_flag("language", "")
	var path = _exe_dir.path_join("translations/%s/data/dialogues/%s_events.json" %[lang, scene_id])
	
	if FileAccess.file_exists(path):
		_update_events(path, data)
	else:
		path = "res://data/dialogues/%s_events.json" % scene_id
		if not FileAccess.file_exists(path):
			_write_events(path, data)
		else:
			_update_events(path, data)
	return _read_file(path)

func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		print("Não existe arquivo em: %s" % path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	
	content = content.strip_edges()
	if content.begins_with("\ufeff"):
		content = content.substr(1)
		
	return JSON.parse_string(content)

func _write_events(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	var events: Dictionary = {}

	for node in data:
		var value = data[node]
		if value is Array:
			var arr: Array = []
			for item in value:
				arr.append(_build_event(item))
			events[node] = arr
		else:
			events[node] = value

	file.store_string(_stringify_json(events))
	file.close()

func _update_events(path: String, data: Dictionary) -> void:
	var existing_file = FileAccess.open(path, FileAccess.READ)
	var existing_events: Dictionary = JSON.parse_string(existing_file.get_as_text())
	existing_file.close()

	var new_events: Dictionary = {}

	for node in data:
		var value = data[node]
		if not value is Array:
			new_events[node] = existing_events.get(node, value)
			continue

		var existing_by_id: Dictionary = {}
		for item in existing_events.get(node, []):
			existing_by_id[item.get("id")] = item

		var new_arr: Array = []
		for item in value:
			var id = item.get("id")
			if existing_by_id.has(id):
				new_arr.append(existing_by_id[id])
			else:
				new_arr.append(_build_event(item))

		new_events[node] = new_arr

	if new_events == existing_events:
		return

	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(_stringify_json(new_events))
	file.close()

func _build_event(item: Dictionary) -> Dictionary:
	var event: Dictionary = {}

	event["id"] = item.get("id")

	if item.has("type"):
		event["type"] = item.get("type")

	if item.has("choices"):
		var choices: Array = []
		for choice in item.get("choices"):
			choices.append({"next": choice.get("next")})
		event["choices"] = choices
	else:
		event["_text"] = item.get("text")
		if item.get("speaker") != "user":
			event["wps"] = 10
			event["wait"] = 1.0
		event["next"] = item.get("next", "END")

	return event

func _stringify_json(value, level: int = 0, inline_items: bool = false) -> String:
	var ind = "\t".repeat(level)
	var ind_inner = "\t".repeat(level + 1)

	if value is Dictionary:
		if value.is_empty():
			return "{}"
		if inline_items:
			return JSON.stringify(value)
		var lines: Array = ["{"]
		var keys = value.keys()
		for i in keys.size():
			var key = keys[i]
			var comma = "," if i < keys.size() - 1 else ""
			var is_choices = key == "choices"
			lines.append('%s"%s": %s%s' % [ind_inner, key, _stringify_json(value[key], level + 1, is_choices), comma])
		lines.append(ind + "}")
		return "\n".join(lines)

	elif value is Array:
		if value.is_empty():
			return "[]"
		var lines: Array = ["["]
		for i in value.size():
			var comma = "," if i < value.size() - 1 else ""
			lines.append("%s%s%s" % [ind_inner, _stringify_json(value[i], level + 1, inline_items), comma])
		lines.append(ind + "]")
		return "\n".join(lines)

	else:
		return JSON.stringify(value)

# Varre a pasta translations/ e retorna as línguas disponíveis
func get_available_languages() -> Array[String]:
	var languages:Array[String] = []
	var path = _exe_dir.path_join("translations")
	
	if not DirAccess.dir_exists_absolute(path):
		return languages
		
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			languages.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	
	return languages

# get_available_languages() seria usado tipo assim:
# var langs = DialogueLoader.get_available_languages()
# pra então o dropdown das línguas aparecer

func _build_index() -> void:
	_nodes_by_id.clear()
	_events_by_id.clear()
	
	for node in _current.get("nodes", []):
		var id = node.get("id", "")
		if not _nodes_by_id.has(id):
			_nodes_by_id[id] = []
		_nodes_by_id[id].append(node)
		
	for node in _events.get("nodes", []):
		var id = node.get("id", "")
		if not _events_by_id.has(id):
			_events_by_id[id] = []
		_events_by_id[id].append(node)

func start() -> void:
	var entry = _current.get("entry", "")
	if entry == "":
		entry = _current["nodes"][0].get("id", "")
	
	advance_to(entry)

func advance_to(node_id: String) -> void:
	if node_id == "END":
		emit_signal("dialogue_ended")
		return
	
	var node = _resolve_node(node_id)
	var event = _resolve_event(node_id)
	
	if node.is_empty():
		push_error("DialogueManager: node '%s' não encontrado" % node_id)
		return
	
	if event.is_empty():
		push_error("DialogueManager: evento de '%s' não encontrado" % node_id)
		return
	
	emit_signal("node_ready", node, event)

func _resolve_node(node_id: String) -> Dictionary:
	for candidate in _nodes_by_id.get(node_id, []):
		return candidate
		
	return {}

func _resolve_event(node_id: String) -> Dictionary:
	for candidate in _events_by_id.get(node_id, []):
		return candidate
	
	return {}

func is_choice(node: Dictionary) -> bool:
	return node.get("type", "") == "choice"

func confirm_node(node: Dictionary) -> void:
	advance_to(node.get("next", "END"))

func pick_choice(node: Dictionary, index: int) -> void:
	var choices: Array = node.get("choices", "")
	if index >= choices.size():
		push_error("DialogueManager: índice de escolha inválido")
		return
	
	var choice = choices[index]
	advance_to(choice.get("next", "END"))
