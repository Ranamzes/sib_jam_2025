class_name DragComponent
extends Node

@export var iteraction_ray_cast: RayCast2D
@export var drag_impulse: int
@export var push_impulse: int
@export var mov_state_comp: StateComponent


func push() -> void:
	if (iteraction_ray_cast.is_colliding() && iteraction_ray_cast.get_collider().is_in_group(GroupNames.druggable)) :
		if iteraction_ray_cast.global_position.distance_squared_to(iteraction_ray_cast.get_collision_point()) > 100 :
			if(mov_state_comp.current_state!=mov_state_comp.pull):
				mov_state_comp.change_state(mov_state_comp.push)

func drag() -> void:
	if (iteraction_ray_cast.is_colliding() && iteraction_ray_cast.get_collider().is_in_group(GroupNames.druggable)) :
		if iteraction_ray_cast.global_position.distance_squared_to(iteraction_ray_cast.get_collision_point()) > 100 :
			if(mov_state_comp.current_state!=mov_state_comp.push):	
				mov_state_comp.change_state(mov_state_comp.pull)

func _process(_delta: float) -> void:
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

func execute_push():
	iteraction_ray_cast.get_collider().apply_central_impulse(iteraction_ray_cast.get_collision_normal() * -push_impulse)

func execute_pull():
	iteraction_ray_cast.get_collider().apply_central_impulse(iteraction_ray_cast.get_collision_normal() * drag_impulse)