class_name PlayerVisualController
extends Node

@onready var contour_sprite: AnimatedSprite2D = get_parent().get_node("ContourSprite")
@onready var eyes_sprite: AnimatedSprite2D = get_parent().get_node("EyesSprite")
@onready var color_sprite: AnimatedSprite2D = get_parent().get_node("ColorSprite")

func _process(delta: float) -> void:
	if not is_instance_valid(contour_sprite):
		return

	# Синхронизируем анимацию, кадр и отражение от ContourSprite к остальным
	if is_instance_valid(eyes_sprite):
		eyes_sprite.animation = contour_sprite.animation
		eyes_sprite.frame = contour_sprite.frame
		eyes_sprite.flip_h = contour_sprite.flip_h

	if is_instance_valid(color_sprite):
		color_sprite.animation = contour_sprite.animation
		color_sprite.frame = contour_sprite.frame
		color_sprite.flip_h = contour_sprite.flip_h