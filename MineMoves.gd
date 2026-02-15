extends Moves
class_name MineMoves

var player_mines: Array[Vector2i]
var opponent_mines: Array[Vector2i]

func _init(board_state, white_turn_now, pm, om):
	player_mines = pm
	opponent_mines = om
	super(board_state, white_turn_now)

func make_move(from: Vector2i, to: Vector2i, special: String = "", payload: String = "") -> String:
	if special == "mine":
		if payload == "self":
			player_mines.append(to)
		else:
			opponent_mines.append(to)
		white_turn = !white_turn
		return ""
	else:
		return super(from, to, special, payload)

func get_possible_mine_tiles(is_player_white: bool) -> Array[Vector2i]:
	var furthest_row := -1
	
	if is_player_white:
		# Search from top to bottom
		for row in range(8):
			for col in range(8):
				var piece: String = board[row][col]
				if piece != "" and piece == piece.to_upper():
					furthest_row = row
					break
			if furthest_row != -1:
				break
		
		if furthest_row == -1:
			return []
		
		var result: Array[Vector2i] = []
		for row in range(furthest_row, 8):
			for col in range(8):
				var piece: String = board[row][col]
				if piece == "" or piece.to_upper() == piece:
					result.append(Vector2i(row, col))
		
		return result
	
	else:
		# Search from bottom to top
		for row in range(7, -1, -1):
			for col in range(8):
				var piece: String = board[row][col]
				if piece != "" and piece == piece.to_lower():
					furthest_row = row
					break
			if furthest_row != -1:
				break
		
		if furthest_row == -1:
			return []
		
		var result: Array[Vector2i] = []
		for row in range(0, furthest_row + 1):
			for col in range(8):
				var piece: String = board[row][col]
				if piece == "" or piece.to_lower() == piece:
					result.append(Vector2i(row, col))
		
		return result
