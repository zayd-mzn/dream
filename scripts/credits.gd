extends Control

@onready var back_button: Button = $Back

func _ready() -> void :

	if back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.disconnect(_on_back_pressed)

	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed() -> void :
	get_tree().change_scene_to_file("res://scenes/mainmenu.tscn")
