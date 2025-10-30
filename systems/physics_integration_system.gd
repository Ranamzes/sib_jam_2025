class_name PhysicsIntegrationSystem
extends Node

@export var player_character: CharacterBody2D

@export var _velocity_comp: VelocityComponent
@export var _state_comp: StateComponent

func _ready() -> void:
    if not (player_character and _velocity_comp and _state_comp):
        push_error("PhysicsIntegrationSystem: Dependencies are not set.")
        set_physics_process(false)

func _physics_process(_delta: float) -> void:
    # 1. Apply the calculated velocity from systems to the CharacterBody2D
    player_character.velocity = _velocity_comp.velocity

    # 2. Execute the physics move
   # print("Applying velocity: ", player_character.velocity)
    player_character.move_and_slide()

    # 3. Update the velocity component with the result from the physics engine
    _velocity_comp.velocity = player_character.velocity

    # 4. Update the boolean state flags
    _state_comp.is_grounded = player_character.is_on_floor()
    _state_comp.is_on_wall = player_character.is_on_wall()
    _state_comp.is_jumping = not _state_comp.is_grounded and _velocity_comp.velocity.y < 0
    _state_comp.is_falling = not _state_comp.is_grounded and _velocity_comp.velocity.y > 0

    # 5. Determine the new primary state and emit the signal if it changed
    var new_state = _determine_primary_state()
    if new_state != _state_comp.current_state:
        _state_comp.state_changed.emit(_state_comp.current_state, new_state)
        _state_comp.current_state = new_state

func _determine_primary_state() -> StringName:
    # State priority: The first condition met determines the state.
    if _state_comp.is_dashing:
        return &"dash"
    if _state_comp.is_latched:
        return &"latch"
    if _state_comp.is_on_wall and not _state_comp.is_grounded:
        return &"wall_slide"
    if _state_comp.is_jumping:
        return &"jump"
    if _state_comp.is_falling:
        return &"fall"
    if _state_comp.is_grounded:
        if abs(_velocity_comp.velocity.x) > 0.1:
            return &"run"
        else:
            return &"idle"
    
    return &"idle" # Fallback state
