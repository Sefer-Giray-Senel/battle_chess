extends Banner
class_name MineBanner

var is_placing = false

func _ready():
	super()
	$HBoxContainer/Button.pressed.connect(on_mine_button_pressed)
	$HBoxContainer/Button.disabled = true
	
	Lobby.connect("mine_placement_state", Callable(self, "_mine_placement_state"))
	Lobby.connect("mine_button_state", Callable(self, "_on_mine_button_state"))

func on_mine_button_pressed():
	Lobby.mine_placement_state.emit(!is_placing)

func _mine_placement_state(new_is_placing: bool):
	is_placing = new_is_placing
	if is_placing:
		$HBoxContainer/Button.text = "X"
	else:
		$HBoxContainer/Button.text = "M"

func _on_mine_button_state(disabled: bool):
	$HBoxContainer/Button.disabled = disabled
