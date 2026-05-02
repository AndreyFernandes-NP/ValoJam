extends Control

@onready var td_icon: Button = $Icons/TDIcon/clickArea
@onready var message_icon: Button = $Icons/MessageIcon/clickArea
@onready var music_folder_icon: Button = $Icons/MusicFolder/clickArea

@onready var td_window: Panel = $WindowLayer/TowerDefenseWindow
@onready var message_window: Panel = $WindowLayer/MensageWindow
@onready var music_folder_window: Panel = $WindowLayer/MusicFolderWindow

@onready var td_content: Control = $WindowLayer/TowerDefenseWindow/Content
@onready var message_content: Control = $WindowLayer/MensageWindow/Content

@onready var td_close_button: Button = $WindowLayer/TowerDefenseWindow/TitleBar/closeButton
@onready var message_close_button: Button = $WindowLayer/MensageWindow/TitleBar/closeButton
@onready var music_folder_close_button: Button = $WindowLayer/MusicFolderWindow/TitleBar/closeButton

@onready var system_button: Button = $Taskbar/systemButton
@onready var system_menu: Panel = $Taskbar/systemMenu
@onready var shutdown_icon: Button = $Taskbar/systemMenu/shutDownIcon

@onready var sound_button: Button = $Taskbar/soundButton
@onready var sound_menu: Panel = $Taskbar/soundMenu

# var tower_defense_scene: PackedScene = preload("res://cenas/TowerDefense.tscn")
var message_scene: PackedScene = preload("res://Scenes/chat/ChatWindow.tscn")



func _ready() -> void:
	WindowManager.desktop_root = $WindowLayer
	
	close_window(td_window)
	close_window(message_window)
	close_window(music_folder_window)
	system_menu.hide()
	sound_menu.hide()
	
	# Ícones da área de trabalho
	td_icon.pressed.connect(func(): open_window(td_window))

	message_icon.pressed.connect(func():
		open_window(message_window)
		load_scene(message_content, message_scene)
	)

	music_folder_icon.pressed.connect(func(): open_window(music_folder_window))
	
	# Botões de fechar das janelas
	td_close_button.pressed.connect(func(): close_window(td_window))
	message_close_button.pressed.connect(func(): close_window(message_window))
	music_folder_close_button.pressed.connect(func(): close_window(music_folder_window))
	
	# Botões da taskbar
	system_button.pressed.connect(_on_system_icon_pressed)
	shutdown_icon.pressed.connect(_on_shutdown_icon_pressed)
	sound_button.pressed.connect(_on_sound_icon_pressed)


func open_window(window: Control) -> void:
	AnimationManager.open_window(window,0.3)


func load_scene(content: Control, scene: PackedScene) -> void:
	if content.get_child_count() > 0:
		return
	var scene_instance: Control = scene.instantiate()
	content.add_child(scene_instance)


func close_window(window: Control) -> void:
	AnimationManager.close_window(window)


func _on_system_icon_pressed() -> void:
	system_menu.visible = not system_menu.visible


func _on_sound_icon_pressed() -> void:
	sound_menu.visible = not sound_menu.visible


func _on_shutdown_icon_pressed() -> void:
	get_tree().quit()
