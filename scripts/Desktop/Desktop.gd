extends Control

# Icones
@onready var td_icon: Button = $Icons/TDIcon/clickArea
@onready var message_icon: Button = $Icons/MessageIcon/clickArea
@onready var music_folder_icon: Button = $Icons/MusicFolder/clickArea

@onready var task_icons: HBoxContainer = $Taskbar/taskIcons

@onready var message_icon_image: TextureRect = $Icons/MessageIcon/iconImage

# Janelas
@onready var td_window: Panel = $WindowLayer/TowerDefenseWindow
@onready var message_window: Panel = $WindowLayer/MensageWindow
@onready var music_folder_window: Panel = $WindowLayer/MusicFolderWindow

# Conteudo dentro da janela
@onready var td_content: Control = $WindowLayer/TowerDefenseWindow/Content
@onready var message_content: Control = $WindowLayer/MensageWindow/Content

# Botoes de fechar
@onready var td_close_button: Button = $WindowLayer/TowerDefenseWindow/TitleBar/closeButton
@onready var message_close_button: Button = $WindowLayer/MensageWindow/TitleBar/closeButton
@onready var music_folder_close_button: Button = $WindowLayer/MusicFolderWindow/TitleBar/closeButton

# Botoes de restaurar
@onready var td_restore_button: Button = $WindowLayer/TowerDefenseWindow/TitleBar/restoreButton
@onready var message_restore_button: Button = $WindowLayer/MensageWindow/TitleBar/restoreButton
@onready var music_folder_restore_button: Button = $WindowLayer/MusicFolderWindow/TitleBar/restoreButton

# Botoes de minimizar
@onready var message_minimize_button: Button =$WindowLayer/MensageWindow/TitleBar/minimizeButton

# Botoes do painel
@onready var system_button: Button = $Taskbar/systemButton
@onready var sound_button: Button = $Taskbar/soundButton
@onready var shutdown_icon: Button = $Taskbar/systemMenu/shutDownIcon

# Menus do painel
@onready var sound_menu: Panel = $Taskbar/soundMenu
@onready var system_menu: Panel = $Taskbar/systemMenu


# Posições e tamanhos originais das janelas
var td_original_size: Vector2
var td_original_position: Vector2

var message_original_size: Vector2
var message_original_position: Vector2

var music_folder_original_size: Vector2
var music_folder_original_position: Vector2

# Estados das janelas para a inversão
var td_is_restored := false
var message_is_restored := false
var music_folder_is_restored := false

# dic
var minimized_windows := {}

# Scenes 
# var tower_defense_scene: PackedScene = preload("res://cenas/TowerDefense.tscn")
var message_scene: PackedScene = preload("res://Scenes/chat/ChatWindow.tscn")
var shutdown_scene: PackedScene = preload("res://Scenes/desktop/Shutdown2.tscn")


func _ready() -> void:
	WindowManager.desktop_root = $WindowLayer
	
	# Armazena os valores originais das janelas antes de qualquer alteração
	td_original_size = td_window.size
	td_original_position = td_window.position

	message_original_size = message_window.size
	message_original_position = message_window.position

	music_folder_original_size = music_folder_window.size
	music_folder_original_position = music_folder_window.position
	
	close_window(td_window)
	close_window(message_window)
	close_window(music_folder_window)
	
	td_window.show()
	system_menu.hide()
	sound_menu.hide()
	
	# Ícones da área de trabalho
	td_icon.pressed.connect(func():
		open_window(td_window)
	)

	message_icon.pressed.connect(func():
		open_window(message_window)
		load_scene(message_content, message_scene)
	)

	music_folder_icon.pressed.connect(func():
		open_window(music_folder_window)
	)
	
	# Botões de fechar das janelas
	td_close_button.pressed.connect(func():
		close_window(td_window)
	)

	message_close_button.pressed.connect(func():
		close_window(message_window)
	)

	music_folder_close_button.pressed.connect(func():
		close_window(music_folder_window)
	)
	
	# Botões de restaurar as janelas
	td_restore_button.pressed.connect(func():
		td_is_restored = toggle_restore_window(
			td_window,
			td_is_restored,
			td_original_size,
			td_original_position,
			Vector2(500, 300),
			Vector2(340, 180)
		)
	)
	
	message_restore_button.pressed.connect(func():
		message_is_restored = toggle_restore_window(
			message_window,
			message_is_restored,
			message_original_size,
			message_original_position,
			Vector2(500, 300),
			Vector2(340, 180)
		)
	)
	
	# Botões de minimizar as janelas
	message_minimize_button.pressed.connect(func():
		minimize_window(message_window, message_icon_image.texture)
	)



	# Botões da taskbar
	system_button.pressed.connect(_on_system_icon_pressed)
	shutdown_icon.pressed.connect(_on_shutdown_icon_pressed)
	sound_button.pressed.connect(_on_sound_icon_pressed)


func open_window(window: Control) -> void:
	AnimationManager.open_window(window, 0.3)


func load_scene(content: Control, scene: PackedScene) -> void:
	if content.get_child_count() > 0:
		return

	var scene_instance: Control = scene.instantiate()
	content.add_child(scene_instance)


func close_window(window: Control) -> void:
	AnimationManager.close_window(window)
	
	if minimized_windows.has(window):
		var task_button: Button = minimized_windows[window]
		task_button.queue_free()
		minimized_windows.erase(window)

func toggle_restore_window(
	window: Control,
	is_restored: bool,
	original_size: Vector2,
	original_position: Vector2,
	restored_size: Vector2,
	restored_position: Vector2
) -> bool:
	if is_restored:
		AnimationManager.restore_window(window, original_size, original_position, 0.07)
	else:
		AnimationManager.restore_window(window, restored_size, restored_position, 0.07)

	return not is_restored

func minimize_window(window: Control, window_icon: Texture2D) -> void:
	window.hide()
	
	if minimized_windows.has(window):
		return
	
	# Configuração do botão na taskbar
	var task_button := Button.new()
	task_button.icon = window_icon
	task_button.expand_icon = true
	task_button.custom_minimum_size = Vector2(64, 32)
	task_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	task_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color.TRANSPARENT
	task_button.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color("#8a8a8a55")
	task_button.add_theme_stylebox_override("hover", hover_style)
	
	

	task_icons.add_child(task_button)
	minimized_windows[window] = task_button

	task_button.pressed.connect(func():
		restore_minimized_window(window)
	)
	
func restore_minimized_window(window: Control) -> void:
	open_window(window)
	window.move_to_front()


func _on_system_icon_pressed() -> void:
	system_menu.visible = not system_menu.visible

func _on_sound_icon_pressed() -> void:
	sound_menu.visible = not sound_menu.visible

func _on_shutdown_icon_pressed() -> void:
	get_tree().change_scene_to_packed(shutdown_scene)
