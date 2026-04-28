extends Node

var _nodes_by_id: Dictionary = {}
var _current: Dictionary = {}
var _exe_dir: String = OS.get_executable_path().get_base_dir()

signal node_ready(node: Dictionary)
signal dialogue_ended

func load_dialogue(scene_id: String) -> bool:
	var data = _load(scene_id)
	if data.is_empty():
		push_error("DialogueManager: falha ao carregar '%s'" % scene_id)
		return false
	
	_current = data
	_build_index()

	return true

func _load(scene_id: String) -> Dictionary:
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

## get_available_languages() seria usado tipo assim:
## var langs = DialogueLoader.get_available_languages()
## pra então o dropdown das línguas aparecer

func _build_index() -> void:
	_nodes_by_id.clear()
	
	for node in _current.get("nodes", []):
		var id = node.get("id", "")
		if not _nodes_by_id.has(id):
			_nodes_by_id[id] = []
		_nodes_by_id[id].append(node)

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
	if node.is_empty():
		push_error("DialogueManager: node '%s' não encontrado" % node_id)
		return
	
	emit_signal("node_ready", node)

func _resolve_node(node_id: String) -> Dictionary:
	for candidate in _nodes_by_id.get(node_id, []):
		return candidate
		
	return {}

func is_choice(node: Dictionary) -> bool:
	return node.get("type", "") == "choice"
