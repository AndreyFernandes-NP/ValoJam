extends Node

var _exe_dir: String = OS.get_executable_path().get_base_dir()

func load_dialogue(scene_id: String) -> Dictionary:
	var lang = GameState.get_flag("language", "")
	
	# Tenta carregar da pasta de tradução primeiro
	if lang != "":
		var translated = _load_from_translation(lang, scene_id)
		if not translated.is_empty():
			return translated
	
	# Fallback para o diálogo embutido no .pck (o original)
	return _load_from_resources(scene_id)

func _load_from_translation(lang: String, scene_id: String) -> Dictionary:
	var path = _exe_dir.path_join(
		"translations/%s/data/dialogue/%s.json" % [lang, scene_id]
	)
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text()) # Em dúvida se vai ou não ser .json

func _load_from_resources(scene_id: String) -> Dictionary:
	var path = "res://data/dialogues/%s.json" % scene_id
	if not FileAccess.file_exists(path):
		push_error("DialogueLoader: arquivo não encontrado - %s" % path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

# Varre a pasta translations/ e retorna as línguas disponíveis
func get_available_languages() -> Array[String]:
	var languages: Array[String] = []
	var translations_path = _exe_dir.path_join("translations")
	
	if not DirAccess.dir_exists_absolute(translations_path):
		return languages
	
	var dir = DirAccess.open(translations_path)
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			languages.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	
	return languages

# get_available_languages() seria usado tipo assim:
#var langs = DialogueLoader.get_available_languages()
# pra então o dropdown das línguas aparecer
