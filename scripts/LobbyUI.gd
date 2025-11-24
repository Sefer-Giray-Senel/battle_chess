extends Control

# Menu containers
@onready var platform_menu: VBoxContainer = $PlatformMenu
@onready var mode_menu: VBoxContainer = $ModeMenu

# Buttons
@onready var steam_button: Button = $PlatformMenu/SteamButton
@onready var lan_button: Button = $PlatformMenu/LanButton

@onready var standard_button: Button = $ModeMenu/StandardButton
@onready var special_button: Button = $ModeMenu/SpecialButton
@onready var back_button: Button = $ModeMenu/BackButton

# Stores whether user selected Steam or LAN
var selected_platform: String = ""

func _ready() -> void:
	# Connect platform buttons
	steam_button.pressed.connect(_on_steam_pressed)
	lan_button.pressed.connect(_on_lan_pressed)

	# Connect mode buttons
	standard_button.pressed.connect(_on_standard_pressed)
	special_button.pressed.connect(_on_special_pressed)
	back_button.pressed.connect(_back_to_platform_menu)

	# Initial state
	platform_menu.visible = true
	mode_menu.visible = false
	
	Lobby.connect("log_message", Callable(self, "_on_log"))
	Lobby.connect("chess_lobby_joined", Callable(self, "_on_lobby_joined"))


# -------------------------
# PLATFORM SELECTION
# -------------------------

func _on_steam_pressed() -> void:
	selected_platform = "Steam"
	_show_mode_menu()

func _on_lan_pressed() -> void:
	selected_platform = "LAN"
	_show_mode_menu()

func _show_mode_menu() -> void:
	platform_menu.visible = false
	mode_menu.visible = true

func _back_to_platform_menu() -> void:
	platform_menu.visible = true
	mode_menu.visible = false

# -------------------------
# MODE SELECTION
# -------------------------

func _on_standard_pressed() -> void:
	_start_game("standard")

func _on_special_pressed() -> void:
	_start_game("special")

func _start_game(mode: String) -> void:
	if selected_platform == "Steam":
		Lobby.start_steam(mode)
	elif selected_platform == "LAN":
		Lobby.start_lan(mode)

func _on_lobby_joined():
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
