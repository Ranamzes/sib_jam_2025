class_name StateComponent
extends Node

# Emitted when a major state changes, useful for animation and logic.
signal state_changed(previous_state: StringName, new_state: StringName)

var movement_vector:Vector2 = Vector2.ZERO
var is_grounded: bool = false
var is_on_wall: bool = false
var is_crouching: bool = false
var jumping: StringName = &"jumping"
var running: StringName = &"running"
var falling: StringName = &"falling"
var dashing: StringName = &"dashing"
var crouching_run: StringName = &"crouching_run"
var crouching_idle: StringName = &"crouching_idle"
var wall_sliding: StringName = &"wall_sliding"
var latching: StringName = &"latching"
var idle: StringName = &"idle"
# The single, authoritative state of the character
var current_state: StringName = &"idle"
var previous_state: StringName = &"idle"
func change_state(new_state: StringName)->void:

	if new_state == current_state:
		return
	state_changed.emit(current_state,new_state)
	previous_state = current_state
	current_state = new_state

func return_state_to_previous()->void:
	change_state(previous_state)
