class_name CheckpointSavableComponent
extends Node

## The RespawnArea that triggers the saving of this object's state.
@export var save_point: Area2D

var _saved_position: Vector2
var _parent_node: Node2D

func _ready() -> void:
	_parent_node = get_parent() as Node2D
	if not _parent_node:
		push_error("CheckpointSavableComponent must have a Node2D parent.")
		return

	# Save the initial position.
	_saved_position = _parent_node.global_position

	# Connect to the save point and the global reset event.
	if save_point:
		save_point.body_entered.connect(_on_save_point_entered)
	else:
		push_error("Save_point is not assigned in CheckpointSavableComponent for '" + _parent_node.name + "'")

	EventBus.reset_level.connect(_on_reset_level)


func _on_save_point_entered(body: Node2D) -> void:
	# When the player enters the save area, update the saved position.
	if body.is_in_group(&"Player"):
		_saved_position = _parent_node.global_position
		print("Saved position for '" + _parent_node.name + "' at: " + str(_saved_position))


func _on_reset_level() -> void:
	# When the level resets, move the parent back to its last saved position.
	_parent_node.global_position = _saved_position
