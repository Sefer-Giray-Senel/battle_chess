# ChessMoveGenerator.gd
extends Node
class_name Moves

const BOARD_SIZE = 8

# Board is expected to be a 2D array of strings like your board_state
var board : Array
var white_turn : bool

var white_can_castle_kingside = true
var white_can_castle_queenside = true
var black_can_castle_kingside = true
var black_can_castle_queenside = true

var en_passant_target: Vector2i = Vector2i(-1, -1)  # The square behind the pawn that moved 2 steps
var en_passant_pawn: Vector2i = Vector2i(-1, -1)    # The pawn that can be captured

func _init(board_state, white_turn_now):
	board = board_state
	white_turn = white_turn_now

# Returns an array of Vector2i positions the piece at (row,col) can legally move to
func get_possible_moves(row: int, col: int) -> Array[Vector2i]:
	var piece = board[row][col]
	if piece == "":
		return []
	
	var moves: Array[Vector2i] = []	
	
	match piece.to_lower():
		"p":
			moves = _pawn_moves(row, col, piece == piece.to_upper())
		"r":
			moves = _rook_moves(row, col)
		"n":
			moves = _knight_moves(row, col)
		"b":
			moves = _bishop_moves(row, col)
		"q":
			moves = _queen_moves(row, col)
		"k":
			moves = _king_moves(row, col)
		_:
			moves = []
	
	return moves

# ===== Helper functions for each piece =====
func _pawn_moves(row: int, col: int, is_white: bool) -> Array[Vector2i]:
	var dir = -1 if is_white else 1
	var start_row = 6 if is_white else 1
	var moves: Array[Vector2i] = []
	
	# Forward one
	if _in_bounds(row+dir, col) and board[row+dir][col] == "":
		moves.append(Vector2i(row+dir, col))
		# Forward two from start
		if row == start_row and board[row+dir*2][col] == "":
			moves.append(Vector2i(row+dir*2, col))
	
	# Captures
	for dy in [-1, 1]:
		if _in_bounds(row+dir, col+dy):
			var target = board[row+dir][col+dy]
			if target != "" and ((target.to_upper() == target) != is_white):
				moves.append(Vector2i(row+dir, col+dy))
	
	# EN PASSANT CAPTURE
	var direction = -1 if is_white else 1
	if en_passant_target != Vector2i(-1, -1):
		# Only if the en passant target is diagonal from this pawn
		if abs(en_passant_target.y - col) == 1 and en_passant_target.x == row + direction:
			moves.append(en_passant_target)
	
	return moves

func _rook_moves(row: int, col: int) -> Array[Vector2i]:
	return _linear_moves(row, col, [[1,0], [-1,0], [0,1], [0,-1]])

func _bishop_moves(row: int, col: int) -> Array[Vector2i]:
	return _linear_moves(row, col, [[1,1], [1,-1], [-1,1], [-1,-1]])

func _queen_moves(row: int, col: int) -> Array[Vector2i]:
	return _linear_moves(row, col, [[1,0], [-1,0], [0,1], [0,-1], [1,1], [1,-1], [-1,1], [-1,-1]])

func _king_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var directions = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
	var is_white = board[row][col] == board[row][col].to_upper()
	for d in directions:
		var r = row + d[0]
		var c = col + d[1]
		if _in_bounds(r,c):
			var target = board[r][c]
			if target == "" or ((target.to_upper() == target) != is_white):
				moves.append(Vector2i(r,c))
	
	# Castling
	if not is_in_check():  # cannot castle while in check
		if is_white:
			# King must be at e1 = (7,4)
			if row == 7 and col == 4:
				# KING SIDE
				if white_can_castle_kingside:
					if board[7][5] == "" and board[7][6] == "":
						if not square_attacked(7,5,false) and not square_attacked(7,6,false):
							moves.append(Vector2i(7,6))
				# QUEEN SIDE
				if white_can_castle_queenside:
					if board[7][1] == "" and board[7][2] == "" and board[7][3] == "":
						if not square_attacked(7,3,false) and not square_attacked(7,2,false):
							moves.append(Vector2i(7,2))
		else:
			# Black king at e8 = (0,4)
			if row == 0 and col == 4:
				if black_can_castle_kingside:
					if board[0][5] == "" and board[0][6] == "":
						if not square_attacked(0,5,true) and not square_attacked(0,6,true):
							moves.append(Vector2i(0,6))
				if black_can_castle_queenside:
					if board[0][1] == "" and board[0][2] == "" and board[0][3] == "":
						if not square_attacked(0,3,true) and not square_attacked(0,2,true):
							moves.append(Vector2i(0,2))
	
	return moves

func _knight_moves(row: int, col: int) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var offsets = [[2,1],[1,2],[-1,2],[-2,1],[-2,-1],[-1,-2],[1,-2],[2,-1]]
	var is_white = board[row][col] == board[row][col].to_upper()
	for o in offsets:
		var r = row + o[0]
		var c = col + o[1]
		if _in_bounds(r,c):
			var target = board[r][c]
			if target == "" or ((target.to_upper() == target) != is_white):
				moves.append(Vector2i(r,c))
	return moves

# ===== Linear moves helper =====
func _linear_moves(row: int, col: int, directions: Array) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var is_white = board[row][col] == board[row][col].to_upper()
	for dir in directions:
		var r = row + dir[0]
		var c = col + dir[1]
		while _in_bounds(r,c):
			var target = board[r][c]
			if target == "":
				moves.append(Vector2i(r,c))
			elif (target.to_upper() == target) != is_white:
				moves.append(Vector2i(r,c))
				break
			else:
				break
			r += dir[0]
			c += dir[1]
	return moves

