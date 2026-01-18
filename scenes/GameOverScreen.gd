extends Control

func _ready():
	$VBoxContainer/Button.pressed.connect(_on_leave_pressed)

func set_player_won(player_won: bool):
	if player_won:
		$VBoxContainer/Label.text = "You Won!"
	else:
		$VBoxContainer/Label.text = "You Lost..."

func _on_leave_pressed():
	Lobby.leave()
