extends Control
class_name Banner

@onready var player_photo: TextureRect = %PlayerPhoto
@onready var player_name_label: Label = %NameLabel
@onready var time_label: Label = %TimeLabel
@onready var captured_pieces_container: HBoxContainer = %CapturedPiecesContainer

const PIECE_TYPES = ["k", "q", "b", "n", "r", "p"]
const SPRINT_SIZE = 16
var piece_sheet: Texture2D
var default_player: Texture2D

var is_white: bool = true

func _ready():
	piece_sheet = load("res://assets/pieces.png")
	default_player = load("res://assets/default_player.png")
	
	update_player_info("Player One (White)")
	update_time(300)
	update_captured_pieces(["q", "n", "p", "p", "p", "p", "p", "p", "p", "p", "p"])

func update_player_info(username: String, avatar_texture: Texture = null):
	if avatar_texture == null:
		var dummy_image: Image = default_player.get_image()
		avatar_texture = ImageTexture.create_from_image(dummy_image)
	player_name_label.text = username
	player_photo.texture = avatar_texture
	# In a real game, you might also use GodotSteam to fetch the avatar image async.
	update_captured_pieces(["q", "n", "p", "p", "p", "p", "p", "p", "p", "p", "p"])


func update_time(time_in_seconds: int):
	var minutes = time_in_seconds / 60
	var seconds = time_in_seconds % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func update_captured_pieces(captured_pieces: Array):
	# Clear previous pieces
	for child in captured_pieces_container.get_children():
		child.queue_free()

	# Display new pieces
	for piece in captured_pieces:
		var piece_texture = get_piece_texture(piece)
		if piece_texture:
			var texture_rect = TextureRect.new()
			texture_rect.texture = piece_texture
			texture_rect.custom_minimum_size = Vector2(32, 32) # Set a small size for the captured piece
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			captured_pieces_container.add_child(texture_rect)

func get_piece_texture(piece: String) -> Texture2D:
	if piece == null:
		return null

	var color_index = 0 if is_white else 1
	var type_index = PIECE_TYPES.find(piece.to_lower())
	if type_index == -1 or color_index == -1:
		return null

	var atlas = AtlasTexture.new()
	atlas.atlas = piece_sheet
	atlas.region = Rect2(type_index * SPRINT_SIZE, color_index * SPRINT_SIZE, SPRINT_SIZE, SPRINT_SIZE)
	return atlas
