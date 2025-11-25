extends Control

var mode: String

func _ready():
	var board_scene = preload("res://scenes/Board.tscn")
	var board = board_scene.instantiate()
	
	# Apply the mode script
	if mode == "mine":
		board.set_script(load("res://scripts/MineBoard.gd"))
	elif mode == "standard":
		board.set_script(load("res://scripts/Board.gd"))
	else: 
		board.set_script(load("res://scripts/Board.gd"))
	
	$HBoxContainer.add_child(board)
	$HBoxContainer.move_child(board, 0)
