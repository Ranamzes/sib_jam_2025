class_name EchoComponent
extends Node2D
var _lifetime_timer:Timer
var _decay_timer:Timer
@export var _echo_stats: EchoStats
@onready var _point_light_2d: PointLight2D = get_node("%PointLight2D")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_lifetime_timer= Timer.new()
	_lifetime_timer.name ="EchoLifetimeTimer"
	_lifetime_timer.one_shot = true
	_lifetime_timer.timeout.connect(_on_life_timer_timeout)
	add_child(_lifetime_timer)
	
	_decay_timer= Timer.new()
	_decay_timer.name ="EchoDecayTimer"
	_decay_timer.one_shot = true
	_decay_timer.timeout.connect(_on_decay_timer_timeout)
	add_child(_decay_timer)
	
	_point_light_2d.scale = Vector2.ZERO
	_lifetime_timer.start(_echo_stats.life_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !_lifetime_timer.is_stopped():
		_point_light_2d.scale = _point_light_2d.scale.move_toward(_echo_stats.max_size * Vector2.ONE, delta *_echo_stats.speed * 5)
		return
	if !_decay_timer.is_stopped():
		_point_light_2d.energy = max(0, _point_light_2d.energy - _echo_stats.decay_rate * delta)

func _on_life_timer_timeout():
	_decay_timer.start(_point_light_2d.energy / _echo_stats.decay_rate)	

func _on_decay_timer_timeout():
	queue_free()
