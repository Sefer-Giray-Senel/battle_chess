extends Control

@onready var chat_box = $ChatBox
@onready var input_field = $HBoxContainer/MessageInput
@onready var send_button = $HBoxContainer/SendButton

func _ready():
	send_button.pressed.connect(_on_send_pressed)
	$LeaveButton.pressed.connect(_on_leave_pressed)
	
	Lobby.connect("message_received", Callable(self, "_on_message_received"))
	Lobby.connect("lobby_left", Callable(self, "_on_lobby_left"))

func _on_send_pressed():
	var text = input_field.text.strip_edges()
	if text != "":
		var data = {
			"type": "chat",
			"message": text
		}
		var packet = JSON.stringify(data)
		Lobby.send_packet(packet)
		chat_box.append_text("me: " + text + "\n")
		input_field.text = ""

func _on_message_received(from_id, text: String, colon: bool):
	chat_box.append_text("%s%s %s\n" % [str(from_id), ":" if colon else "", text])

func _on_leave_pressed():
	Lobby.leave()

func _on_lobby_left():
	Lobby.set_mode("LAN")
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
