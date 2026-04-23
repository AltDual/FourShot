extends Node

const ROOM_RUNTIME_SCENE := preload("res://scenes/room-runtime.tscn")
const ROOM_TRANSITION_COOLDOWN := 0.35


@onready var dungeon = $DungeonGenerator
@onready var room_view: Node2D = $RoomView
@onready var map_overlay = $MapCanvasLayer/MapOverlay
@onready var player: CharacterBody2D = $Player
@onready var game_camera = $GameCamera

var current_room_instance: Node2D
var pending_entry_direction: Vector2i = Vector2i.ZERO
var is_transitioning: bool = false
var can_transition_rooms: bool = true

func _ready() -> void:
	game_camera.set_target(player)
	map_overlay.set_references(dungeon, player)
	load_current_room()

func _process(_delta: float) -> void:
	var current_room: RoomData = dungeon.get_current_room()

	if Input.is_action_just_pressed("toggle_map"):
		if not current_room.doors_locked:
			map_overlay.visible = not map_overlay.visible
			map_overlay.refresh()

	if current_room.doors_locked and map_overlay.visible:
		map_overlay.visible = false

	if Input.is_action_just_pressed("ui_accept"):
		if current_room.doors_locked and not current_room.cleared:
			clear_current_room()
			return

func load_current_room() -> void:
	if current_room_instance:
		if current_room_instance.door_used.is_connected(_on_room_door_used):
			current_room_instance.door_used.disconnect(_on_room_door_used)

		current_room_instance.queue_free()
		await get_tree().process_frame

	var room: RoomData = dungeon.get_current_room()
	room.visited = true

	current_room_instance = ROOM_RUNTIME_SCENE.instantiate()
	room_view.add_child(current_room_instance)

	current_room_instance.setup(
		room,
		dungeon.current_room_pos,
		dungeon,
		pending_entry_direction,
		player
	)

	current_room_instance.door_used.connect(_on_room_door_used)

	pending_entry_direction = Vector2i.ZERO

	handle_room_enter(room)
	map_overlay.refresh()

func _on_room_door_used(direction: Vector2i) -> void:
	if is_transitioning:
		return

	if not can_transition_rooms:
		return

	is_transitioning = true
	can_transition_rooms = false

	var moved: bool = dungeon.move_to_room(direction)

	if not moved:
		is_transitioning = false
		start_transition_cooldown()
		return

	pending_entry_direction = -direction
	await load_current_room()

	is_transitioning = false
	start_transition_cooldown()

func start_transition_cooldown() -> void:
	var timer := get_tree().create_timer(ROOM_TRANSITION_COOLDOWN)
	timer.timeout.connect(_end_transition_cooldown)

func _end_transition_cooldown() -> void:
	can_transition_rooms = true
	#room_runtime.reenable_doors()

func handle_room_enter(room: RoomData) -> void:
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

	if room.room_type == "boss":
		print("Boss defeated")

	refresh_current_room()
	map_overlay.refresh()

func refresh_current_room() -> void:
	if current_room_instance:
		current_room_instance.refresh()
