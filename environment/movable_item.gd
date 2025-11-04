class_name MovableItem
extends RigidBody2D

@export_group("Physics Properties")
@export var initial_mass: float = 25.0
@export var initial_friction: float = 0.8
@export var initial_linear_damp: float = 5.0

var default_global_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	default_global_position = global_position

	# Apply exported physics properties to the native RigidBody2D properties
	mass = initial_mass
	linear_damp = initial_linear_damp

	# Create and apply PhysicsMaterial for friction
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = initial_friction
	physics_material_override = physics_material

func _on_reset_level(active_checkpoint_id: int) -> void:
	global_position = default_global_position
	# NOTE: Using integer value for mode due to a persistent parser error with the enum constant.
	# 0 = MODE_RIGID
	set("mode", 0)

func start_drag() -> void:
	# NOTE: Using integer value for mode due to a persistent parser error with the enum constant.
	# 3 = MODE_KINEMATIC
	set("mode", 3)

func stop_drag(release_velocity: Vector2) -> void:
	# NOTE: Using integer value for mode due to a persistent parser error with the enum constant.
	# 0 = MODE_RIGID
	set("mode", 0)
	apply_central_impulse(release_velocity)