func _in_bounds(row:int, col:int) -> bool:
	return row >= 0 and row < BOARD_SIZE and col >= 0 and col < BOARD_SIZE

func is_in_check() -> bool:
	var king_pos: Vector2i = find_king()
	
	for row in range(board.size()):
		for col in range(board[row].size()):
			var piece = board[row][col]
			if piece != "" and piece.to_lower() != "k" and (piece.to_upper() == piece) != white_turn:
				var moves = get_possible_moves(row, col)
				if king_pos in moves:
					return true
					
	return false

func find_king() -> Vector2i:
	for row in range(board.size()):
		for col in range(board[row].size()):
			var piece = board[row][col]
			if piece != "" and piece.to_lower() == "k" and (piece.to_upper() == piece) == white_turn:
				return Vector2i(row, col)
	return Vector2i(-1, -1)

func get_possible_legal_moves(row: int, col: int) -> Array[Vector2i]:
	var piece = board[row][col]
	if piece == "":
		return []
	
	var is_white = piece == piece.to_upper()
	# Only generate moves for the side whose turn it is
	if is_white != white_turn:
		return []
	
	var legal_moves: Array[Vector2i] = []
	var moves = get_possible_moves(row, col)
	for move in moves:
		var testBoard = Moves.new(deep_copy_state(board), white_turn);
		testBoard.make_move(Vector2i(row, col), move, "")
		testBoard.white_turn = !testBoard.white_turn
		if not testBoard.is_in_check():
			legal_moves.append(move)
	return legal_moves

func deep_copy_state(state: Array) -> Array:
	var copy: Array = []
	for row in state:
		copy.append(row.duplicate())
	return copy

func is_promotion(from: Vector2i, to: Vector2i):
	var piece = board[from.x][from.y]
	if piece.to_lower() != "p":
		return false
	if to.x == 0 and piece == piece.to_upper():
		return true
	if to.x == 7 and piece != piece.to_upper():
		return true
	return false

func make_move(from: Vector2i, to: Vector2i, special: String = "", payload: String = ""):
	var piece = board[from.x][from.y]
	
	# Update castling rights:
	if piece.to_lower() == "k":
		if piece == piece.to_upper():
			white_can_castle_kingside = false
			white_can_castle_queenside = false
		else:
			black_can_castle_kingside = false
			black_can_castle_queenside = false
	
	# If rook moves
	if piece.to_lower() == "r":
		if from == Vector2i(7,0): white_can_castle_queenside = false
		if from == Vector2i(7,7): white_can_castle_kingside = false
		if from == Vector2i(0,0): black_can_castle_queenside = false
		if from == Vector2i(0,7): black_can_castle_kingside = false
	
	# --- Disable castling if a rook is captured ---
	var target_piece = board[to.x][to.y]
	
	if target_piece != "":
		if target_piece == "R":
			if Vector2i(to.x, to.y) == Vector2i(7,0):
				white_can_castle_queenside = false
			if Vector2i(to.x, to.y) == Vector2i(7,7):
				white_can_castle_kingside = false
		if target_piece == "r":
			if Vector2i(to.x, to.y) == Vector2i(0,0):
				black_can_castle_queenside = false
			if Vector2i(to.x, to.y) == Vector2i(0,7):
				black_can_castle_kingside = false
	
	if piece.to_lower() == "k" and abs(to.y - from.y) == 2:
		# --- CASTLING KING SIDE ---
		if to.y == 6:
			if from.x == 7:
				board[7][5] = board[7][7]
				board[7][7] = ""
			else:
				board[0][5] = board[0][7]
				board[0][7] = ""
		# --- CASTLING QUEEN SIDE ---
		elif to.y == 2:
			if from.x == 7:
				board[7][3] = board[7][0]
				board[7][0] = ""
			else:
				board[0][3] = board[0][0]
				board[0][0] = ""
	
	# EN PASSANT LOGIC
	# Check EN PASSANT execution
	if piece.to_lower() == "p":
		if to == en_passant_target:
			# Remove the pawn that moved 2 tiles last turn
			board[en_passant_pawn.x][en_passant_pawn.y] = ""
	
	en_passant_target = Vector2i(-1, -1)
	en_passant_pawn = Vector2i(-1, -1)
	# If a pawn moves two squares:
	if piece.to_lower() == "p" and abs(to.x - from.x) == 2:
		var direction = 1 if to.x > from.x else -1  # +1 down, -1 up
		en_passant_target = Vector2i(to.x - direction, to.y)
		en_passant_pawn = to
	
	# Normal move or promotion:
	if special == "promotion":
		board[to.x][to.y] = payload
	else:
		board[to.x][to.y] = board[from.x][from.y]
	board[from.x][from.y] = ""
	
	white_turn = !white_turn

func is_checkmate() -> bool:
	if is_in_check():
		var not_checkmate = false
		for row in range(board.size()):
			for col in range(board[row].size()):
				var piece = board[row][col]
				if piece != "" and (piece.to_upper() == piece) == white_turn:
					var moves = get_possible_legal_moves(row, col)
					if moves.size() > 0:
						not_checkmate = true
		return not not_checkmate
	else:
		return false

func square_attacked(r:int, c:int, by_white:bool) -> bool:
	for row in range(8):
		for col in range(8):
			var p = board[row][col]
			if p == "":
				continue
			if (p.to_upper() == p) != by_white:
				continue
			if p.to_lower() == "k" and abs(row-r) > 1:
				continue
			var moves = get_possible_moves(row,col)
			if Vector2i(r,c) in moves:
				return true
	return false
