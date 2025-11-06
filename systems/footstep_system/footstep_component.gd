class_name FootstepComponent
extends Node

## Главный ресурс с данными о звуках шагов.
@export var audio_data: FootstepAudioData

## Узел, который определяет тип поверхности.
@export var surface_detector: SurfaceDetector

## Плеер для воспроизведения звуков.
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var current_surface_name: String = "default"

func _ready() -> void:
	if not audio_data:
		push_warning("FootstepAudioData resource not assigned to FootstepComponent.")

	if not surface_detector:
		push_warning("SurfaceDetector node not assigned to FootstepComponent.")
	else:
		# Подписываемся на изменение поверхности
		surface_detector.surface_changed.connect(_on_surface_changed)
		# Устанавливаем начальное значение
		current_surface_name = surface_detector.current_surface

	if not audio_player:
		push_error("AudioStreamPlayer node named 'AudioStreamPlayer' is missing as a child of FootstepComponent.")


## Вызывается из AnimationPlayer. action_index: 0 для ходьбы, 1 для бега.
func play_step(action_index: int = 0) -> void:
	if not audio_data or not audio_player:
		return

	# 1. Получаем профиль для текущей поверхности
	var surface_profile: FootstepSurfaceProfile = audio_data.surface_profiles.get(current_surface_name)
	if not surface_profile:
		# Если для этой поверхности нет профиля, используем профиль по умолчанию
		surface_profile = audio_data.surface_profiles.get("default")
		if not surface_profile:
			# Если нет даже профиля по умолчанию, выходим
			return

	# 2. Получаем коллекцию звуков для нужного действия (ходьба/бег)
	var collection: FootstepStreamCollection = surface_profile.get_collection_for_action(action_index)
	if not collection:
		return

	# 3. Получаем следующий случайный звук из коллекции
	var stream: AudioStream = collection.get_next_stream()
	if not stream:
		return

	# 4. Воспроизводим звук
	audio_player.stream = stream
	audio_player.play()


func _on_surface_changed(new_surface_name: String) -> void:
	current_surface_name = new_surface_name

func stop() -> void:
	if audio_player:
		audio_player.stop()
