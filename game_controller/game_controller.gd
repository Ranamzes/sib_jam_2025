extends Node

@export var level_number: int = 1
@export var lastCheckPoint: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func reload_level():
	var game_scene = preload("res://main2.tscn")
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
