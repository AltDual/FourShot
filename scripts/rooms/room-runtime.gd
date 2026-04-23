extends Node2D

const DOOR_REENABLE_DELAY := 0.5

const ROOM_WIDTH := 1280
const ROOM_HEIGHT := 720

# Adjust these to match your actual hallway sizes.
const HALLWAY_HORIZONTAL_LENGTH := 700
const HALLWAY_HORIZONTAL_HEIGHT := 100

const HALLWAY_VERTICAL_WIDTH := 100
const HALLWAY_VERTICAL_LENGTH := 400

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

@onready var camera_zone_room: Area2D = $CameraZoneRoom
@onready var camera_zone_up: Area2D = $CameraZoneUp
@onready var camera_zone_down: Area2D = $CameraZoneDown
@onready var camera_zone_left: Area2D = $CameraZoneLeft
@onready var camera_zone_right: Area2D = $CameraZoneRight

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
	set_camera_to_room_zone()
	update_room_state()
	disable_doors_temporarily()

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

func get_game_camera():
	var root = get_tree().current_scene
	if root == null:
		return null
	if not root.has_node("GameCamera"):
		return null
	return root.get_node("GameCamera")

func set_camera_rect(rect: Rect2) -> void:
	var camera = get_game_camera()
	if camera == null:
		return
	camera.set_camera_rect(rect)

func set_camera_limits(left: float, top: float, right: float, bottom: float) -> void:
	var camera = get_game_camera()
	if camera == null:
		return
	camera.set_camera_limits(left, top, right, bottom)

func set_camera_to_room_zone() -> void:
	set_camera_rect(get_room_rect())

func set_camera_to_up_hallway_zone() -> void:
	var room_rect := get_room_rect()
	var hall_rect := get_up_hallway_rect()

	set_camera_limits(
		hall_rect.position.x,
		hall_rect.position.y,
		hall_rect.position.x + hall_rect.size.x,
		room_rect.position.y + room_rect.size.y
	)

func set_camera_to_down_hallway_zone() -> void:
	var room_rect := get_room_rect()
	var hall_rect := get_down_hallway_rect()

	set_camera_limits(
		hall_rect.position.x,
		room_rect.position.y,
		hall_rect.position.x + hall_rect.size.x,
		hall_rect.position.y + hall_rect.size.y
	)

func set_camera_to_left_hallway_zone() -> void:
	var room_rect := get_room_rect()
	var hall_rect := get_left_hallway_rect()

	set_camera_limits(
		hall_rect.position.x,
		hall_rect.position.y,
		room_rect.position.x + room_rect.size.x,
		hall_rect.position.y + hall_rect.size.y
	)

func set_camera_to_right_hallway_zone() -> void:
	var room_rect := get_room_rect()
	var hall_rect := get_right_hallway_rect()

	set_camera_limits(
		room_rect.position.x,
		hall_rect.position.y,
		hall_rect.position.x + hall_rect.size.x,
		hall_rect.position.y + hall_rect.size.y
	)
	
	

func get_room_rect() -> Rect2:
	return Rect2(global_position, Vector2(ROOM_WIDTH, ROOM_HEIGHT))

func get_up_hallway_rect() -> Rect2:
	return Rect2(
		global_position + Vector2((ROOM_WIDTH - HALLWAY_VERTICAL_WIDTH) * 0.5, -HALLWAY_VERTICAL_LENGTH),
		Vector2(HALLWAY_VERTICAL_WIDTH, HALLWAY_VERTICAL_LENGTH)
	)

func get_down_hallway_rect() -> Rect2:
	return Rect2(
		global_position + Vector2((ROOM_WIDTH - HALLWAY_VERTICAL_WIDTH) * 0.5, ROOM_HEIGHT),
		Vector2(HALLWAY_VERTICAL_WIDTH, HALLWAY_VERTICAL_LENGTH)
	)

func get_left_hallway_rect() -> Rect2:
	return Rect2(
		global_position + Vector2(-HALLWAY_HORIZONTAL_LENGTH, (ROOM_HEIGHT - HALLWAY_HORIZONTAL_HEIGHT) * 0.5),
		Vector2(HALLWAY_HORIZONTAL_LENGTH, HALLWAY_HORIZONTAL_HEIGHT)
	)

func get_right_hallway_rect() -> Rect2:
	return Rect2(
		global_position + Vector2(ROOM_WIDTH, (ROOM_HEIGHT - HALLWAY_HORIZONTAL_HEIGHT) * 0.5),
		Vector2(HALLWAY_HORIZONTAL_LENGTH, HALLWAY_HORIZONTAL_HEIGHT)
	)

func _on_camera_zone_room_body_entered(body: Node) -> void:
	if body == player:
		set_camera_to_room_zone()

func _on_camera_zone_up_body_entered(body: Node) -> void:
	if body == player:
		set_camera_to_up_hallway_zone()

func _on_camera_zone_down_body_entered(body: Node) -> void:
	if body == player:
		set_camera_to_down_hallway_zone()

func _on_camera_zone_left_body_entered(body: Node) -> void:
	if body == player:
		set_camera_to_left_hallway_zone()

func _on_camera_zone_right_body_entered(body: Node) -> void:
	if body == player:
		set_camera_to_right_hallway_zone()

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
