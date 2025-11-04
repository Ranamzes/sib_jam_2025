class_name RespawnArea
extends Area2D

@export var checkpoint_id: int = 0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"Player"):
		print("Player entered RespawnArea ID: ", checkpoint_id, " at: ", global_position)
		EventBus.new_respawn.emit(global_position, checkpoint_id)
