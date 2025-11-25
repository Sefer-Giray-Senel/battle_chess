extends Board
class_name MineBoard

func _on_move_received(packet):
	print("MINE")
	super(packet)
