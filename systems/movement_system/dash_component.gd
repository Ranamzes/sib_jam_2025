class_name DashComponent
extends Node




@export var _state_comp: StateComponent
@export var _dash_stats: DashStats
@export var _movement_stats: MovementStats
@export var _physics: PhysicsIntegrationSystem


var _dash_count: int = 0
var _dash_timer: Timer

func _ready() -> void:

	if not (_state_comp and _dash_stats and _movement_stats and _physics):
		push_error("DashComponent: Player is missing required components."); set_physics_process(false); return

	# Create and configure timer
	_dash_timer = Timer.new()
	_dash_timer.name = "DashTimer"
	_dash_timer.one_shot = true
	_dash_timer.timeout.connect(_end_dash)
	add_child(_dash_timer)

func _physics_process(_delta: float) -> void:
	if _state_comp.is_grounded:
		_dash_count = _dash_stats.max_dashes
	if _state_comp.current_state == _state_comp.dashing and _state_comp.is_on_wall:
		_end_dash()   
	
func request_dash() -> void:
	if _dash_count <= 0 or _state_comp.current_state == _state_comp.dashing:
		return

	var dash_direction = _get_dash_direction()

	if dash_direction == Vector2.ZERO:
		return # Do not dash if there is no direction

	_dash_count -= 1
	_state_comp.change_state(_state_comp.dashing)
	
	var dash_speed = _movement_stats.max_speed * _dash_stats.dash_length
	
	_physics.change_velocity(dash_direction * dash_speed)
	
	# A simple fixed-time dash
	_dash_timer.start(_dash_stats.dash_time)


func _get_dash_direction() -> Vector2:
	var input_vector = _physics.get_move_input_vector()

	# Prioritize player input for dash direction
	if input_vector != Vector2.ZERO:
		match _dash_stats.dash_type:
			1: # Horizontal
				if input_vector.x != 0:
					return Vector2(sign(input_vector.x), 0)
			2: # Vertical
				if input_vector.y != 0:
					return Vector2(0, sign(input_vector.y))
			3: # Four Way (digital)
				if abs(input_vector.x) > abs(input_vector.y):
					return Vector2(sign(input_vector.x), 0)
				elif input_vector.y != 0:
					return Vector2(0, sign(input_vector.y))
			4: # Eight Way (analog)
				return input_vector.normalized()
		return Vector2.ZERO # Should not be reached if input is not zero, but as a fallback

	# If no input, use current horizontal velocity for a momentum dash
	var current_velocity = _physics.get_current_velocity()
	if abs(current_velocity.x) > 0.1: # Use a small threshold
		return Vector2(sign(current_velocity.x), 0)

	return Vector2.ZERO

func _end_dash()->void:

	_state_comp.return_state_to_previous()
	# Reset velocity to prevent sudden stop
	_physics.change_velocity(Vector2.ZERO)
	_dash_timer.stop()
