class_name FootstepSurfaceProfile
extends Resource

@export var walk_collection: FootstepStreamCollection
@export var run_collection: FootstepStreamCollection

func get_collection_for_action(action_index: int) -> FootstepStreamCollection:
	if action_index == 1:
		return run_collection
	return walk_collection
