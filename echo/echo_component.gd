class_name EchoComponent
extends Node2D
var _lifetime_timer:Timer
@export var echo_stats: EchoStats
@onready var _point_light_2d: PointLight2D = get_node("%PointLight2D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_lifetime_timer= Timer.new()
	_lifetime_timer.name ="EchoLifetimeTimer"
	_lifetime_timer.one_shot = true
	_lifetime_timer.timeout.connect(_on_life_timer_timeout)
	add_child(_lifetime_timer)
	_point_light_2d.scale = Vector2.ZERO
	_lifetime_timer.start(echo_stats.life_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_point_light_2d.scale = _point_light_2d.scale.move_toward(echo_stats.max_size*Vector2.ONE,delta *echo_stats.speed*5)

func _on_life_timer_timeout():
	queue_free()
	pass

func start_lifetime_timer():
	pass
