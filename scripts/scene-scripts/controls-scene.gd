extends Control

const TITLE_SCREEN := "res://scenes/title_screen.tscn"

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)
