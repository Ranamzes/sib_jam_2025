class_name SurfaceAudioProfile
extends Resource

## Коллекция звуков для ходьбы.
@export var walk_collection: AudioStreamCollection

## Коллекция звуков для бега.
@export var run_collection: AudioStreamCollection

## Возвращает коллекцию в зависимости от типа действия.
func get_collection_for_action(action_index: int) -> AudioStreamCollection:
	match action_index:
		0: # Walk
			return walk_collection
		1: # Run
			return run_collection
		_: # Default to walk
			push_warning("Invalid action index for footstep sound. Defaulting to 'walk'.")
			return walk_collection
