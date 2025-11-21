extends Control

@onready var dropdown = $ModeDropdown
@onready var log_label = $LogLabel

func _ready():
	dropdown.clear()
	dropdown.add_item("LAN")
	dropdown.add_item("Steam")
	dropdown.item_selected.connect(_on_dropdown_item_selected)

	$HostButton.pressed.connect(_on_host_pressed)
	$JoinButton.pressed.connect(_on_join_pressed)

	Lobby.connect("log_message", Callable(self, "_on_log"))
	Lobby.connect("chess_lobby_joined", Callable(self, "_on_lobby_joined"))

func _on_dropdown_item_selected(_index: int):
	Lobby.set_mode(dropdown.get_item_text(dropdown.get_selected_id()))

func _on_host_pressed():
	Lobby.host()

func _on_join_pressed():
	Lobby.join()

func _on_log(msg: String):
	log_label.append_text(msg + "\n")

func _on_lobby_joined():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
