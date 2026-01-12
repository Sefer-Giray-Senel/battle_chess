extends Control

signal quit_pressed

func _on_quit_button_pressed():
	quit_pressed.emit()
