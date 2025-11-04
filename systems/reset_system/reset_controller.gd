class_name ResetController
extends Node

const SAVABLE_GROUP = "savable"

var _restart_timer: Timer
@export var player_packed_scene : PackedScene

var player_respawn_position: Vector2
var last_active_checkpoint_id: int = 0

func _ready() -> void:
	EventBus.player_died.connect(_on_died)
	EventBus.new_respawn.connect(_on_new_respawn)
	EventBus.reset_level.connect(_reset_savable_objects)
	
	_restart_timer= Timer.new()
	_restart_timer.name ="RestartTimer"
	_restart_timer.one_shot = true
	_restart_timer.timeout.connect( _on_restart_timer_timeout)
	add_child(_restart_timer)
	
	var initial_player = get_tree().get_first_node_in_group(&"Player") as CharacterBody2D
	if initial_player:
		player_respawn_position = initial_player.global_position

func _on_died():
	_restart_timer.start(2)

func _on_restart_timer_timeout():
	EventBus.reset_level.emit(last_active_checkpoint_id)
	
	var player_instance:CharacterBody2D = player_packed_scene.instantiate()
	player_instance.add_to_group(&"Player")
	owner.add_child(player_instance)
	player_instance.global_position = player_respawn_position
	EventBus.player_respawned.emit(player_instance)

func _on_new_respawn(new_p: Vector2, new_id: int):
	print("ResetController received new respawn ID: ", new_id, " at position: ", new_p)
	player_respawn_position = new_p
	last_active_checkpoint_id = new_id

func _reset_savable_objects(active_checkpoint_id: int) -> void:
	print("Resetting savable objects for checkpoint ID: ", active_checkpoint_id)
	var savable_nodes = get_tree().get_nodes_in_group(SAVABLE_GROUP)
	print("Found savable nodes: ", savable_nodes)
	
	for node in savable_nodes:
		var component: CheckpointSavableComponent = node.get_node_or_null("CheckpointSavableComponent")
		if not component:
			print("WARNING: Node '" + node.name + "' is in savable group but has no CheckpointSavableComponent.")
			continue

		# Check if we should skip resetting this object.
		# If reset_until_checkpoint is null, it should always reset.
		# If it's set, only reset if the current checkpoint ID is not past the cutoff.
		if component.reset_until_checkpoint and active_checkpoint_id > component.reset_until_checkpoint.checkpoint_id:
			print("Skipping reset for '"+node.name+"' as checkpoint " + str(active_checkpoint_id) + " is past its cutoff of " + str(component.reset_until_checkpoint.checkpoint_id))
			continue

		# Tell the component to reset itself
		component.reset()
