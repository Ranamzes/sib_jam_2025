@tool
class_name FootstepComponent
extends Node

## Главный ресурс с данными о звуках шагов.
@export var audio_data: FootstepAudioData
## Определяет, насколько далеко от центра экрана звук будет панорамироваться на 100% при зуме = 1.0.
@export var pan_range: float = 640.0 # Половина стандартной ширины viewport (1280 / 2)

@onready var surface_detector: SurfaceDetector = $SurfaceDetector
@onready var foot_marker: Marker2D = $FootMarker
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

const PANNER_BUS_NAME: StringName = &"Footstep_Pan"
var _panner_bus_idx: int = -1
var _panner_effect_idx: int = -1

var current_surface_name: String = "default"

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_ensure_child_node("AudioStreamPlayer", "AudioStreamPlayer")
		_ensure_child_node("SurfaceDetector", "RayCast2D", "res://systems/footstep_system/surface_detector.gd")
		_ensure_child_node("FootMarker", "Marker2D")

func _ensure_child_node(node_name: String, node_type: String, script_path: String = ""):
	if not has_node(node_name):
		var new_node = ClassDB.instantiate(node_type)
		new_node.name = node_name
		add_child(new_node, true)
		if get_tree() and get_tree().edited_scene_root:
			new_node.owner = get_tree().edited_scene_root
		if not script_path.is_empty():
			new_node.set_script(load(script_path))

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# --- Настройка панорамирования ---
	_panner_bus_idx = AudioServer.get_bus_index(PANNER_BUS_NAME)
	if _panner_bus_idx != -1:
		# Находим индекс эффекта Panner на шине
		for i in range(AudioServer.get_bus_effect_count(_panner_bus_idx)):
			var effect: AudioEffect = AudioServer.get_bus_effect(_panner_bus_idx, i)
			if effect is AudioEffectPanner:
				_panner_effect_idx = i
				break
	if _panner_effect_idx == -1:
		push_warning("FootstepComponent: Could not find 'AudioEffectPanner' on bus '%s'." % PANNER_BUS_NAME)
	# --- Конец настройки ---

	if not audio_data:
		push_warning("FootstepAudioData resource not assigned to FootstepComponent.")

	if not surface_detector:
		push_warning("Child node 'SurfaceDetector' not found in FootstepComponent.")
	else:
		surface_detector.surface_changed.connect(_on_surface_changed)
		current_surface_name = surface_detector.current_surface

	if not foot_marker:
		push_warning("Child node 'FootMarker' not found in FootstepComponent.")

	if not audio_player:
		push_error("Child node 'AudioStreamPlayer' not found in FootstepComponent.")
	else:
		# Направляем звук в шину для панорамирования
		audio_player.bus = PANNER_BUS_NAME


## Вызывается из AnimationPlayer. action_index: 0 для ходьбы, 1 для бега.
func play_step(action_index: int = 0) -> void:
	if not audio_data or not audio_player or not foot_marker:
		return

	var surface_profile: SurfaceAudioProfile = audio_data.surface_profiles.get(current_surface_name)
	if not surface_profile:
		surface_profile = audio_data.surface_profiles.get("default")
		if not surface_profile:
			return

	var collection: AudioStreamCollection = surface_profile.get_collection_for_action(action_index)
	if not collection:
		return

	var stream: AudioStream = collection.get_next_stream()
	if not stream:
		return

	# --- Новая, более надежная логика панорамирования через шину ---
	if _panner_bus_idx != -1 and _panner_effect_idx != -1:
		var viewport: Viewport = get_viewport()
		var camera: Camera2D = viewport.get_camera_2d()
		if camera:
			# Используем центр видимого прямоугольника, а не позицию камеры.
			# Это "истинный" центр экрана для игрока, независимо от плагинов камеры.
			var view_center_x: float = viewport.get_visible_rect().get_center().x
			var offset_x: float = foot_marker.global_position.x - view_center_x

			# Учитываем зум камеры
			var pan_range_at_current_zoom: float = pan_range / camera.zoom.x
			var pan_value: float = clamp(offset_x / pan_range_at_current_zoom, -1.0, 1.0)

			# Получаем эффект с шины и устанавливаем его параметр
			var effect: AudioEffectPanner = AudioServer.get_bus_effect(_panner_bus_idx, _panner_effect_idx)
			if effect:
				effect.pan = pan_value

	# Play the sound
	audio_player.stream = stream
	audio_player.play()


func _on_surface_changed(new_surface_name: String) -> void:
	current_surface_name = new_surface_name

func stop() -> void:
	if audio_player:
		audio_player.stop()
