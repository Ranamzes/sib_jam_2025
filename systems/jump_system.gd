class_name JumpSystem
extends Node

@export var player_character: CharacterBody2D

@export var _velocity_comp: VelocityComponent
@export var _state_comp: StateComponent
@export var _stats_comp: StatsComponent
@export var _action_input_comp: ActionInputComponent

var _jump_stats: JumpStats
var _jump_count: int = 0

var _coyote_timer: Timer
var _buffer_timer: Timer

func _ready() -> void:
    if not player_character:
        push_error("JumpSystem: Player character node is not assigned."); set_physics_process(false); return
    
    if not (_velocity_comp and _state_comp and _stats_comp and _action_input_comp):
        push_error("JumpSystem: Player is missing required components."); set_physics_process(false); return

    _jump_stats = _stats_comp.jump
    _action_input_comp.jump_requested.connect(_on_jump_requested)

    # Create and configure timers
    _coyote_timer = Timer.new()
    _coyote_timer.name = "CoyoteTimer"
    _coyote_timer.one_shot = true
    add_child(_coyote_timer)

    _buffer_timer = Timer.new()
    _buffer_timer.name = "BufferTimer"
    _buffer_timer.one_shot = true
    add_child(_buffer_timer)

func _physics_process(_delta: float) -> void:
    # Replenish jumps on floor. We use the body's state directly for robustness.
    if player_character.is_on_floor():
        _jump_count = _jump_stats.max_jumps
        if not _coyote_timer.is_stopped():
            _coyote_timer.stop()
        _coyote_timer.start(_jump_stats.coyote_time)
    
    # Execute a buffered jump if we just landed
    if not _buffer_timer.is_stopped() and _can_jump():
        _execute_jump()

func _can_jump() -> bool:
    # Coyote time is only available for single jump configurations
    var use_coyote = (_jump_stats.max_jumps == 1 and not _coyote_timer.is_stopped())
    return _jump_count > 0 or use_coyote

func _on_jump_requested() -> void:
    if _can_jump():
        _execute_jump()
    elif _jump_stats.jump_buffering > 0:
        # If we can't jump now, buffer the input for a short time
        _buffer_timer.start(_jump_stats.jump_buffering)

func _execute_jump() -> void:
    # A tunable formula to get a jump velocity. 
    # This is not strictly physics-based but provides good game-feel control.
    var jump_velocity = -_jump_stats.jump_height * _jump_stats.gravity_scale * 5.0
    
    _velocity_comp.velocity.y = jump_velocity
    _jump_count -= 1

    # Consume timers immediately after use
    _coyote_timer.stop()
    _buffer_timer.stop()
