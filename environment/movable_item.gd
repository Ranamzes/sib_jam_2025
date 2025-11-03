extends RigidBody2D

var last_position: Vector2 =  Vector2.ZERO
var velocity: Vector2 =  Vector2.ZERO

func _ready() -> void:
	last_position = global_position;

func _process(delta: float) -> void:
	velocity = (global_position - last_position) / delta
	