extends Control

const LOBBY_SCENE := "res://scenes/lobby.tscn"
const CONTROLS_SCENE := "res://scenes/controls.tscn"

@onready var start_button: Button = $CenterContainer/MarginContainer/VBoxContainer/StartButton

func _ready() -> void:
	start_button.grab_focus()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(LOBBY_SCENE)

func _on_controls_button_pressed() -> void:
	get_tree().change_scene_to_file(CONTROLS_SCENE)

func _on_quit_button_pressed() -> void:
	get_tree().quit()
