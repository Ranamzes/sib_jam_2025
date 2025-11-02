extends Node
class_name PuzzleManager

var cells: Array[Cell] = []
var pieces: Array[PuzzlePiece] = []
var dragging = false
var game_over: bool = false

signal puzzle_complete

func _process(delta: float) -> void:
	for child in get_children():
		for sub_child in child.get_children():
			if sub_child is Cell:
				cells.append(sub_child)
			if sub_child is PuzzlePiece:
				var position: Vector2 = Vector2(randi_range(-30, 30), randi_range(-30, 30))
				pieces.append(sub_child)
				sub_child.position = position
			
		set_process(false)

func find_cell(index: int):
	for cell in cells:
		if cell.index == index:
			return cell

func check_win():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	puzzle_complete.emit()
