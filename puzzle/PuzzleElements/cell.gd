extends Area2D
class_name Cell

@export var index: int = -1
var occupied = false 

func is_free():
	return not occupied

func occupy():
	occupied = true

func unoccupy():
	occupied = false
