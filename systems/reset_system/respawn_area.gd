class_name RespawnArea
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"Player"):
		print("Player entered RespawnArea at: ", global_position)
		EventBus.new_respawn.emit(global_position)
