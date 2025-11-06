class_name MusicTriggerZone
extends Area2D

## Аудиопоток, который будет воспроизводиться при входе в эту зону.
@export var music_stream: AudioStream

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if music_stream:
			print("MusicTriggerZone: Player entered. Emitting change_background_music signal.")
			get_node("/root/EventBus").emit_signal(&"change_background_music", music_stream)
