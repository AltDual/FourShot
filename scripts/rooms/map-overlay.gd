extends Control

const CELL_SIZE := 48
const ROOM_SIZE := 20
const DOOR_LENGTH := 12
const LINE_WIDTH := 3
const PANEL_PADDING := 40

var dungeon = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_dungeon(dungeon_ref) -> void:
	dungeon = dungeon_ref
	queue_redraw()

func refresh() -> void:
	queue_redraw()

func _draw() -> void:
	if dungeon == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.82), true)

	var map_rect := get_map_rect()

	draw_rect(map_rect, Color(0.08, 0.08, 0.08, 0.95), true)
	draw_rect(map_rect, Color.WHITE, false, 3.0)

	for y in range(dungeon.GRID_HEIGHT):
		for x in range(dungeon.GRID_WIDTH):
			var pos := Vector2i(x, y)
			var room: RoomData = dungeon.get_room(pos)

			if not room.exists:
				continue

			if not room.visited:
				continue

			draw_room(pos, room, map_rect.position)

func draw_room(grid_pos: Vector2i, room: RoomData, map_origin: Vector2) -> void:
	var center := grid_to_screen(grid_pos, map_origin)
	var half := ROOM_SIZE * 0.5

	var room_color := Color(0.85, 0.85, 0.85)

	if room.room_type == "start":
		room_color = Color(0.2, 0.9, 0.2)
	elif room.room_type == "boss":
		room_color = Color(0.9, 0.2, 0.2)

	var rect := Rect2(
		center - Vector2(half, half),
		Vector2(ROOM_SIZE, ROOM_SIZE)
	)

	draw_rect(rect, room_color)
	draw_rect(rect, Color.BLACK, false, 2.0)

	if room.door_up:
		var up_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.UP):
			up_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(0, -half),
			center + Vector2(0, -half - DOOR_LENGTH),
			up_color,
			LINE_WIDTH
		)

	if room.door_down:
		var down_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.DOWN):
			down_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(0, half),
			center + Vector2(0, half + DOOR_LENGTH),
			down_color,
			LINE_WIDTH
		)

	if room.door_left:
		var left_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.LEFT):
			left_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(-half, 0),
			center + Vector2(-half - DOOR_LENGTH, 0),
			left_color,
			LINE_WIDTH
		)

	if room.door_right:
		var right_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.RIGHT):
			right_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(half, 0),
			center + Vector2(half + DOOR_LENGTH, 0),
			right_color,
			LINE_WIDTH
		)

	if room.cleared:
		draw_line(
			center + Vector2(-6, -6),
			center + Vector2(6, 6),
			Color.BLACK,
			3.0
		)
		draw_line(
			center + Vector2(-6, 6),
			center + Vector2(6, -6),
			Color.BLACK,
			3.0
		)

	if grid_pos == dungeon.current_room_pos:
		draw_circle(center, 8.0, Color.BLACK)
		draw_circle(center, 5.0, Color.YELLOW)

func get_map_rect() -> Rect2:
	var map_pixel_size := Vector2(
		(dungeon.GRID_WIDTH - 1) * CELL_SIZE + ROOM_SIZE,
		(dungeon.GRID_HEIGHT - 1) * CELL_SIZE + ROOM_SIZE
	)

	var panel_size := map_pixel_size + Vector2(PANEL_PADDING * 2, PANEL_PADDING * 2)
	var panel_pos := (size - panel_size) * 0.5

	return Rect2(panel_pos, panel_size)

func grid_to_screen(grid_pos: Vector2i, map_origin: Vector2) -> Vector2:
	return map_origin + Vector2(PANEL_PADDING, PANEL_PADDING) + Vector2(
		grid_pos.x * CELL_SIZE + ROOM_SIZE * 0.5,
		grid_pos.y * CELL_SIZE + ROOM_SIZE * 0.5
	)
