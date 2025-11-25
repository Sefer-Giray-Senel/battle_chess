extends Control
class_name Board

const TILE_SIZE = 64
const SPRINT_SIZE = 16
const BOARD_SIZE = 8
const BLACK_TILE = Color(0.9, 0.85, 0.8)
const WHITE_TILE = Color(0.1, 0.3, 0.3)
const SELECTED_COLOR = Color(0.7, 0.9, 0.4)  # yellow-ish highlight
const POSSIBLE_COLOR = Color(0.4, 0.7, 0.3)
const PIECE_TYPES = ["k", "q", "b", "n", "r", "p"]

# Board state: empty = "", uppercase = white, lowercase = black
var board_state = [
	["r","n","b","q","k","b","n","r"],
	["p","p","p","p","p","p","p","p"],
	["","","","","","","",""],
	["","","","","","","",""],
	["","","","","","","",""],
	["","","","","","","",""],
	["P","P","P","P","P","P","P","P"],
	["R","N","B","Q","K","B","N","R"]
]

var tile_nodes := []       # 2D array of ColorRects
var selected_tile: Vector2i = Vector2i(-1, -1)  # row,col of selected piece
var possible_moves: Array[Vector2i] = []

var white_turn: bool = true
var is_player_white: bool = true

var piece_sheet: Texture2D

var move_generator := Moves.new(board_state, white_turn)

@onready var promotion_popup = preload("res://scenes/Popup.tscn").instantiate()

func _ready():
	add_child(promotion_popup)
	promotion_popup.hide()
	
	Lobby.connect("move_received", Callable(self, "_on_move_received"))
	Lobby.connect("role_received", Callable(self, "_on_role_received"))
	Lobby.connect("lobby_left", Callable(self, "_on_lobby_left"))
	
	piece_sheet = load("res://assets/pieces.png")
	var grid = $GridContainer
	tile_nodes.resize(BOARD_SIZE)
	for row in range(BOARD_SIZE):
		tile_nodes[row] = []
		for col in range(BOARD_SIZE):
			var tile = ColorRect.new()
			tile.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
			
			# Alternate tile colors
			var is_light = (row + col) % 2 == 0
			tile.color = WHITE_TILE if is_light else BLACK_TILE
			
			tile.name = "Tile_%d_%d" % [row, col]
						
			# Connect click signal
			tile.connect("gui_input", Callable(self, "_on_tile_input").bind(row, col))
			
			grid.add_child(tile)
			tile_nodes[row].append(tile)
	_update_board_display()

func _on_role_received(is_player_w: bool):
	is_player_white = is_player_w
	_update_board_display()

# Handles tile clicks
func _on_tile_input(event: InputEvent, row: int, col: int):
	if event is InputEventMouseButton and event.pressed:
		if !is_player_white:
			row = 7 - row
			col = 7 - col
		var piece = board_state[row][col]
		
		if selected_tile != Vector2i(-1,-1):
			var from = selected_tile
			var to = Vector2i(row,col)
			
			if to in possible_moves:
				if move_generator.is_promotion(from, to):
					var chosen = await promotion_popup.show_and_get_choice()
					print("promoted to ", chosen)
					chosen = chosen.to_upper() if white_turn else chosen
					move_generator.make_move(from, to, "promotion", chosen)
					send_move(from, to, "promotion", chosen)
				else:
					move_generator.make_move(from, to)
					send_move(from, to)
				white_turn = !white_turn
				selected_tile = Vector2i(-1,-1)
				possible_moves.clear()
				if move_generator.is_checkmate():
					print("game over")
			else:
				if piece != "" and _is_piece_turn(piece):
					selected_tile = Vector2i(row, col)
					possible_moves = move_generator.get_possible_legal_moves(row, col)
		else:
			if piece != "" and _is_piece_turn(piece):
				selected_tile = Vector2i(row, col)
				possible_moves = move_generator.get_possible_legal_moves(row, col)
		
		_update_board_display()

func send_move(from, to, special: String = "", payload: String= ""):
	var data = {
		"type": "move",
		"from": [from[0], from[1]],
		"to": [to[0], to[1]],
		"special": special,
		"payload": payload
	}
	var packet = JSON.stringify(data)
	Lobby.send_packet(packet)

func _on_move_received(packet):
	print("first", packet)
	var from = Vector2i(packet.from[0], packet.from[1])
	var to = Vector2i(packet.to[0], packet.to[1])
	move_generator.make_move(from, to, packet.special, packet.payload)
	print("second", packet)
	white_turn = !white_turn
	_update_board_display()

func _is_piece_turn(piece: String) -> bool:
	var is_white = piece == piece.to_upper()
	return (is_white and white_turn and is_player_white) or (!is_white and !white_turn and !is_player_white)

func _update_board_display():
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			_update_tile_visual(row, col)

func _update_tile_visual(row: int, col: int):
	var grid = $GridContainer
	var tile = grid.get_node("Tile_%d_%d" % [row, col])
	var piece = ""
	if !is_player_white:
			row = 7 - row
			col = 7 - col
	piece = board_state[row][col]
	
	# Base tile color (light/dark)
	var is_light = (row + col) % 2 == 0
	var base_color = WHITE_TILE if is_light else BLACK_TILE
	
	# Highlights
	var blend_strength := 0.7  # 0 = only base, 1 = only highlight
	if selected_tile == Vector2i(row, col):
		tile.color = SELECTED_COLOR
	elif Vector2i(row, col) in possible_moves:
		tile.color = base_color.lerp(POSSIBLE_COLOR, blend_strength)
	else:
		tile.color = base_color
	
	# Remove any previous piece visuals
	for child in tile.get_children():
		child.queue_free()

	# Draw piece if present
	if piece != "":
		var sprite = TextureRect.new()
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		sprite.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sprite.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sprite.custom_minimum_size = Vector2(TILE_SIZE, TILE_SIZE)
		# Use the helper to get correct subtexture
		sprite.texture = get_piece_texture(piece)

		tile.add_child(sprite)

func get_piece_texture(piece: String) -> Texture2D:
	if piece == null:
		return null

	var color_index = 1 if piece == piece.to_upper() else 0
	var type_index = PIECE_TYPES.find(piece.to_lower())
	if type_index == -1 or color_index == -1:
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = piece_sheet
	atlas.region = Rect2(type_index * SPRINT_SIZE, color_index * SPRINT_SIZE, SPRINT_SIZE, SPRINT_SIZE)
	return atlas
