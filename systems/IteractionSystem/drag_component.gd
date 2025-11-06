class_name DragComponent
extends Node

@export var iteraction_ray_cast_path: NodePath
@export var mov_state_comp: StateComponent
var physics_system: PhysicsIntegrationSystem # No longer exported, will be fetched dynamically
@export var drag_offset: Vector2 = Vector2(80, 0)
@export var pull_lerp_speed: float = 15.0 # Separate lerp speed for pull
@export var push_lerp_speed: float = 15.0 # Separate lerp speed for push

@onready var player: CharacterBody2D = owner as CharacterBody2D
@onready var contour_sprite: AnimatedSprite2D = player.get_node("ContourSprite") if player else null
@onready var iteraction_ray_cast: RayCast2D = get_node(iteraction_ray_cast_path) if iteraction_ray_cast_path else null

var dragged_item: MovableItem = null

func _ready() -> void:
	call_deferred("_check_physics_system")

func _check_physics_system() -> void:
	var player_node = get_owner()
	if player_node:
		physics_system = player_node.get_node_or_null("Systems/PhysicsIntegrationSystem")

	if not physics_system:
		push_error("DragComponent: PhysicsIntegrationSystem is not set!")

func _physics_process(delta: float) -> void:
	if not player or not contour_sprite or not iteraction_ray_cast:
		return

	# Flip RayCast based on player's visual direction
	if contour_sprite.flip_h:
		iteraction_ray_cast.target_position.x = -abs(iteraction_ray_cast.target_position.x)
	else:
		iteraction_ray_cast.target_position.x = abs(iteraction_ray_cast.target_position.x)

	if not is_instance_valid(dragged_item):
		return

	# --- Position Update ---
	var target_x_offset = drag_offset.x
	if contour_sprite.flip_h:
		target_x_offset = -drag_offset.x

	var target_position = player.global_position + Vector2(target_x_offset, drag_offset.y)

	var current_lerp_speed: float
	if mov_state_comp.current_state == mov_state_comp.pull:
		current_lerp_speed = pull_lerp_speed
	else:
		current_lerp_speed = push_lerp_speed

	dragged_item.global_position = dragged_item.global_position.lerp(target_position, 1.0 - exp(-delta * current_lerp_speed))




func start_dragging_action() -> void:
	if not iteraction_ray_cast:
		return

	iteraction_ray_cast.force_raycast_update()
	if iteraction_ray_cast.is_colliding():
		var collider = iteraction_ray_cast.get_collider()
		if collider and collider.is_in_group("draggable"):
			var item = collider as MovableItem
			if is_instance_valid(item):
				dragged_item = item
				dragged_item.start_drag()
				# Initial state is pull, _physics_process will correct to push if needed
				mov_state_comp.change_state(mov_state_comp.pull)

func stop_dragging_action() -> void:
	if not is_instance_valid(dragged_item):
		return

	# Set release velocity to zero to prevent unpredictable impulse
	var release_velocity = Vector2.ZERO
	dragged_item.stop_drag(release_velocity)
	dragged_item = null

	# Revert to a neutral state, PhysicsIntegrationSystem will then determine the correct state (idle/walk)
	mov_state_comp.change_state(mov_state_comp.idle)
