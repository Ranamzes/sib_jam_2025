class_name AnimationSystem
extends Node

@export var animation_tree: AnimationTree
@export var mov_state_comp: StateComponent

@export_group("Sprites")
@export var contour_sprite: AnimatedSprite2D
@export var eyes_sprite: AnimatedSprite2D
@export var color_sprite: AnimatedSprite2D

var _state_machine

func _ready() -> void:
	if not (animation_tree and contour_sprite and mov_state_comp):
		push_error("AnimationSystem: Core dependencies are not set.")
		set_process(false)
		return

	_state_machine = animation_tree.get("parameters/playback")
	mov_state_comp.state_changed.connect(_on_state_changed)

func _on_state_changed(_previous_state: StringName, new_state: StringName) -> void:
	if _state_machine:
		_state_machine.travel(new_state)

func _process(_delta: float) -> void:
	var velocity: Vector2 = mov_state_comp.movement_vector
	
	animation_tree.set("parameters/speed/blend_position", abs(velocity.x))
	animation_tree.set("parameters/y_velocity/blend_position", velocity.y)

	# --- Flip Sprites ---
	if abs(velocity.x) > 0.1:
		var flip = velocity.x < 0
		contour_sprite.flip_h = flip

	# --- Sync Sprites ---
	# The AnimationTree only drives the contour_sprite.
	# We copy its state to the other sprites to keep them in sync.
	if is_instance_valid(eyes_sprite):
		eyes_sprite.animation = contour_sprite.animation
		eyes_sprite.frame = contour_sprite.frame
		eyes_sprite.flip_h = contour_sprite.flip_h

	if is_instance_valid(color_sprite):
		color_sprite.animation = contour_sprite.animation
		color_sprite.frame = contour_sprite.frame
		color_sprite.flip_h = contour_sprite.flip_h