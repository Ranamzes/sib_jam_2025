extends CharacterBody2D

# --- Dependencies ---
# These will be fetched dynamically.
var footstep_component: FootstepComponent
var surface_detector: RayCast2D


func _ready() -> void:
	call_deferred("_init_dependencies")

func _init_dependencies() -> void:
	var player_node = get_owner()
	if player_node:
		footstep_component = get_node_or_null("Components/FootstepComponent")
		surface_detector = get_node_or_null("Components/FootstepComponent/SurfaceDetector")

	if not footstep_component:
		push_error("Player: FootstepComponent node not found at path: Components/FootstepComponent")
	if not surface_detector:
		push_error("Player: SurfaceDetector RayCast2D node not found at path: Components/FootstepComponent/SurfaceDetector")


func _physics_process(_delta: float) -> void:
	_update_surface_detection()


func _update_surface_detection() -> void:
	# Ensure both the component and the detector are ready.
	if not footstep_component or not surface_detector:
		return

	# Check if the raycast is colliding with something.
	if surface_detector.is_colliding():
		var collider: Object = surface_detector.get_collider()

		# We need to find a surface name. We'll check the collider's groups.
		var detected_surface: StringName = &"default" # Fallback surface

		# We iterate through the groups of the collider to find a match
		# with the surfaces defined in our FootstepData.
		if collider and footstep_component.footstep_data:
			for surface_resource in footstep_component.footstep_data.surfaces:
				if collider.is_in_group(surface_resource.surface_name):
					detected_surface = surface_resource.surface_name
					break # Found a match, no need to check further.

		# Update the component with the detected surface.
		footstep_component.current_surface_name = detected_surface
	else:
		# If not colliding with anything (e.g., in the air),
		# we can set it to a default or "air" surface.
		footstep_component.current_surface_name = &"default"
