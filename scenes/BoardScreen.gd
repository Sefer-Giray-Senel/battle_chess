extends Control

var banner_top: Banner
var banner_bottom: Banner

var mode: String

var is_white: bool = true

func _ready():
	var board_scene = preload("res://scenes/Board.tscn")
	var board = board_scene.instantiate()
	
	var banner = preload("res://scenes/Banner.tscn")
	banner_top = banner.instantiate()
	banner_bottom = banner.instantiate()
	
	# Apply the mode script
	if mode == "mine":
		board.set_script(load("res://scripts/MineBoard.gd"))
	elif mode == "standard":
		board.set_script(load("res://scripts/Board.gd"))
	else: 
		board.set_script(load("res://scripts/Board.gd"))
	
	var container = $HBoxContainer/VBoxContainer
	container.add_child(banner_top)
	container.add_child(board)
	container.add_child(banner_bottom)
	#$HBoxContainer.move_child(board, 0)
	
	Lobby.connect("role_received", Callable(self, "_on_role_received"))

func _on_role_received(is_player_w: bool):
	is_white = is_player_w
	banner_top.is_white = not is_player_w
	banner_bottom.is_white = is_player_w
	if is_white:
		banner_bottom.update_player_info("White player")
		banner_top.update_player_info("Black player")
	else:
		banner_top.update_player_info("White player")
		banner_bottom.update_player_info("Black player")
		
