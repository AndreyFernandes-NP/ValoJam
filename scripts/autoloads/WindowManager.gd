extends Node

# Referência à cena raiz do desktop, é setada pelo Desktop.tscn ao iniciar
var desktop_root: Node = null

signal window_opened(window_name: String)
signal window_closed(window_name: String)

func open_window(scene_path: String, window_name: String) -> Node:
	if desktop_root == null:
		push_error("WindowManager: desktop_root não foi setado.")
		return null
	
	var scene = load(scene_path).instantiate()
	scene.name = window_name
	desktop_root.add_child(scene)
	emit_signal("window_opened", window_name)
	return scene

func close_window(window_name: String) -> void:
	if desktop_root == null:
		return
	var window = desktop_root.get_node_or_null(window_name)
	if window:
		window.queue_free()
		emit_signal("window_closed", window_name)
