extends Area2D
class_name PuzzlePiece

@export var index: int = -1
var cell_index: int = -1

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

@onready var sprite2d: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export var puzzle_manager: PuzzleManager

#func _ready() -> void:
#	collision_shape.shape = shape
#	sprite2d.texture = sprite_texture

func _on_input_event(viewport, event, shape_idx):
	if puzzle_manager.game_over:
		return
	if puzzle_manager.dragging and dragging == false:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if cell_index != -1:
				var cell = puzzle_manager.find_cell(cell_index)
				cell.unoccupy()
				cell_index = -1

			puzzle_manager.dragging = true
			dragging = true
			z_index = 100
			drag_offset = global_position - get_global_mouse_position()
		else:
#			sprite2d.material.set("shader_parameter/shadow_offset", Vector2(0, 0))
			puzzle_manager.dragging = false
			dragging = false
			z_index = 0
			drop_piece()
			puzzle_manager.check_puzzle_done()
	elif event is InputEventMouseMotion and dragging:
		var new_pos: Vector2 = get_global_mouse_position() + drag_offset
#		sprite2d.material.set("shader_parameter/mouse_screen_pos", new_pos)
		handle_drag_animation()
		position = new_pos

func drop_piece() -> void:
	var overlapping_areas: Array[Area2D] = get_overlapping_areas()
	for cell in overlapping_areas:
		if cell.is_in_group("cell"):
			if cell.is_free():
				cell_index = cell.index
				cell.occupy()
				position = cell.global_position
				puzzle_manager.check_puzzle_done()
				return

func handle_drag_animation():
#	sprite2d.material.set("shader_parameter/shadow_offset", Vector2(10, -10))
	pass
func _on_mouse_exited() -> void:
	if dragging && puzzle_manager.dragging:
		puzzle_manager.dragging = false
		dragging = false
		z_index = 0
		drop_piece()
		puzzle_manager.check_puzzle_done()
