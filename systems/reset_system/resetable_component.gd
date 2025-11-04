class_name ResetableComponent
extends Node

var default_global_position:Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(owner is Node):
		print(owner)
		default_global_position = (owner as Node).global_position
		EventBus.reset_level.connect(_on_reset_level)


func _on_reset_level(_checkpoint_id: int):
	if(owner is Node):
		(owner as Node).global_position = default_global_position 
		(owner as Node).get_parent()
