
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		var win_screen_scene = preload("res://world.tscn")
		if win_screen_scene:
			get_tree().change_scene_to_packed(win_screen_scene)	
		else:
			push_error("Failed to load win screen scene!")
