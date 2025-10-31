class_name PhysicsIntegrationSystem
extends Node

@export var player_character: CharacterBody2D


@export var _state_comp: MovementStateComponent
@export var _move_stats: MovementStats
@export var _jump_stats: JumpStats


var _move_input_vector: Vector2 = Vector2.ZERO
var _acceleration: float
var _deceleration: float
var _velocity: Vector2 = Vector2.ZERO
var _jump_count: int = 0

var _coyote_timer: Timer
var _buffer_timer: Timer

func _ready() -> void:
	if not (player_character and _state_comp):
		push_error("PhysicsIntegrationSystem: Dependencies are not set.")
		set_physics_process(false)

	
	# Create and configure timers
	_coyote_timer = Timer.new()
	_coyote_timer.name = "CoyoteTimer"
	_coyote_timer.one_shot = true
	add_child(_coyote_timer)

	_buffer_timer = Timer.new()
	_buffer_timer.name = "BufferTimer"
	_buffer_timer.one_shot = true
	add_child(_buffer_timer)  
	if _move_stats.time_to_reach_max_speed > 0:
		_acceleration = _move_stats.max_speed / _move_stats.time_to_reach_max_speed
	else:
		_acceleration = 9999 # Effectively instant

	if _move_stats.time_to_reach_zero_speed > 0:
		_deceleration = _move_stats.max_speed / _move_stats.time_to_reach_zero_speed
	else:
		_deceleration = 9999 # Effectively instant  

func _physics_process(_delta: float) -> void:
	# 1. Apply the calculated velocity from systems to the CharacterBody2D
	_update_jump_state()
	calculate_current_state()
	_apply_gravity()
	_execute_actions_for_current_state(_delta)
	player_character.velocity = _velocity
	player_character.move_and_slide()
	_velocity = player_character.velocity
	_state_comp.is_grounded = player_character.is_on_floor()
	_state_comp.is_on_wall = player_character.is_on_wall() and not _state_comp.is_grounded
	_state_comp.movement_vector = sign(_velocity)


func _execute_run(_delta:float):
	var target_speed: float = _move_input_vector.x *_move_stats.max_speed
	target_speed = target_speed * _move_stats.crouch_speed_multiplier if _state_comp.is_crouching   else target_speed

	var current_velocity_x = _velocity.x
	if _move_stats.directional_snap and _move_input_vector.x !=0 :
		current_velocity_x = target_speed
	elif target_speed != 0:
		# Accelerate towards target speed
		current_velocity_x = move_toward(current_velocity_x, target_speed, _acceleration * _delta)
	else:
		# Decelerate to zero
		current_velocity_x = move_toward(current_velocity_x, 0, _deceleration * _delta)
	_velocity.x = current_velocity_x

func _update_jump_state():
	if player_character.is_on_floor():
		_jump_count = _jump_stats.max_jumps
	if not _coyote_timer.is_stopped():
		_coyote_timer.stop()
		_coyote_timer.start(_jump_stats.coyote_time)  

func _execute_buffering_jump():
	if not _buffer_timer.is_stopped() and _can_jump():
		_state_comp.change_state(_state_comp.jumping)
	

func _execute_actions_for_current_state(_delta:float):
	# State priority: The first condition met determines the state.
	match _state_comp.current_state:
		_state_comp.jumping:
			request_jump()
		_state_comp.running,_state_comp.falling,_state_comp.crouching_run,_state_comp.idle,_state_comp.crouching_idle:
			_execute_run(_delta)
			
	
	
	
func calculate_current_state():
	_state_comp.is_grounded = player_character.is_on_floor()
	_state_comp.is_on_wall = player_character.is_on_wall() and not _state_comp.is_grounded
	if( not _state_comp.is_grounded and _velocity.y >= 0):
		_state_comp.change_state(_state_comp.falling)
	if(_state_comp.is_grounded&&_velocity==Vector2.ZERO):
			_state_comp.change_state(_state_comp.idle)
	if(_state_comp.is_grounded&&_velocity.x!=0):
			_state_comp.change_state(_state_comp.running)		
func _apply_gravity():
	#if _state_component.is_dashing or _state_component.is_latched:
	#	return
		
	var applied_gravity: float = _jump_stats.gravity_scale

	# Apply descending factor if falling
	if _velocity.y > 0:
		applied_gravity *= _jump_stats.descending_gravity_factor

	# Apply gravity
	_velocity.y += applied_gravity
	
	# Clamp to terminal velocity
	_velocity.y = min(_velocity.y, _jump_stats.terminal_velocity)


func _can_jump() -> bool:
	# Coyote time is only available for single jump configurations
	var use_coyote = (_jump_stats.max_jumps == 1 and not _coyote_timer.is_stopped())
	return _jump_count > 0 or use_coyote

func request_jump() -> void:
	if _can_jump():
		_execute_jump()
	elif _jump_stats.jump_buffering > 0:
		# If we can't jump now, buffer the input for a short time
		_buffer_timer.start(_jump_stats.jump_buffering)

func _execute_jump() -> void:
	# A tunable formula to get a jump velocity. 
	# This is not strictly physics-based but provides good game-feel control.
	var jump_velocity = -_jump_stats.jump_height * _jump_stats.gravity_scale * 5.0
	
	_velocity.y = jump_velocity
	_jump_count -= 1
	_state_comp.change_state(_state_comp.jumping)
	# Consume timers immediately after use
	_coyote_timer.stop()
	_buffer_timer.stop()

#Character controller or ai controller should change movement vector
func _change_movement_vector(_new_movement_vector:Vector2):
	_move_input_vector = _new_movement_vector
