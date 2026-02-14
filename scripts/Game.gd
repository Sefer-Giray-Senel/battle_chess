extends Control

enum GameState {
	LOADING,
	PLAYING,
	GAME_OVER
}

@onready var board := $BoardScreen
@onready var loading := $LoadingScreen
@onready var game_over := $GameOverScreen

var state: GameState = GameState.LOADING

func set_mode(mode: String):
	board.mode = mode

func _ready():
	set_state(GameState.LOADING)
	Lobby.connect("chess_lobby_joined", Callable(self, "_on_lobby_joined"))
	Lobby.connect("game_over", Callable(self, "_on_game_over"))

func set_state(new_state: GameState) -> void:
	state = new_state
	
	board.visible = state == GameState.PLAYING or state == GameState.GAME_OVER
	loading.visible = state == GameState.LOADING
	game_over.visible = state == GameState.GAME_OVER

func _on_lobby_joined():
	set_state(GameState.PLAYING)

func _on_game_over(player_won: bool):
	if state != GameState.GAME_OVER:
		game_over.set_player_won(player_won)
		set_state(GameState.GAME_OVER)
