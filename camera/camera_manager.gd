class_name CameraManager
extends Node

@export var player: Node2D
@export var tilemap: TileMapLayer
@export var noise_resource: PhantomCameraNoise2D
@export var pixel_perfect: bool = true
@export var smoothing: float = 5.0

var camera: Camera2D
var viewport_container: SubViewportContainer
var pcam: PhantomCamera2D

func _ready() -> void:
	# This path is more robust, assuming the scene structure is World -> SubViewportContainer -> SubViewport -> Main -> CameraManager
	var sub_viewport = get_parent().get_parent()
	if sub_viewport is SubViewport:
		viewport_container = sub_viewport.get_parent()
	
	# This assumes CameraManager and MainCamera are siblings under the 'Main' node.
	camera = get_parent().get_node_or_null("MainCamera")

	if not camera or not viewport_container:
		push_error("CameraManager could not find required nodes (Camera or ViewportContainer).")
		return
	
	EventBus.player_respawned.connect(_on_player_respawned)
	
	# Initial setup
	initialize_camera_target(player)

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	# --- ZOOM SNAPPING ---
	var snapped_zoom = camera.zoom
	snapped_zoom.x = round(camera.zoom.x * viewport_container.scale.x) / viewport_container.scale.x
	snapped_zoom.y = round(camera.zoom.y * viewport_container.scale.y) / viewport_container.scale.y
	camera.zoom = snapped_zoom

	# --- PIXEL PERFECT CORRECTION ---
	if pixel_perfect:
		var camera_pos = camera.global_position
		
		var snapped_pos = camera_pos.round() # Use round() for more stable snapping
		var offset = camera_pos - snapped_pos
		
		camera.global_position = snapped_pos
		
		if viewport_container:
			var base_pos = Vector2(-1, -1) * viewport_container.scale.x
			viewport_container.position = base_pos - offset * viewport_container.scale
	else:
		# If not pixel perfect, do nothing to the camera position, let PhantomCamera handle it.
		if viewport_container:
			# Just reset the container position.
			viewport_container.position = Vector2(-1, -1) * viewport_container.scale.x

func initialize_camera_target(target_player: Node2D) -> void:
	if not is_instance_valid(target_player):
		return
		
	player = target_player
	pcam = player.get_node_or_null("PhantomCamera2D")
	if not pcam:
		return

	pcam.priority = 1

	if tilemap:
		pcam.limit_target = tilemap.get_path()

	if noise_resource:
		pcam.noise = noise_resource

func _on_player_respawned(new_player_node: Node2D) -> void:
	initialize_camera_target(new_player_node)
