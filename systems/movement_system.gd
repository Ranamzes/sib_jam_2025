class_name MovementSystem
extends Node

@export var player_character: CharacterBody2D

@export var _velocity_component: VelocityComponent
@export var _stats_component: StatsComponent
@export var _action_input_component: ActionInputComponent
@export var _state_component: StateComponent

var _move_input_vector: Vector2 = Vector2.ZERO
var _acceleration: float
var _deceleration: float

func _ready() -> void:
	if not player_character:
		push_error("MovementSystem: Player character node is not assigned.")
		set_physics_process(false)
		return


	if not (_velocity_component and _stats_component and _action_input_component and _state_component):
		push_error("MovementSystem: Player is missing required components (Velocity, Stats, ActionInput, or State).")
		set_physics_process(false)
		return

	# Pre-calculate acceleration/deceleration
	var move_stats: MovementStats = _stats_component.movement
	if move_stats.time_to_reach_max_speed > 0:
		_acceleration = move_stats.max_speed / move_stats.time_to_reach_max_speed
	else:
		_acceleration = 9999 # Effectively instant

	if move_stats.time_to_reach_zero_speed > 0:
		_deceleration = move_stats.max_speed / move_stats.time_to_reach_zero_speed
	else:
		_deceleration = 9999 # Effectively instant

	_action_input_component.move_vector_changed.connect(_on_move_vector_changed)

func _on_move_vector_changed(move_vector: Vector2) -> void:
	_move_input_vector = move_vector

func _physics_process(delta: float) -> void:
	var move_stats: MovementStats = _stats_component.movement
	var target_speed: float = _move_input_vector.x * move_stats.max_speed

	var current_velocity_x = _velocity_component.velocity.x

	if move_stats.directional_snap and _move_input_vector.x != 0:
		current_velocity_x = target_speed
	elif target_speed != 0:
		# Accelerate towards target speed
		current_velocity_x = move_toward(current_velocity_x, target_speed, _acceleration * delta)
	else:
		# Decelerate to zero
		current_velocity_x = move_toward(current_velocity_x, 0, _deceleration * delta)
	
	_velocity_component.velocity.x = current_velocity_x
