class_name AudioStreamCollection
extends Resource

## Массив аудиопотоков для этой коллекции.
@export var streams: Array[AudioStream] = []

var _shuffled_indices: Array[int] = []
var _current_index: int = -1


## Возвращает следующий случайный аудиопоток из коллекции, избегая повторений.
## Когда все потоки будут воспроизведены, он снова перемешивает плейлист.
func get_next_stream() -> AudioStream:
	if streams.is_empty():
		return null

	# Если плейлист закончился или еще не создан, создаем его
	if _current_index >= streams.size() - 1 or _shuffled_indices.is_empty():
		_reshuffle()

	_current_index += 1
	var stream_index = _shuffled_indices[_current_index]
	return streams[stream_index]


func _reshuffle() -> void:
	print("Reshuffling footstep playlist...")
	_shuffled_indices.clear()
	_shuffled_indices.resize(streams.size())
	
	# Заполняем массив индексами [0, 1, 2, ...]
	for i in streams.size():
		_shuffled_indices[i] = i
	
	# Перемешиваем
	_shuffled_indices.shuffle()
	
	# Сбрасываем индекс
	_current_index = -1
