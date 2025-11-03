extends RigidBody2D

var last_position: Vector2 =  Vector2.ZERO
var velocity: Vector2 =  Vector2.ZERO
var default_global_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	default_global_position = global_position
	last_position = global_position
	EventBus.reset_level.connect(_on_reset_level)


func _on_reset_level():
	global_position = default_global_position 
		

func _process(delta: float) -> void:
	velocity = (global_position - last_position) / delta
	