extends Node

func open_window(instance: Control, duration: float = 0.15) -> Tween:
	# Define o pivô no centro do node, normalmente ele fica no (0,0), 
	# Assim a animação vai vir sempre do centro
	instance.pivot_offset = instance.size / 2
	
	instance.scale = Vector2(0.9,0.9)
	# Modulate.a serve para alterar o alpha, que é a opacidade/transparencia, do node
	# com a escala de 0.0 a 1.0
	instance.modulate.a = 0.0
	instance.show()
	instance.move_to_front()
	
	var tween := instance.create_tween()
	# Faz as animações rodarem ao mesmo tempo
	tween.set_parallel(true) 
	# O Trans_Back faz ele ir de 0.9 -> 1.05 -> 1.0 por exemplo
	tween.set_trans(Tween.TRANS_BACK)
	# O Ease_out faz começar rapido e terminar devagar a animação
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(instance, "scale", Vector2(1,1), duration)
	tween.tween_property(instance, "modulate:a", 1.0, duration)

	return tween
	
func close_window(instance: Control, duration: float = 0.15) -> Tween:
	var tween := instance.create_tween()
	tween.set_parallel(true)
	# O Trans_Quad faz a animação seguir de uma forma quadratica em vez de linear
	# Juntando com Ease_in faz a animação ficar desse jeito aqui mais ou menos 
	# > https://imgur.com/3Kuqboh
	tween.set_trans(Tween.TRANS_QUAD)
	# O EASE_IN faz começar devagar e terminar rápido a animação
	# é o oposto do amigão la de cima
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(instance, "scale", Vector2(0.9, 0.9), duration)
	tween.tween_property(instance, "modulate:a", 0.0, duration)

	tween.finished.connect(func():
		instance.hide()
		instance.scale = Vector2(1,1)
		instance.modulate.a = 1.0
	)	

	return tween

func shutdown_screen(overlay: ColorRect) -> Tween:
	overlay.visible = true
	overlay.move_to_front()

	# Garante que o pivô fique no centro da tela,
	# porque a animação vai "fechar" a imagem pro meio.
	overlay.pivot_offset = overlay.size / 2

	# Começa como um flash branco cobrindo a tela inteira.
	overlay.color = Color.WHITE
	overlay.scale = Vector2(1.0, 1.0)
	overlay.modulate.a = 0.0

	var tween := overlay.create_tween()

	# Primeiro dá aquele flash rápido de monitor/TV desligando.
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay, "modulate:a", 1.0, 0.08)

	# Depois a tela fecha na vertical, virando uma linha no meio.
	tween.tween_property(overlay, "scale:y", 0.025, 0.22)

	# A linha some fechando na horizontal.
	tween.tween_property(overlay, "scale:x", 0.0, 0.16)

	tween.finished.connect(func():
		overlay.color = Color.BLACK
		overlay.scale = Vector2(1.0, 1.0)
		overlay.modulate.a = 1.0
	)

	return tween

func restore_window(instance: Control, restore_size: Vector2, restore_position: Vector2, duration: float = 0.15) -> Tween:
	instance.scale = Vector2(1,1)
	instance.pivot_offset = instance.size / 2
	instance.move_to_front()

	var tween := instance.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(instance, "size", restore_size, duration)
	tween.tween_property(instance, "position", restore_position, duration)

	return tween
