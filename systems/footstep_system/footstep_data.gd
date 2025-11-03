
class_name FootstepData
extends Resource

## The FMOD event path for the footstep sound.
## Example: "event:/Player/Footsteps"
@export var fmod_event_path: String

## The name of the FMOD parameter that controls the surface type.
## Example: &"Surface"
@export var fmod_surface_parameter_name: StringName

## The name of the FMOD parameter that distinguishes between walking and running.
## Example: &"is_running"
@export var fmod_is_running_parameter_name: StringName

## A list of all possible surfaces the character can walk on.
@export var surfaces: Array[AudioSurfaceResource]
