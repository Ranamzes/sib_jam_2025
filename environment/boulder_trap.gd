extends Node2D

@export var holder_collision_shape_path: NodePath

var _holder_collision_shape: CollisionShape2D

func _ready() -> void:
	if not holder_collision_shape_path.is_empty():
		_holder_collision_shape = get_node_or_null(holder_collision_shape_path)

	if not _holder_collision_shape:
		push_error("BoulderTrap: Holder collision shape not found at path: %s" % holder_collision_shape_path)


func _on_player_trigger_body_entered(body: Node):
	print("area work")
	if body.is_in_group("Player"):
		print("player group")
		if _holder_collision_shape:
			print("нашли шейп")
			_holder_collision_shape.queue_free()
		else:
			push_error("BoulderTrap: Cannot disable holder, collision shape is not assigned.")
