class_name FootstepStreamCollection
extends Resource

@export var streams: Array[AudioStream]

var _shuffled_indices: Array[int] = []
var _current_index: int = -1


# Returns the next random audio stream from the collection, avoiding repetition.
# When all streams have been played, it reshuffles the playlist.
func get_next_stream() -> AudioStream:
	if streams.is_empty():
		return null

	# If the playlist is finished or not yet created, create it
	if _current_index >= streams.size() - 1 or _shuffled_indices.is_empty():
		_reshuffle()

	_current_index += 1
	var stream_index = _shuffled_indices[_current_index]
	return streams[stream_index]


func _reshuffle() -> void:
	_shuffled_indices.clear()
	_shuffled_indices.resize(streams.size())
	
	# Fill the array with indices [0, 1, 2, ...]
	for i in streams.size():
		_shuffled_indices[i] = i
	
	# Shuffle
	_shuffled_indices.shuffle()
	
	# Reset index
	_current_index = -1