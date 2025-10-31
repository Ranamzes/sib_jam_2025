extends Node
class_name HealthComponent

signal died
signal health_changed(is_damage: bool)

@export var base_max_health: float = 10
var current_health
var max_health

func _ready():
	max_health = base_max_health
	current_health = max_health

func damage(damage_amount:float ):
	current_health = max(current_health-damage_amount, 0)
	health_changed.emit(true)
	Callable(check_death).call_deferred()


func increase_max_health_by_percent(percent: float, amount: int):
	increase_max_health(base_max_health*percent,amount)


func increase_max_health(increment: float,amount: int):
	max_health = base_max_health + increment * amount
	increase_health(increment)
	
	
func increase_health(increment: float):
	current_health += increment	
	health_changed.emit(false)
	
	
func get_health_percent() -> float:
	if max_health <= 0:
		return 0;
	return min(current_health/max_health, 1)

func check_death():
	if current_health == 0:
		died.emit()
		owner.queue_free()
