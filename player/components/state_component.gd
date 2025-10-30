class_name StateComponent
extends Node

# Emitted when a major state changes, useful for animation and logic.
signal state_changed(previous_state: StringName, new_state: StringName)

# The single, authoritative state of the character
var current_state: StringName = &"idle"

# Core states
var is_grounded: bool = false
var is_on_wall: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var is_dashing: bool = false
var is_crouching: bool = false
var is_latched: bool = false
