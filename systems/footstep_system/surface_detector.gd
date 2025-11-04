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

		# Проверяем, есть ли у коллайдера метаданные о поверхности
		if collider.has_meta("surface_type"):
			new_surface = collider.get_meta("surface_type")
		
		if new_surface != current_surface:
			self.current_surface = new_surface

func set_current_surface(new_surface: String) -> void:
	if current_surface != new_surface:
		current_surface = new_surface
		emit_signal("surface_changed", current_surface)
		print("Surface changed to: %s" % current_surface)
