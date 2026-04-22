extends Node2D

const CELL_SIZE := 64
const ROOM_SIZE := 28
const DOOR_LENGTH := 14
const LINE_WIDTH := 4
const MAP_OFFSET := Vector2(100, 100)
const PRINT_ENTRY := true

@onready var dungeon: Node = $DungeonGenerator

func _ready() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
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
		if PRINT_ENTRY:
			var room = dungeon.get_current_room()
			print("Entered room: ", dungeon.current_room_pos, " | type=", room.room_type)
			queue_redraw()

func _draw() -> void:
	for y in range(dungeon.GRID_HEIGHT):
		for x in range(dungeon.GRID_WIDTH):
			var pos := Vector2i(x, y)
			var room = dungeon.get_room(pos)

			if not room.exists:
				continue

			draw_room(pos, room)

func draw_room(grid_pos: Vector2i, room) -> void:
	var center := grid_to_screen(grid_pos)
	var half := ROOM_SIZE * 0.5

	var room_color := Color.WHITE

	if room.room_type == "start":
		room_color = Color.GREEN
	elif room.room_type == "boss":
		room_color = Color.RED

	

	var rect := Rect2(
		center - Vector2(half, half),
		Vector2(ROOM_SIZE, ROOM_SIZE)
	)

	draw_rect(rect, room_color)

	# Outline
	draw_rect(rect, Color.BLACK, false, 2.0)
	if grid_pos == dungeon.current_room_pos:
		draw_circle(center, 7.0, Color.YELLOW)
	# Doors
	if room.door_up:
		draw_line(
			center + Vector2(0, -half),
			center + Vector2(0, -half - DOOR_LENGTH),
			Color.CYAN,
			LINE_WIDTH
		)

	if room.door_down:
		draw_line(
			center + Vector2(0, half),
			center + Vector2(0, half + DOOR_LENGTH),
			Color.CYAN,
			LINE_WIDTH
		)

	if room.door_left:
		draw_line(
			center + Vector2(-half, 0),
			center + Vector2(-half - DOOR_LENGTH, 0),
			Color.CYAN,
			LINE_WIDTH
		)

	if room.door_right:
		draw_line(
			center + Vector2(half, 0),
			center + Vector2(half + DOOR_LENGTH, 0),
			Color.CYAN,
			LINE_WIDTH
		)

func grid_to_screen(grid_pos: Vector2i) -> Vector2:
	return MAP_OFFSET + Vector2(grid_pos.x * CELL_SIZE, grid_pos.y * CELL_SIZE)
