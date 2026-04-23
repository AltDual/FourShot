extends Node2D

const DOOR_REENABLE_DELAY := 0.5

@export var room_width: int = 1280
@export var room_height: int = 720

signal door_used(direction: Vector2i)

@onready var door_up: Area2D = $DoorUp
@onready var door_down: Area2D = $DoorDown
@onready var door_left: Area2D = $DoorLeft
@onready var door_right: Area2D = $DoorRight

@onready var spawn_default: Marker2D = $SpawnDefault
@onready var spawn_from_up: Marker2D = $SpawnFromUp
@onready var spawn_from_down: Marker2D = $SpawnFromDown
@onready var spawn_from_left: Marker2D = $SpawnFromLeft
@onready var spawn_from_right: Marker2D = $SpawnFromRight

@onready var debug_label: Label = $DebugLabel

var room_data: RoomData
var room_grid_pos: Vector2i
var dungeon = null
var player: CharacterBody2D = null

func setup(
	new_room_data: RoomData,
	new_grid_pos: Vector2i,
	dungeon_ref,
	entry_direction: Vector2i,
	player_ref: CharacterBody2D
) -> void:
	room_data = new_room_data
	room_grid_pos = new_grid_pos
	dungeon = dungeon_ref
	player = player_ref

	position_player(entry_direction)
	apply_camera_limits()
	update_room_state()
	disable_doors_temporarily()

func apply_camera_limits() -> void:
	if player == null:
		return
	if not player.has_node("Camera2D"):
		return

	var camera: Camera2D = player.get_node("Camera2D")
	camera.apply_room_limits(global_position, Vector2(room_width, room_height))

func update_room_state() -> void:
	if room_data == null:
		return

	door_up.visible = room_data.door_up
	door_down.visible = room_data.door_down
	door_left.visible = room_data.door_left
	door_right.visible = room_data.door_right

	door_up.monitoring = room_data.door_up and not room_data.doors_locked
	door_down.monitoring = room_data.door_down and not room_data.doors_locked
	door_left.monitoring = room_data.door_left and not room_data.doors_locked
	door_right.monitoring = room_data.door_right and not room_data.doors_locked

	debug_label.text = "Room %s | Type: %s | Locked: %s | Cleared: %s" % [
		str(room_grid_pos),
		room_data.room_type,
		str(room_data.doors_locked),
		str(room_data.cleared)
	]

func disable_doors_temporarily() -> void:
	door_up.monitoring = false
	door_down.monitoring = false
	door_left.monitoring = false
	door_right.monitoring = false

	var timer := get_tree().create_timer(DOOR_REENABLE_DELAY)
	timer.timeout.connect(_on_door_cooldown_finished)

func _on_door_cooldown_finished() -> void:
	update_room_state()

func position_player(entry_direction: Vector2i) -> void:
	if player == null:
		return

	player.velocity = Vector2.ZERO

	if entry_direction == Vector2i.UP:
		player.global_position = spawn_from_up.global_position
	elif entry_direction == Vector2i.DOWN:
		player.global_position = spawn_from_down.global_position
	elif entry_direction == Vector2i.LEFT:
		player.global_position = spawn_from_left.global_position
	elif entry_direction == Vector2i.RIGHT:
		player.global_position = spawn_from_right.global_position
	else:
		player.global_position = spawn_default.global_position

func refresh() -> void:
	update_room_state()

func _on_door_up_body_entered(body: Node) -> void:
	if body == player and door_up.monitoring:
		door_up.set_deferred("monitoring", false)
		emit_signal("door_used", Vector2i.UP)

func _on_door_down_body_entered(body: Node) -> void:
	if body == player and door_down.monitoring:
		door_down.set_deferred("monitoring", false)
		emit_signal("door_used", Vector2i.DOWN)

func _on_door_left_body_entered(body: Node) -> void:
	if body == player and door_left.monitoring:
		door_left.set_deferred("monitoring", false)
		emit_signal("door_used", Vector2i.LEFT)

func _on_door_right_body_entered(body: Node) -> void:
	if body == player and door_right.monitoring:
		door_right.set_deferred("monitoring", false)
		emit_signal("door_used", Vector2i.RIGHT)
