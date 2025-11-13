class_name SoundCollectionResource
extends Resource

## Массив аудиопотоков, из которых будет выбираться случайный.
@export var sounds: Array[AudioStream]

## Возвращает случайный аудиопоток из массива.
func get_random_stream() -> AudioStream:
	if sounds.is_empty():
		return null
	return sounds.pick_random()
