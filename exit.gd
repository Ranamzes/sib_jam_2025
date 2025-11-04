
extends Area2D


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		await get_tree().create_timer(1.5).timeout
		var win_screen_scene = preload("res://puzzle/new_puzzle.tscn")
		if win_screen_scene:
			get_tree().change_scene_to_packed(win_screen_scene)	
		else:
			push_error("Failed to load win screen scene!")
