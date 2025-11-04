extends Node
class_name PuzzleManager

var cells: Array[Cell] = []
var pieces: Array[PuzzlePiece] = []
var dragging = false
var game_over: bool = false
var noise = false
var restart = false

signal puzzle_complete

func _process(delta: float) -> void:
	if game_over == false or noise == true:
		for child in get_children():
			for sub_child in child.get_children():
				if sub_child is Cell:
					cells.append(sub_child)
				if sub_child is PuzzlePiece:
					var position: Vector2 = Vector2(randi_range(200, 1000), randi_range(100, 500))
					pieces.append(sub_child)
					sub_child.global_position = position
			if noise == false:
				set_process(false)

func find_cell(index: int):
	for cell in cells:
		if cell.index == index:
			return cell

func check_puzzle_done():
	for piece in pieces:
		if piece.index != piece.cell_index:
			return
	
	if game_over == false and noise == false:
		await get_tree().create_timer(1.0).timeout
		game_over = true
		noise = true
		set_process(true)
		#puzzle_complete.emit()
		print("done!")
		await get_tree().create_timer(1.5).timeout
		set_process(false)
		noise = false
		#await get_tree().create_timer(1.5).timeout
		var win_screen_scene = preload("res://puzzle/FinalScene.tscn")
		if win_screen_scene and game_over == true and restart == false:
			restart = true
			get_tree().change_scene_to_packed(win_screen_scene)	
		else:
			push_error("Failed to load win screen scene!")
