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
				var position: Vector2 = Vector2(randi_range(200, 1000), randi_range(100, 500))
				pieces.append(sub_child)
				sub_child.global_position = position
			
		set_process(false)

func find_cell(index: int):
	for cell in cells:
		if cell.index == index:
			return cell

func check_puzzle_done():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	game_over = true
	puzzle_complete.emit()
	print("done!")
