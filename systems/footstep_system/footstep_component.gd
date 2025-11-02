class_name FootstepComponent
extends Node

## The data resource containing FMOD event info and surface definitions.
@export var footstep_data: FootstepData

## Path to the Node2D marking the position of the footstep sound.
@export var foot_marker: NodePath

## This variable should be updated by an external surface detector (e.g., a RayCast script).
## It holds the name of the surface the character is currently on.
var current_surface_name: StringName = &"default"

@onready var _foot_marker_node: Node2D = get_node_or_null(foot_marker)


func _ready() -> void:
	# Safety check to ensure the marker is assigned in the editor.
	if not _foot_marker_node:
		push_warning("Foot marker not assigned in FootstepComponent.")


## This function should be called from an AnimationPlayer track when a foot hits the ground.
func play_step() -> void:
	if not _foot_marker_node:
		return

	_play_step_at_position(_foot_marker_node.global_position)


func _play_step_at_position(step_position: Vector2) -> void:
	if not is_instance_valid(footstep_data):
		push_warning("FootstepData not assigned to FootstepComponent.")
		return

	# Find the correct surface parameter value from our data resource.
	var surface_value: float = 0.0 # Default value if no surface is found
	for surface_resource in footstep_data.surfaces:
		if surface_resource.surface_name == current_surface_name:
			surface_value = surface_resource.fmod_parameter_value
			break

	# Create an FMOD event instance
	var event_instance: FmodEvent = FmodServer.create_event_instance(footstep_data.fmod_event_path)
	if not event_instance.is_valid():
		push_warning("Failed to create FMOD event instance for: %s" % footstep_data.fmod_event_path)
		return

	# Set the 2D position for panning
	event_instance.set_2d_attributes(Transform2D(0.0, step_position))

	# Set the surface parameter
	event_instance.set_parameter_by_name(footstep_data.fmod_surface_parameter_name, surface_value)
	
	# Start the event and release it immediately (making it a "one-shot")
	event_instance.start()
	event_instance.release()