@tool
class_name MovementAudioComponent
extends Node

## Ресурс, содержащий коллекцию звуков для воспроизведения.
@export var sound_collection: SoundCollectionResource
## Минимальная скорость, при которой начинает воспроизводиться звук.
@export var velocity_threshold: float = 5.0

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var _parent_body: Node2D
var _selected_stream: AudioStream
var _is_playing: bool = false
var _last_position: Vector2 = Vector2.ZERO

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		if not has_node("AudioStreamPlayer2D"):
			var player = AudioStreamPlayer2D.new()
			player.name = "AudioStreamPlayer2D"
			add_child(player, true)
			if get_tree() and get_tree().edited_scene_root:
				player.owner = get_tree().edited_scene_root

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_parent_body = get_parent() as Node2D
	if not _parent_body:
		push_error("MovementAudioComponent must be a child of a Node2D.")
		return
	
	_last_position = _parent_body.global_position

	if not audio_player:
		push_error("MovementAudioComponent requires an AudioStreamPlayer2D child node.")
		return
		
	if not sound_collection:
		push_warning("SoundCollectionResource is not assigned to MovementAudioComponent.")
		return
		
	# Выбираем один случайный звук при запуске, чтобы он не менялся при каждом движении.
	_selected_stream = sound_collection.get_random_stream()
	
	# Устанавливаем зацикливание на самом ресурсе потока
	if _selected_stream:
		if _selected_stream.has_method("set_loop"):
			_selected_stream.set_loop(true) # Для AudioStreamWAV
		elif "loop" in _selected_stream:
			_selected_stream.loop = true # Для AudioStreamOGGVorbis
	else:
		push_warning("SoundCollectionResource returned a null stream for ", _parent_body.name)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_parent_body) or not _selected_stream:
		return

	# Рассчитываем скорость вручную, чтобы это работало независимо от режима физического тела (Rigid/Kinematic)
	var current_position = _parent_body.global_position
	var velocity_vector = (current_position - _last_position) / delta
	_last_position = current_position
	
	var current_velocity_length: float = velocity_vector.length()

	if current_velocity_length > velocity_threshold:
		if not _is_playing:
			_start_playing()
	else:
		if _is_playing:
			_stop_playing()

func _start_playing() -> void:
	audio_player.stream = _selected_stream
	audio_player.play()
	_is_playing = true

func _stop_playing() -> void:
	audio_player.stop()
	_is_playing = false
