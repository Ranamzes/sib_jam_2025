class_name MovementStats
extends Resource

@export_group("Horizontal Movement")
@export_range(50, 500) var max_speed: float = 200.0
@export_range(1, 5) var run_multiplier: float = 1.5
@export_range(0, 4) var time_to_reach_max_speed: float = 0.2
@export_range(0, 4) var time_to_reach_zero_speed: float = 0.2
@export var directional_snap: bool = false
