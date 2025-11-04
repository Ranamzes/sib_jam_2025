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

var _footstep_event_instance: FmodEvent





func _ready() -> void:

	# Safety check to ensure the marker is assigned in the editor.

	if not _foot_marker_node:

		push_warning("Foot marker not assigned in FootstepComponent.")



	if is_instance_valid(footstep_data):

		_footstep_event_instance = FmodServer.create_event_instance(footstep_data.fmod_event_path)

	else:

		push_warning("FootstepData not assigned to FootstepComponent.")





func _exit_tree() -> void:

	if _footstep_event_instance and _footstep_event_instance.is_valid():

		_footstep_event_instance.stop(FmodServer.FMOD_STUDIO_STOP_IMMEDIATE)

		_footstep_event_instance.release()


## Call this method to stop the footstep sound when the character stops moving.
func stop() -> void:
	pass
	if _footstep_event_instance and _footstep_event_instance.is_valid():
		_footstep_event_instance.stop(FmodServer.FMOD_STUDIO_STOP_ALLOWFADEOUT)



## This function should be called from an AnimationPlayer track when a foot hits the ground.

## It now accepts a boolean to differentiate between walking and running.

func play_step(is_running: bool = false) -> void:

	if not _foot_marker_node:

		return



	_play_step_at_position(_foot_marker_node.global_position, is_running)





func _play_step_at_position(step_position: Vector2, is_running: bool) -> void:

	if not _footstep_event_instance or not _footstep_event_instance.is_valid():

		push_warning("Footstep event instance is not valid.")

		return



	# Find the correct surface parameter value from our data resource.

	var surface_value: float = 0.0 # Default value if no surface is found

	for surface_resource in footstep_data.surfaces:

		if surface_resource.surface_name == current_surface_name:

			surface_value = surface_resource.fmod_parameter_value

			break



	# Set the 2D position for panning

	_footstep_event_instance.set_2d_attributes(Transform2D(0.0, step_position))



	# Set the surface parameter

	_footstep_event_instance.set_parameter_by_name(footstep_data.fmod_surface_parameter_name, surface_value)



	# Set the is_running parameter (0.0 for walk, 1.0 for run)

	var running_value: float = 1.0 if is_running else 0.0

	_footstep_event_instance.set_parameter_by_name(footstep_data.fmod_is_running_parameter_name, running_value)



	# Start the event. Since we are reusing the instance, we don't release it here.

	# We just restart it on every step.

	_footstep_event_instance.start()
