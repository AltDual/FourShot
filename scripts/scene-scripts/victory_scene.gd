extends Control

func _ready() -> void:
	get_tree().paused = false
	$VBoxContainer/PlayAgain.pressed.connect(_on_play_again)
	$VBoxContainer/MainMenu.pressed.connect(_on_main_menu)

func _on_play_again() -> void:
	get_tree().change_scene_to_file("res://scenes/dungeon_test.tscn")

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
