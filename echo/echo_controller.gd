class_name EchoController
extends Node2D
@export var echo_packed_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.create_echo.connect(_on_echo_requested)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_echo_requested(echo_stats:EchoStats, pos:Vector2):
	var new_echo_instance: EchoComponent =  echo_packed_scene.instantiate()
	new_echo_instance._echo_stats = echo_stats
	new_echo_instance.global_position = pos
	owner.add_child(new_echo_instance)
