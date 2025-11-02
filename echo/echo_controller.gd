class_name EchoController
extends Node2D
@export var echo_packed_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_echo_requested(echo_stats:EchoStats,position:Vector2):
	var new_echo_instance: EchoComponent =  echo_packed_scene.instantiate()
	new_echo_instance.echo_stats = echo_stats
	new_echo_instance.global_position = position
	#CHANGE TO owner.add_child after signal added
	owner.owner.add_child(new_echo_instance)
	new_echo_instance.start_lifetime_timer()
