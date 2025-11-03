class_name DashStats
extends Resource

@export_group("Dashing")
@export_enum("None", "Horizontal", "Vertical", "Four Way", "Eight Way") var dash_type: int
@export_range(0, 10) var max_dashes: int = 1
@export var enable_dash_cancel: bool = true
@export_range(1.5, 4) var dash_length: float = 2.5
@export_range(0.05,1)var dash_time: float = 0.1
