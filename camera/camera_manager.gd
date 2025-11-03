class_name CameraManager
extends Node

@export var player: Node2D
@export var tilemap: TileMapLayer
@export var noise_resource: PhantomCameraNoise2D

func _ready() -> void:
	if not player:
		return

	var pcam: PhantomCamera2D = player.get_node_or_null("PhantomCamera2D")
	if not pcam:
		return

	pcam.priority = 1

	if tilemap:
		pcam.limit_target = tilemap.get_path()

	if noise_resource:
		pcam.noise = noise_resource