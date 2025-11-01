class_name JumpStats
extends Resource

@export_group("Jumping and Gravity")
@export_range(0, 20) var jump_height: float = 2.0
@export_range(1, 4) var max_jumps: int = 1
@export_range(0, 100) var gravity_scale: float = 20.0
@export_range(0, 1000) var terminal_velocity: float = 500.0
@export_range(0.5, 3) var descending_gravity_factor: float = 1.3
@export var enable_short_hop: bool = true

@export_group("Assist Features")
@export_range(0, 0.5) var coyote_time: float = 0.2
@export_range(0, 0.5) var jump_buffering: float = 0.2
