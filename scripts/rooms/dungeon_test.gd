extends Node

const ROOM_PLACEHOLDER_SCENE := preload("res://scenes/room-placeholder.tscn")

@onready var dungeon = $DungeonGenerator
@onready var room_view: Control = $RoomView
@onready var map_overlay = $MapOverlay

var current_room_instance: Control

func _ready() -> void:
	map_overlay.set_dungeon(dungeon)
	load_current_room()

func _process(_delta: float) -> void:
	var current_room: RoomData = dungeon.get_current_room()

	# Map toggle only when not in combat
	if Input.is_action_just_pressed("toggle_map"):
		if not current_room.doors_locked:
			map_overlay.visible = not map_overlay.visible
			map_overlay.refresh()

	# Close map automatically if combat starts
	if current_room.doors_locked and map_overlay.visible:
		map_overlay.visible = false

	# Debug clear key
	if Input.is_action_just_pressed("ui_accept"):
		if current_room.doors_locked and not current_room.cleared:
			clear_current_room()
			return

	# Prevent movement while locked
	if current_room.doors_locked:
		return

	# Optional: prevent movement while map is open
	if map_overlay.visible:
		return

	var moved := false

	if Input.is_action_just_pressed("ui_up"):
		moved = dungeon.move_to_room(Vector2i.UP)
	elif Input.is_action_just_pressed("ui_down"):
		moved = dungeon.move_to_room(Vector2i.DOWN)
	elif Input.is_action_just_pressed("ui_left"):
		moved = dungeon.move_to_room(Vector2i.LEFT)
	elif Input.is_action_just_pressed("ui_right"):
		moved = dungeon.move_to_room(Vector2i.RIGHT)

	if moved:
		load_current_room()
		map_overlay.refresh()

func load_current_room() -> void:
	if current_room_instance:
		current_room_instance.queue_free()

	var room: RoomData = dungeon.get_current_room()
	room.visited = true

	current_room_instance = ROOM_PLACEHOLDER_SCENE.instantiate()
	room_view.add_child(current_room_instance)
	current_room_instance.setup(room, dungeon.current_room_pos, dungeon)

	handle_room_enter(room)
	map_overlay.refresh()

func handle_room_enter(room: RoomData) -> void:
	print("Entered room: ", dungeon.current_room_pos, " | type=", room.room_type)

	if room.room_type == "start":
		room.doors_locked = false
		room.enemies_spawned = false
		refresh_current_room()
		return

	if room.cleared:
		room.doors_locked = false
		refresh_current_room()
		return

	if room.room_type == "boss":
		enter_boss_room(room)
	else:
		enter_combat_room(room)

func enter_combat_room(room: RoomData) -> void:
	if not room.enemies_spawned:
		room.enemies_spawned = true
		print("Spawn normal enemies here")

	room.doors_locked = true
	map_overlay.visible = false
	refresh_current_room()

func enter_boss_room(room: RoomData) -> void:
	print("BOSS ROOM ENTERED")

	if not room.enemies_spawned:
		room.enemies_spawned = true
		print("Spawn boss here")

	room.doors_locked = true
	map_overlay.visible = false
	refresh_current_room()

func clear_current_room() -> void:
	var room: RoomData = dungeon.get_current_room()

	room.cleared = true
	room.doors_locked = false

	print("Room cleared: ", dungeon.current_room_pos)

	if room.room_type == "boss":
		print("Boss defeated")

	refresh_current_room()
	map_overlay.refresh()

func refresh_current_room() -> void:
	if current_room_instance:
		current_room_instance.setup(dungeon.get_current_room(), dungeon.current_room_pos, dungeon)
