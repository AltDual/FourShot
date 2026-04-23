extends Control

const ROOM_WORLD_WIDTH := 1280.0
const ROOM_WORLD_HEIGHT := 720.0

const CELL_SPACING_X := 56.0
const CELL_SPACING_Y := 36.0

const ROOM_MAP_WIDTH := 32.0
const ROOM_MAP_HEIGHT := 18.0

const DOOR_LENGTH := 10.0
const LINE_WIDTH := 2.0

var dungeon = null
var player: CharacterBody2D = null

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_references(dungeon_ref, player_ref: CharacterBody2D) -> void:
	dungeon = dungeon_ref
	player = player_ref
	queue_redraw()

func refresh() -> void:
	queue_redraw()

func _process(_delta: float) -> void:
	if visible:
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

			draw_room(pos, room, map_rect)

	draw_player_marker(map_rect)

func draw_room(grid_pos: Vector2i, room: RoomData, map_rect: Rect2) -> void:
	var center := grid_to_screen(grid_pos, map_rect)
	var half_w := ROOM_MAP_WIDTH * 0.5
	var half_h := ROOM_MAP_HEIGHT * 0.5

	var room_color := Color(0.85, 0.85, 0.85)
	if room.room_type == "start":
		room_color = Color(0.2, 0.9, 0.2)
	elif room.room_type == "boss":
		room_color = Color(0.9, 0.2, 0.2)

	var rect := Rect2(
		center - Vector2(half_w, half_h),
		Vector2(ROOM_MAP_WIDTH, ROOM_MAP_HEIGHT)
	)

	draw_rect(rect, room_color)
	draw_rect(rect, Color.BLACK, false, 2.0)

	if room.door_up:
		var up_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.UP):
			up_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(0, -half_h),
			center + Vector2(0, -half_h - DOOR_LENGTH),
			up_color,
			LINE_WIDTH
		)

	if room.door_down:
		var down_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.DOWN):
			down_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(0, half_h),
			center + Vector2(0, half_h + DOOR_LENGTH),
			down_color,
			LINE_WIDTH
		)

	if room.door_left:
		var left_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.LEFT):
			left_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(-half_w, 0),
			center + Vector2(-half_w - DOOR_LENGTH, 0),
			left_color,
			LINE_WIDTH
		)

	if room.door_right:
		var right_color := Color.CYAN
		if dungeon.door_leads_to_boss(grid_pos, Vector2i.RIGHT):
			right_color = Color(1.0, 0.65, 0.15)

		draw_line(
			center + Vector2(half_w, 0),
			center + Vector2(half_w + DOOR_LENGTH, 0),
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
		draw_circle(center, 6.0, Color.BLACK)
		draw_circle(center, 4.0, Color.YELLOW)

func draw_player_marker(map_rect: Rect2) -> void:
	if player == null:
		return

	var current_room_center := grid_to_screen(dungeon.current_room_pos, map_rect)

	var local_x: float = clamp(player.global_position.x / ROOM_WORLD_WIDTH, 0.0, 1.0)
	var local_y: float = clamp(player.global_position.y / ROOM_WORLD_HEIGHT, 0.0, 1.0)

	var marker_offset := Vector2(
		(local_x - 0.5) * ROOM_MAP_WIDTH,
		(local_y - 0.5) * ROOM_MAP_HEIGHT
	)

	var marker_pos := current_room_center + marker_offset

	draw_circle(marker_pos, 4.0, Color.BLACK)
	draw_circle(marker_pos, 2.5, Color(1.0, 1.0, 0.3))

func get_map_rect() -> Rect2:
	var panel_size := Vector2(460, 320)
	var panel_pos := (size - panel_size) * 0.5
	return Rect2(panel_pos, panel_size)

func grid_to_screen(grid_pos: Vector2i, map_rect: Rect2) -> Vector2:
	var current_pos: Vector2i = dungeon.current_room_pos
	var map_center := map_rect.position + map_rect.size * 0.5

	return map_center + Vector2(
		(grid_pos.x - current_pos.x) * CELL_SPACING_X,
		(grid_pos.y - current_pos.y) * CELL_SPACING_Y
	)
