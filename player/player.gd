extends CharacterBody2D

# --- Dependencies ---
# Please assign the required nodes in the Inspector.
@export var footstep_component_path: NodePath
@export var surface_detector_path: NodePath

var footstep_component: FootstepComponent
var surface_detector: RayCast2D


func _ready() -> void:
	# Get the nodes from the assigned paths.
	footstep_component = get_node_or_null(footstep_component_path)
	surface_detector = get_node_or_null(surface_detector_path)

	if not footstep_component:
		push_error("Player: FootstepComponent node not assigned or found at path: %s" % footstep_component_path)
	if not surface_detector:
		push_error("Player: SurfaceDetector RayCast2D node not assigned or found at path: %s" % surface_detector_path)


func _physics_process(delta: float) -> void:
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
