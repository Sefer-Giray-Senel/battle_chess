extends Board
class_name MineBoard

var player_mines: Array[Vector2i] = []
var opponent_mines: Array[Vector2i] = []
var player_placed_num = 0

var MAX_MINES = 3

var is_placing_mines = false

func _ready():
	super()
	
	Lobby.connect("mine_placement_state", Callable(self, "on_mine_placement_state"))

func _create_move_generator():
	return MineMoves.new(board_state, white_turn, player_mines, opponent_mines)

func _on_move_received(packet):
	if player_placed_num < MAX_MINES:
		Lobby.mine_button_state.emit(false)
	
	super(packet)

func draw_new_visiuals(piece: String, tile: Node, row: int, col: int):
	if Vector2i(row, col) in player_mines:
		var sprite = TextureRect.new()
		sprite.texture = MOVE_DOT_TEXTURE
		sprite.modulate = Color(0, 0, 0)
		tile.add_child(sprite)
	
	super(piece, tile, row, col)

func on_mine_placement_state(is_placing: bool):
	is_placing_mines = is_placing
	if is_placing_mines:
		selected_tile = Vector2i(-1,-1)
		possible_moves = move_generator.get_possible_mine_tiles(is_player_white)
	else:
		possible_moves = []
	_update_board_display()

func process_input(row: int, col: int):
	if is_placing_mines:
		var from = Vector2i(-1, -1)
		var to = Vector2i(row, col)
		move_generator.make_move(from, to, "mine", "self")
		player_placed_num = player_placed_num + 1
		Lobby.mine_placement_state.emit(false)
		Lobby.mine_button_state.emit(true)
		send_move(from, to, "mine")
		change_turn()
		$PlayerTimer.stop()
		$OpponentTimer.start()
		#TODO highlight mine icon to indicate last move
		_update_board_display()
	else:
		super(row, col)

func after_move(from: Vector2i, to: Vector2i, opponent_move: bool):
	if from != Vector2i(-1,-1):
		last_move_from = from
		last_move_to = to
	else:
		last_move_from = Vector2i(-1, -1)
		last_move_to = Vector2i(-1, -1)
	if not opponent_move:
		selected_tile = Vector2i(-1,-1)
		possible_moves.clear()
	
	if opponent_move:
		if to in player_mines:
			var captured: String = board_state[to.x][to.y]
			board_state[to.x][to.y] = ""
			player_mines.erase(to)
			#TODO sound and visiual effects
			if captured.to_lower() == "k":
				game_over(opponent_move)
				return
			piece_captured.emit(captured, false)
			if move_generator.is_checkmate():
				game_over(opponent_move)
				return
			elif move_generator.is_in_check():
				return
	else:
		if to in opponent_mines:
			var captured: String = board_state[to.x][to.y]
			board_state[to.x][to.y] = ""
			opponent_mines.erase(to)
			#TODO sound and visiual effects
			if captured.to_lower() == "k":
				game_over(opponent_move)
				return
			piece_captured.emit(captured, true)
			if move_generator.is_checkmate():
				game_over(opponent_move)
				return
			elif move_generator.is_in_check():
				return
	
	change_turn()
	if move_generator.is_checkmate():
		game_over(!opponent_move)
	if opponent_move:
		$PlayerTimer.start()
		$OpponentTimer.stop()
	else:
		$PlayerTimer.stop()
		$OpponentTimer.start()

func send_move(from = Vector2i(-1,-1), to = Vector2i(-1,-1), special: String = "", payload: String= ""):
	Lobby.mine_button_state.emit(true)
	super(from, to, special, payload)

func _on_role_received(is_player_w: bool):
	super(is_player_w)

func _on_game_active():
	if is_player_white:
		Lobby.mine_button_state.emit(false)
	super()
