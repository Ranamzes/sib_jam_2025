@tool
class_name FootstepComponent
extends Node

## Главный ресурс с данными о звуках шагов.
@export var audio_data: FootstepAudioData

@onready var surface_detector: SurfaceDetector = $SurfaceDetector
@onready var foot_marker: Marker2D = $FootMarker
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var current_surface_name: String = "default"

func _enter_tree():
	if Engine.is_editor_hint():
		# Ensure required child nodes exist when added in the editor
		_ensure_child_node("AudioStreamPlayer2D", "AudioStreamPlayer2D")
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
		push_error("Child node 'AudioStreamPlayer2D' not found in FootstepComponent.")
	else:
		# Disable distance attenuation to keep volume constant, but preserve panning.
		audio_player.attenuation = 0


## Вызывается из AnimationPlayer. action_index: 0 для ходьбы, 1 для бега.
func play_step(action_index: int = 0) -> void:
	if not audio_data or not audio_player or not foot_marker:
		return

	var surface_profile: FootstepSurfaceProfile = audio_data.surface_profiles.get(current_surface_name)
	if not surface_profile:
		surface_profile = audio_data.surface_profiles.get("default")
		if not surface_profile:
			return

	var collection: FootstepStreamCollection = surface_profile.get_collection_for_action(action_index)
	if not collection:
		return

	var stream: AudioStream = collection.get_next_stream()
	if not stream:
		return

	# Set the sound's position to the foot's exact position for precise panning,
	# only if it has changed.
	if audio_player.global_position != foot_marker.global_position:
		audio_player.global_position = foot_marker.global_position
	
	# Play the sound
	audio_player.stream = stream
	audio_player.play()


func _on_surface_changed(new_surface_name: String) -> void:
	current_surface_name = new_surface_name

func stop() -> void:
	if audio_player:
		audio_player.stop()