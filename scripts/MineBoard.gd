extends Board
class_name MineBoard

var player_mines: Array[Vector2i] = [Vector2i(1,1),Vector2i(2,2),Vector2i(3,5)]
var opponent_mines: Array[Vector2i] = []

var MAX_MINES = 3

func _on_move_received(packet):
	print("MINE")
	super(packet)

func draw_new_visiuals(piece: String, tile: Node, row: int, col: int):
	if Vector2i(row, col) in player_mines:
		var sprite = TextureRect.new()
		sprite.texture = MOVE_DOT_TEXTURE
		sprite.modulate = Color(0, 0, 0)
		tile.add_child(sprite)
	
	super(piece, tile, row, col)
