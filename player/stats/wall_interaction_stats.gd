class_name WallInteractionStats
extends Resource

@export_group("Wall Mechanics")
@export var can_wall_jump: bool = false
@export_range(0, 0.5) var input_pause_after_wall_jump: float = 0.1
@export_range(0, 90) var wall_kick_angle: float = 60.0
@export_range(1, 20) var wall_slide_gravity_dampen: float = 1.0
@export var can_wall_latch: bool = false
