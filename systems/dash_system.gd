class_name DashSystem
extends Node

@export var player_character: CharacterBody2D

@export var _velocity_comp: VelocityComponent
@export var _state_comp: StateComponent
@export var _stats_comp: StatsComponent
@export var _action_input_comp: ActionInputComponent

var _dash_stats: DashStats
var _dash_count: int = 0
var _dash_timer: Timer
var _current_move_vector: Vector2 = Vector2.ZERO

func _ready() -> void:
    if not player_character:
        push_error("DashSystem: Player character node is not assigned."); set_physics_process(false); return

    if not (_velocity_comp and _state_comp and _stats_comp and _action_input_comp):
        push_error("DashSystem: Player is missing required components."); set_physics_process(false); return

    _dash_stats = _stats_comp.dash
    _action_input_comp.dash_requested.connect(_on_dash_requested)
    _action_input_comp.move_vector_changed.connect(_on_move_vector_changed)

    # Create and configure timer
    _dash_timer = Timer.new()
    _dash_timer.name = "DashTimer"
    _dash_timer.one_shot = true
    _dash_timer.timeout.connect(_end_dash)
    add_child(_dash_timer)

func _physics_process(_delta: float) -> void:
    if player_character.is_on_floor():
        _dash_count = _dash_stats.max_dashes
    
func _on_dash_requested() -> void:
    if _dash_count <= 0 or _state_comp.is_dashing:
        return

    _dash_count -= 1
    _state_comp.is_dashing = true
    
    var dash_speed = _stats_comp.movement.max_speed * _dash_stats.dash_length
    var dash_direction = _get_dash_direction()

    if dash_direction == Vector2.ZERO:
        _dash_count += 1 # Refund dash if no direction
        _state_comp.is_dashing = false
        return

    _velocity_comp.velocity = dash_direction * dash_speed
    
    # A simple fixed-time dash
    _dash_timer.start(0.15)

func _get_dash_direction() -> Vector2:
    var input_vector = _current_move_vector
    
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
    
    return Vector2.ZERO # No dash if no valid input for the chosen type

func _end_dash() -> void:
    _state_comp.is_dashing = false
    # Reset velocity to prevent sudden stop
    _velocity_comp.velocity = Vector2.ZERO

func _on_move_vector_changed(move_vector: Vector2) -> void:
    _current_move_vector = move_vector
