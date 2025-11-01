
#WIP: DOESNT WORK
class_name CrouchSystem
extends Node

@export var _action_input_comp: ActionInputComponent
@export var _state_comp: StateComponent
@export var _collider: CollisionShape2D

var _original_collider_height: float
var _original_collider_pos: Vector2

func _ready() -> void:
    if not (_action_input_comp and _state_comp and _collider):
        push_error("CrouchSystem: Dependencies are not set.")
        set_physics_process(false)
        return

    # Store original collider properties to restore them later
    _original_collider_height = _collider.shape.size.y
    _original_collider_pos = _collider.position
    _action_input_comp.crouch_started.connect(_on_crouch_started)
    _action_input_comp.crouch_stopped.connect(_on_crouch_stopped)

func _on_crouch_started() -> void:
    if not _state_comp.is_grounded:
        return
    
    _state_comp.is_crouching = true
    # Halve the collider height and adjust its position to keep it on the ground
    _collider.shape.size.y = _original_collider_height / 2
    _collider.position.y = _original_collider_pos.y + (_original_collider_height / 4)

func _on_crouch_stopped() -> void:
    _state_comp.is_crouching = false
    # Restore original collider shape
    _collider.shape.size.y = _original_collider_height
    _collider.position = _original_collider_pos
