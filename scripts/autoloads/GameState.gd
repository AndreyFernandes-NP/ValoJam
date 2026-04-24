extends Node

# Versão atual do TD "instalada"
var td_version: String = "0.1"

# Flags gerais do ARG, só adicionar aqui se precisar de alguma
var flags: Dictionary = {}

# Quantas vezes o player fechou o jogo (controla progressão ARG)
# Obs: Contabilizar apenas se ele fechou em um estado "aceitável"
var close_count: int = 0

# Sinal emitido quando uma flag muda, usado em relação as funções abaixo
signal flag_changed(key: String, value: Variant)

# Funções chaves para escrita/leitura de flags
func set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	emit_signal("flag_changed", key, value)

func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)

func has_flag(key: String) -> bool:
	return flags.has(key)

# Como checar/setar uma flag do ARG:
#GameState.set_flag("maciel_cuzinho_largo", true)
#GameState.get_flag("td_pedrao_gebona_enorme", false)
#GameState.set_flag("chat_scroll_position", chat.scroll_pos)
#GameState.set_flag("chat_messages", chat.message_history)
#...
# Use isso em OUTROS scripts, não nesse pelo amor de deus kkkkkk
# Seria mais usado em um .gd em que precisamos comparar/obter flags
