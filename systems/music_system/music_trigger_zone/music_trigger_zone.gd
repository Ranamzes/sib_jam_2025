class_name MusicTriggerZone
extends Area2D

## Аудиопоток, который будет воспроизводиться при входе в эту зону.
@export var music_stream: AudioStream
## Длительность кроссфейда в секундах.
@export var fade_duration: float = 1.5

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(GroupNames.PLAYER):
		if music_stream:
			print("MusicTriggerZone: Player entered. Emitting change_background_music signal with duration: " + str(fade_duration))
			EventBus.change_background_music.emit(music_stream, fade_duration)
