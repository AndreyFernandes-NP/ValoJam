extends Control

@onready var background: ColorRect = $background
@onready var light_effect: ColorRect = $lightEffect
@onready var shutdown_sound: AudioStreamPlayer2D = $shutdownSound
@onready var screen: ColorRect = $screen



func _ready() -> void:
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	light_effect.set_anchors_preset(Control.PRESET_FULL_RECT)

	background.color = Color.WHITE
	light_effect.show()
	light_effect.modulate.a = 1.0

	shutdown_sound.play()

	await _shutdown_animation()

	# Depois que a animação termina, deixa só a tela preta
	background.color = Color.BLACK
	light_effect.hide()
	screen.hide()

	await get_tree().create_timer(1.0).timeout

	get_tree().quit()


func _shutdown_animation() -> void:
	var material := light_effect.material as ShaderMaterial

	material.set_shader_parameter("band_size", 1.0)
	material.set_shader_parameter("brightness", 1.0)
	material.set_shader_parameter("glow_size", 0.4)
	material.set_shader_parameter("center_glow", 0.0)
	material.set_shader_parameter("noise_power", 0.16)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Fundo branco escurece
	tween.tween_property(background, "color", Color.BLACK, 0.3)

	# Faixa branca vai fechando até virar linha
	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("band_size", value),
		0.7,
		0.015,
		0.4
	)

	# Brilho central aparece
	tween.tween_method(
		func(value: float):
			material.set_shader_parameter("center_glow", value),
		0.0,
		1.4,
		0.15
	)

	await tween.finished

	var pulse := create_tween()
	pulse.set_parallel(true)
	pulse.set_trans(Tween.TRANS_QUAD)
	pulse.set_ease(Tween.EASE_OUT)

	# Bolinha dá a pulsada final
	pulse.tween_method(
		func(value: float):
			material.set_shader_parameter("glow_size", value),
		0.15,
		0.05,
		0.1
	)

	pulse.tween_method(
		func(value: float):
			material.set_shader_parameter("brightness", value),
		0.7,
		0.0,
		0.15
	)

	await pulse.finished
