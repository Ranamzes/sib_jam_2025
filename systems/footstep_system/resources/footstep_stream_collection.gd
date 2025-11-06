class_name FootstepStreamCollection
extends Resource

@export var streams: Array[AudioStream]

var last_stream_index: int = -1

func get_next_stream() -> AudioStream:
	if streams.is_empty():
		return null

	var next_index: int
	if streams.size() == 1:
		next_index = 0
	else:
		next_index = randi() % streams.size()
		if next_index == last_stream_index:
			next_index = (next_index + 1) % streams.size()
	
	last_stream_index = next_index
	return streams[next_index]
