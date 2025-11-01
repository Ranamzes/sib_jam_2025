class_name AnimationSystem
extends Node

## The AnimationTree node that this system will control.
@export var animation_tree: AnimationTree
## The root node of the character, used for getting components.

## The visual part of the player that needs to be flipped.
@export var player_sprite: Node2D
@export var mov_state_comp: StateComponent

# A direct reference to the state machine playback for convenience.
var _state_machine

func _ready() -> void:
	if not (animation_tree and player_sprite ):
		push_error("AnimationSystem: Dependencies (AnimationTree, CharacterBody2D, Node2D sprite, State or Velocity) are not set.")
		set_process(false)
		return

	# This assumes the parameter path is "parameters/playback". 
	# This is the default for a new AnimationNodeStateMachine.
	_state_machine = animation_tree.get("parameters/playback")
	
	# Connect to the state change signal
	mov_state_comp.state_changed.connect(_on_state_changed)

func _on_state_changed(_previous_state: StringName, new_state: StringName) -> void:
	if _state_machine:
		_state_machine.travel(new_state)

func _process(_delta: float) -> void:
	# Only handle continuous parameter updates here
	var velocity = mov_state_comp.movement_vector
	
	# Blend positions are useful for blending between idle/run animations.
	animation_tree.set("parameters/speed/blend_position", abs(velocity.x))
	
	# Vertical velocity can be used to transition between jump/fall.
	animation_tree.set("parameters/y_velocity/blend_position", velocity.y)

	# --- Flip Sprite ---
	if abs(velocity.x) > 0.1:
		player_sprite.scale.x = sign(velocity.x) * abs(player_sprite.scale.x)
