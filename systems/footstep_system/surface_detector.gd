class_name SurfaceDetector
extends RayCast2D

## Текущая определенная поверхность.
signal surface_changed(surface_name: String)

@export var current_surface: String = "default":
	set = set_current_surface

func _physics_process(delta: float) -> void:
	if is_colliding():
		var collider = get_collider()
		var new_surface = "default"

		if collider is TileMap:
			var collision_point = get_collision_point()
			var local_collision_point = collider.to_local(collision_point)
			var tile_coords = collider.local_to_map(local_collision_point)
			var tile_data = collider.get_cell_tile_data(0, tile_coords) # Assuming layer 0 for now

			if tile_data and tile_data.has_meta("surface_type"):
				new_surface = tile_data.get_meta("surface_type")
		else:
			# Fallback to checking collider's metadata if not a TileMap or tile metadata not found
			if collider.has_meta("surface_type"):
				new_surface = collider.get_meta("surface_type")
		
		if new_surface != current_surface:
			self.current_surface = new_surface

func set_current_surface(new_surface: String) -> void:
	if current_surface != new_surface:
		current_surface = new_surface
		emit_signal("surface_changed", current_surface)
		print("Surface changed to: %s" % current_surface)
