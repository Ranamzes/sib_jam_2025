class_name GravitySystem
extends Node


@export var _velocity_component: VelocityComponent
@export var _state_component: StateComponent
@export var _stats_component: StatsComponent

func _ready() -> void:

	

	if not (_velocity_component and _state_component and _stats_component):
		push_error("GravitySystem: Player is missing required components (Velocity, State, or Stats).")
		set_physics_process(false)

func _physics_process(_delta: float) -> void:
	# Do not apply gravity if player is dashing or latched on a wall
	if _state_component.is_dashing or _state_component.is_latched:
		return
		
	var stats: JumpStats = _stats_component.jump
	var applied_gravity: float = stats.gravity_scale

	# Apply descending factor if falling
	if _velocity_component.velocity.y > 0:
		applied_gravity *= stats.descending_gravity_factor

	# Apply gravity
	_velocity_component.velocity.y += applied_gravity
	
	# Clamp to terminal velocity
	_velocity_component.velocity.y = min(_velocity_component.velocity.y, stats.terminal_velocity)
