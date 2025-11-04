class_name DragComponent
extends Node

@export var iteraction_ray_cast: RayCast2D
@export var mov_state_comp: StateComponent
@export var drag_offset: Vector2 = Vector2(80, 0)

var dragged_item: MovableItem = null
var last_item_position: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(dragged_item):
		return

	# Continuously update the position of the kinematic body
	var player = get_parent().get_parent()
	var target_position = player.global_position + drag_offset * player.get_node("ContourSprite").scale.x
	dragged_item.global_position = dragged_item.global_position.lerp(target_position, 0.2)

func start_dragging_action() -> void:
	if iteraction_ray_cast.is_colliding():
		var collider = iteraction_ray_cast.get_collider()
		if collider and collider.is_in_group("druggable"):
			var item = collider as MovableItem
			if is_instance_valid(item):
				dragged_item = item
				dragged_item.start_drag()
				last_item_position = item.global_position
				mov_state_comp.change_state(mov_state_comp.pull)

func stop_dragging_action() -> void:
	if not is_instance_valid(dragged_item):
		return

	# Calculate release velocity to give it a little push
	var release_velocity = (dragged_item.global_position - last_item_position) / get_process_delta_time()
	dragged_item.stop_drag(release_velocity * 10) # Multiply for a better feel
	dragged_item = null
	mov_state_comp.return_state_to_previous()