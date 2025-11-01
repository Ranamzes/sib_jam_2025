class_name MovementStats
extends Resource

@export_group("Horizontal Movement")
@export_range(50, 500) var max_speed: float = 200.0
@export_range(0, 4) var time_to_reach_max_speed: float = 0.2
@export_range(0, 4) var time_to_reach_zero_speed: float = 0.2
@export var directional_snap: bool = false
@export_range(0.1, 1.0) var crouch_speed_multiplier: float = 0.5
