extends Panel

@onready var music_grid: GridContainer = $Content/MusicGrid
@onready var audio_player: AudioStreamPlayer2D = $MusicaBG

var music_icon_scene: PackedScene = preload("res://Scenes/desktop/MusicIcon.tscn")
var music_folder_path := "res://assets/sounds/Desktop/"

func _ready() -> void:
	load_music_files()

func load_music_files() -> void:
	var dir := DirAccess.open(music_folder_path)
	
	if dir == null:
		push_error("Folder de música não encontrado: " + music_folder_path)
		return
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var lower_name := file_name.to_lower()
			
			if lower_name.ends_with(".ogg") or lower_name.ends_with(".mp3") or lower_name.ends_with(".wav"):
				create_music_icon(file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func create_music_icon(file_name: String) -> void:
	var icon := music_icon_scene.instantiate()
	
	icon.get_node("Label").text = file_name.get_basename()
	
	var button: Button = icon.get_node("clickArea")
	button.pressed.connect(func():
		play_music(music_folder_path + file_name)
	)
	
	music_grid.add_child(icon)

func play_music(path: String) -> void:
	var stream := load(path)
	
	if stream == null:
		push_error("Não consegui carregar a música: " + path)
		return
	
	audio_player.stream = stream
	audio_player.play()
