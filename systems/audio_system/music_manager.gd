
extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	# Создаем плеер и добавляем его в дерево сцены, чтобы он был активен
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Подписываемся на сигнал смены музыки
	var event_bus = get_node("/root/EventBus")
	if event_bus:
		print("MusicManager: Connecting to EventBus...")
		event_bus.change_background_music.connect(_on_change_background_music)
	else:
		push_error("MusicManager: EventBus not found!")


func _on_change_background_music(new_stream: AudioStream) -> void:
	if not new_stream:
		push_error("Received an invalid audio stream.")
		return

	print("Changing background music...")

	music_player.stream = new_stream
	music_player.play()
