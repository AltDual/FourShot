extends Control

const MAIN_SCENE := "res://scenes/main.tscn"
const TITLE_SCREEN := "res://scenes/title_screen.tscn"
const DEBUG_MAP := "res://scenes/DebugDungeonMap.tscn"

func _on_dungeon_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCREEN)


func _on_debug_button_pressed() -> void:
	get_tree().change_scene_to_file(DEBUG_MAP)
