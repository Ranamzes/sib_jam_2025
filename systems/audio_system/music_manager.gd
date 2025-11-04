
extends Node

var music_player: AudioStreamPlayer

func _ready() -> void:
	# Создаем плеер и добавляем его в дерево сцены, чтобы он был активен
	music_player = AudioStreamPlayer.new()
	add_child(music_player)

	# Подписываемся на сигнал смены музыки
	get_node("/root/EventBus").change_background_music.connect(_on_change_background_music)


func _on_change_background_music(new_stream: AudioStream) -> void:
	if not new_stream:
		push_error("Received an invalid audio stream.")
		return

	print("Changing background music...")

	# Если уже играет музыка, и это не тот же трек, плавно останавливаем
	if music_player.playing and music_player.stream != new_stream:
		# Godot не имеет встроенного crossfade, поэтому делаем простой fade-out/fade-in
		var tween = get_tree().create_tween()
		tween.tween_property(music_player, "volume_db", -80.0, 0.5).set_trans(Tween.TRANS_LINEAR)
		await tween.finished

	# Устанавливаем новый трек и запускаем
	music_player.stream = new_stream
	music_player.volume_db = 0.0 # Сбрасываем громкость
	music_player.play()
	print("Now playing: %s" % new_stream.resource_path)
