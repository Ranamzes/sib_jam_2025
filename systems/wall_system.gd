class_name WallSystem
extends Node

@export var player_character: CharacterBody2D

@export var _velocity_comp: VelocityComponent
@export var _state_comp: StateComponent
@export var _stats_comp: StatsComponent
@export var _action_input_comp: ActionInputComponent

var _jump_stats: JumpStats
var _wall_stats: WallInteractionStats
var _wall_jump_latch_lockout_timer: Timer
var _is_latch_input_pressed: bool = false

func _ready() -> void:
    if not (player_character and _velocity_comp and _state_comp and _stats_comp and _action_input_comp):
        push_error("WallSystem: Dependencies are not set."); set_physics_process(false); return

    _jump_stats = _stats_comp.jump
    _wall_stats = _stats_comp.wall
    _action_input_comp.jump_requested.connect(_on_jump_requested)
    _action_input_comp.latch_toggled.connect(_on_latch_toggled)

    _wall_jump_latch_lockout_timer = Timer.new()
    _wall_jump_latch_lockout_timer.name = "WallJumpLatchLockoutTimer"
    _wall_jump_latch_lockout_timer.one_shot = true
    add_child(_wall_jump_latch_lockout_timer)

func _on_latch_toggled(is_pressed: bool) -> void:
    _is_latch_input_pressed = is_pressed

func _physics_process(_delta: float) -> void:
    # Latch Logic: Use the signal-driven flag
    _state_comp.is_latched = _state_comp.is_on_wall and _is_latch_input_pressed and _wall_stats.can_wall_latch and _wall_jump_latch_lockout_timer.is_stopped()

    # If latched, immediately zero out vertical velocity to prevent flying upwards
    if _state_comp.is_latched:
        _velocity_comp.velocity.y = 0
        return # No further wall gravity/slide logic needed if latched

    # Wall Slide Gravity Logic (only if not latched and falling)
    if _state_comp.is_on_wall and _velocity_comp.velocity.y > 0:
        if _wall_stats.wall_slide_gravity_dampen > 1.0:
            _velocity_comp.velocity.y -= _stats_comp.jump.gravity_scale * (1.0 - 1.0 / _wall_stats.wall_slide_gravity_dampen)

func _on_jump_requested() -> void:
    # Only handle wall jump, regular jumps are handled by JumpSystem
    if _state_comp.is_on_wall and _wall_stats.can_wall_jump:
        _execute_wall_jump()

func _execute_wall_jump() -> void:
    var jump_velocity_base = -_jump_stats.jump_height * _jump_stats.gravity_scale * 5.0
    var wall_normal = player_character.get_wall_normal()

    var angle_rad = deg_to_rad(_wall_stats.wall_kick_angle)
    var vertical_kick = abs(jump_velocity_base * sin(angle_rad))
    var horizontal_kick = abs(jump_velocity_base * cos(angle_rad))

    print("Wall Jump Debug:")
    print("  wall_kick_angle:", _wall_stats.wall_kick_angle)
    print("  wall_normal:", wall_normal)
    print("  horizontal_kick:", horizontal_kick)
    print("  final velocity.x:", wall_normal.x * horizontal_kick)

    _velocity_comp.velocity.y = -vertical_kick
    _velocity_comp.velocity.x = wall_normal.x * horizontal_kick

    # Start lockout timer to prevent immediate re-latching
    _wall_jump_latch_lockout_timer.start(0.15) # 0.15 seconds lockout
