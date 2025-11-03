class_name ResetController
extends Node
var _restart_timer: Timer
@export var player_packed_scene : PackedScene
var player_respawn_position: Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.player_died.connect(_on_died)
	EventBus.new_respawn.connect(_on_new_respawn)
	_restart_timer= Timer.new()
	_restart_timer.name ="RestartTimer"
	_restart_timer.one_shot = true
	_restart_timer.timeout.connect( _on_restart_timer_timeout)
	add_child(_restart_timer)
	player_respawn_position = (get_tree().get_first_node_in_group(&"Player") as CharacterBody2D).global_position
	


# Called every frame. 'delta' is the elapsed time since the previous frame.


func _on_died():
	_restart_timer.start(2)

func _on_restart_timer_timeout():
	EventBus.reset_level.emit()
	var player_instance:CharacterBody2D = player_packed_scene.instantiate()
	player_instance.add_to_group(&"Player")
	owner.add_child(player_instance)
	player_instance.global_position = player_respawn_position

func _on_new_respawn(new_p:Vector2):
	player_respawn_position = new_p
