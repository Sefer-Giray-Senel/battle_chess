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
	Lobby.connect("set_player_name", Callable(self, "_on_player_name"))
	Lobby.connect("set_player_image", Callable(self, "_on_player_image"))
	board.connect("timer_changed", Callable(self, "_on_timer_changed"))
	board.connect("piece_captured", Callable(self, "_on_piece_captured"))

func _on_role_received(is_player_w: bool):
	is_white = is_player_w
	banner_top.is_white = not is_player_w
	banner_bottom.is_white = is_player_w

func _on_timer_changed(new_time: int, is_player: bool):
	if is_player:
		banner_bottom.update_time(new_time)
	else:
		banner_top.update_time(new_time)

func _on_piece_captured(type: String, is_player: bool):
	if is_player:
		banner_top.add_captured_pieces(type)
	else:
		banner_bottom.add_captured_pieces(type)

func _on_player_name(player_name: String, is_opponent: bool):
	if is_opponent:
		banner_top.update_player_name(player_name)
	else:
		banner_bottom.update_player_name(player_name)

func _on_player_image(player_image: Texture, is_opponent: bool):
	if is_opponent:
		banner_top.update_player_photo(player_image)
	else:
		banner_bottom.update_player_photo(player_image)
