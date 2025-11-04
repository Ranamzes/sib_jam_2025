class_name RespawnArea
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	body.is_in_group(&"Player")
	EventBus.new_respawn.emit(global_position)
