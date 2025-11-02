class_name DragComponent
extends Node

@export var iteraction_ray_cast: RayCast2D
@export var drag_impulse: int

@export var mov_state_comp: StateComponent

func drag() -> void:
	print_debug("dragging")
	print_debug(iteraction_ray_cast.is_colliding())
	if (iteraction_ray_cast.is_colliding() && iteraction_ray_cast.get_collider().is_in_group(GroupNames.druggable)) :
		iteraction_ray_cast.get_collider().apply_central_impulse(iteraction_ray_cast.get_collision_normal() * drag_impulse)

func _process(delta: float) -> void:
	if mov_state_comp == null :
		return

	# Only handle continuous parameter updates here
	var velocity = mov_state_comp.movement_vector
	
	
	# --- Flip Sprite ---
	if abs(velocity.x) > 0.1:
		if velocity.x > 0 :
			iteraction_ray_cast.rotation_degrees = 270
		else :
			iteraction_ray_cast.rotation_degrees = 90
	
