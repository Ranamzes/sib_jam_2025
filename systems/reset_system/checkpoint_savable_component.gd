class_name CheckpointSavableComponent
extends Node

## A component that saves and restores the state of a Node2D and its children at checkpoints.

## If true, the entire scene for the parent node will be re-instantiated on reset.
## This is for complex objects that might have parts deleted (e.g., a trap that breaks).
## If false, only the position and children's transforms will be restored.
@export var reinstantiate_on_reset: bool = false

## The checkpoint that triggers saving the object's state.
@export var save_position_at_checkpoint: RespawnArea
## The object will stop resetting after the player activates a checkpoint with an ID greater than this one.
@export var reset_until_checkpoint: RespawnArea

## (Read-only) The last saved global position of the parent node.
@export var saved_position: Vector2

var _parent_node: Node2D
var _saved_children_state: Dictionary = {}
var _original_scene_path: String

func _ready() -> void:
	_parent_node = get_parent() as Node2D
	if not _parent_node:
		push_error("CheckpointSavableComponent must have a Node2D parent.")
		return

	# Store the scene path for potential re-instantiation.
	_original_scene_path = _parent_node.scene_file_path
	if reinstantiate_on_reset and _original_scene_path.is_empty():
		push_error("CheckpointSavableComponent on '" + _parent_node.name + "' is set to re-instantiate, but the node has no scene file path.")

	# Initial state save.
	_save_state()

	# Connect to the save point.
	if save_position_at_checkpoint:
		save_position_at_checkpoint.body_entered.connect(_on_save_checkpoint_entered)
	else:
		push_error("'save_position_at_checkpoint' is not assigned in CheckpointSavableComponent for '" + _parent_node.name + "'")

func _on_save_checkpoint_entered(body: Node2D) -> void:
	# When the player enters the save area, update the saved state.
	if body.is_in_group(&"Player"):
		print("Saving state for '" + _parent_node.name + "'...")
		_save_state()

## Saves the current state of the parent and its children.
func _save_state() -> void:
	# No need to save state if we are just going to re-instance the whole scene.
	if reinstantiate_on_reset:
		saved_position = _parent_node.global_position
		print("Saved position for '" + _parent_node.name + "' at: " + str(saved_position))
		return

	saved_position = _parent_node.global_position
	_saved_children_state.clear()
	
	for child in _parent_node.get_children():
		if not child is Node2D:
			continue
		_saved_children_state[child] = {
			"transform": child.transform,
			"visible": child.visible,
		}
	print("Saved position for '" + _parent_node.name + "' at: " + str(saved_position))
	print("Saved state for " + str(_saved_children_state.size()) + " children.")

## Resets the parent node to its last saved state.
func reset() -> void:
	print("DEBUG: reset() called for '", _parent_node.name, "'")
	if not is_instance_valid(_parent_node):
		# The node was likely freed, which is expected if it was part of a re-instantiated scene.
		# The controller will create a new one. We don't need to do anything.
		print("DEBUG: Parent node '", _parent_node.name, "' is invalid, skipping reset.")
		return

	print("DEBUG: reinstantiate_on_reset is: ", reinstantiate_on_reset)
	if reinstantiate_on_reset:
		_reinstantiate_scene()
	else:
		_restore_state()

func _restore_state() -> void:
	print("DEBUG: _restore_state() called for '", _parent_node.name, "'")
	print("DEBUG: Resetting '", _parent_node.name, "' to position: ", saved_position)
	_parent_node.global_position = saved_position

	for child in _parent_node.get_children():
		if child is RigidBody2D:
			push_warning("CheckpointSavableComponent on '%s' is using 'restore state' mode, but has a RigidBody2D child ('%s'). This may not work as expected. Consider setting 'reinstantiate_on_reset' to true." % [_parent_node.name, child.name])

		if not child is Node2D or not _saved_children_state.has(child):
			continue
			
		var state: Dictionary = _saved_children_state[child]
		child.transform = state["transform"]
		child.visible = state["visible"]
		
	print("DEBUG: Finished resetting state for '", _parent_node.name, "'.")

func _reinstantiate_scene() -> void:
	print("DEBUG: _reinstantiate_scene() called for '", _parent_node.name, "'")
	print("DEBUG: Original scene path is: '", _original_scene_path, "'")

	if _original_scene_path.is_empty():
		push_error("Cannot re-instantiate '" + _parent_node.name + "': Original scene path is empty.")
		return

	var packed_scene: PackedScene = load(_original_scene_path)
	if not packed_scene:
		push_error("Failed to load packed scene from '" + _original_scene_path + "'")
		return

	print("DEBUG: Re-instantiating '", _parent_node.name, "' from scene: ", _original_scene_path)
	
	var new_instance: Node2D = packed_scene.instantiate() as Node2D
	var original_parent = _parent_node.get_parent()
	
	if not original_parent:
		push_error("Cannot re-instantiate '"+_parent_node.name+"': Original parent is null.")
		return
	
	print("DEBUG: Original parent is: '", original_parent.name, "'")
	print("DEBUG: Setting new instance position to: ", saved_position)

	# Set position and add to scene tree
	new_instance.global_position = saved_position
	original_parent.add_child(new_instance)
	
	print("DEBUG: Calling queue_free() on old instance of '", _parent_node.name, "'")
	# The old node must be removed
	_parent_node.queue_free()
	
	print("DEBUG: Successfully re-instantiated '", new_instance.name, "'.")
