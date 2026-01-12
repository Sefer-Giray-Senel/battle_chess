extends PopupPanel

signal piece_selected(piece_type)

var selected_piece: String

func create_icon(region: Rect2) -> Texture2D:
	var tex := AtlasTexture.new()
	tex.atlas = load("res://assets/pieces.png")
	tex.region = region
	return tex

func set_button_icon(btn: Button, icon: Texture2D):
	btn.custom_minimum_size = Vector2(64, 64)
	btn.icon = icon
	btn.expand_icon = true
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.text = ""
	btn.flat = true


func _ready():
	var tile = Vector2(16, 16)

	var q = create_icon(Rect2(Vector2(16, 16), tile))
	var r = create_icon(Rect2(Vector2(64, 16), tile))
	var b = create_icon(Rect2(Vector2(32, 16), tile))
	var n = create_icon(Rect2(Vector2(48, 16), tile))

	set_button_icon($HBoxContainer/q, q)
	set_button_icon($HBoxContainer/r, r)
	set_button_icon($HBoxContainer/b, b)
	set_button_icon($HBoxContainer/n, n)
	
	for btn in $HBoxContainer.get_children():
		btn.pressed.connect(_on_piece_pressed.bind(btn.name))

func _on_piece_pressed(piece_type: String):
	selected_piece = piece_type
	emit_signal("piece_selected", piece_type)
	hide()

func show_and_get_choice() -> String:
	center_on_board()
	show()
	# wait for the signal and return its argument
	var chosen = await self.piece_selected
	return chosen

func center_on_board():
	var parent_rect = get_parent().get_rect()
	position = (Vector2i(parent_rect.size) - size) / 2
