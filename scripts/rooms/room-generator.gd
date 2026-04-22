extends Node

# =========================
# GENERATION SETTINGS
# =========================
const GRID_WIDTH := 5
const GRID_HEIGHT := 5

const MIN_ROOMS := 12
const MAX_ROOMS := 15

const USE_RANDOM_START_ROOM := true
const START_ROOM_POSITION := Vector2i(2, 2)

const PRINT_LAYOUT := true
const PRINT_ROOM_DETAILS := true

# Bias for choosing which existing room expands next.
const EXPAND_FROM_OUTWARD_BIAS := 1.5

# Bias for choosing which empty neighbor becomes the new room.
const NEW_ROOM_OUTWARD_BIAS := 2

# Boss room settings
const REQUIRE_BOSS_ROOM := true
const MIN_BOSS_DISTANCE_FROM_START := 5
const MAX_BOSS_DISTANCE_FROM_START := 7
const MAX_GENERATION_ATTEMPTS := 100

# =========================
# DUNGEON DATA
# =========================
var rooms: Array = []
var current_start_pos: Vector2i
var current_room_pos: Vector2i

func _ready() -> void:
	randomize()
	generate_dungeon_until_valid()

	if PRINT_LAYOUT:
		print_dungeon()

	if PRINT_ROOM_DETAILS:
		print_room_details()

func generate_dungeon() -> bool:
	create_empty_grid()

	current_start_pos = get_start_room_position()
	var target_room_count := randi_range(MIN_ROOMS, MAX_ROOMS)

	var active_rooms: Array[Vector2i] = []
	var placed_count := 1

	var start_room: RoomData = get_room(current_start_pos)
	start_room.exists = true
	start_room.room_type = "start"
	active_rooms.append(current_start_pos)
	current_room_pos = current_start_pos

	while placed_count < target_room_count:
		var expandable_rooms: Array[Vector2i] = []

		for pos in active_rooms:
			if not get_valid_new_neighbors(pos).is_empty():
				expandable_rooms.append(pos)

		if expandable_rooms.is_empty():
			break

		var base_pos := choose_biased_position(expandable_rooms, current_start_pos, EXPAND_FROM_OUTWARD_BIAS)
		var neighbors := get_valid_new_neighbors(base_pos)
		var new_pos := choose_biased_position(neighbors, current_start_pos, NEW_ROOM_OUTWARD_BIAS)

		create_connection(base_pos, new_pos)

		if not active_rooms.has(new_pos):
			active_rooms.append(new_pos)

		placed_count += 1

	return assign_boss_room()

func generate_dungeon_until_valid() -> void:
	for attempt in range(MAX_GENERATION_ATTEMPTS):
		var success := generate_dungeon()

		if success:
			print("Dungeon generated successfully on attempt ", attempt + 1)
			return

	push_error("Failed to generate a valid dungeon after %d attempts." % MAX_GENERATION_ATTEMPTS)

func move_to_room(direction: Vector2i) -> bool:
	var current_room := get_room(current_room_pos)

	if direction == Vector2i.UP and current_room.door_up:
		current_room_pos += Vector2i.UP
		return true
	elif direction == Vector2i.DOWN and current_room.door_down:
		current_room_pos += Vector2i.DOWN
		return true
	elif direction == Vector2i.LEFT and current_room.door_left:
		current_room_pos += Vector2i.LEFT
		return true
	elif direction == Vector2i.RIGHT and current_room.door_right:
		current_room_pos += Vector2i.RIGHT
		return true

	return false

func get_current_room() -> RoomData:
	return get_room(current_room_pos)
	
func assign_boss_room() -> bool:
	if not REQUIRE_BOSS_ROOM:
		return true

	var valid_boss_candidates: Array[Vector2i] = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var pos := Vector2i(x, y)
			var room := get_room(pos)

			if not room.exists:
				continue

			if room.room_type == "start":
				continue

			if not is_leaf_room(pos):
				continue

			var distance := get_room_distance_from_start(pos)

			if distance >= MIN_BOSS_DISTANCE_FROM_START and distance <= MAX_BOSS_DISTANCE_FROM_START:
				valid_boss_candidates.append(pos)

	if valid_boss_candidates.is_empty():
		return false

	var boss_pos := valid_boss_candidates[randi() % valid_boss_candidates.size()]
	get_room(boss_pos).room_type = "boss"
	mark_pre_boss_room(boss_pos)
	return true
	
func mark_pre_boss_room(boss_pos: Vector2i) -> void:
	var connected := get_connected_neighbors(boss_pos)

	if connected.is_empty():
		return

	var pre_boss_pos := connected[0]
	var pre_boss_room := get_room(pre_boss_pos)

	if pre_boss_room.room_type == "normal":
		pre_boss_room.room_type = "pre_boss"
func door_leads_to_boss(from_pos: Vector2i, direction: Vector2i) -> bool:
	var target := from_pos + direction

	if not is_in_bounds(target):
		return false

	var room := get_room(target)
	return room.exists and room.room_type == "boss"
	
func is_leaf_room(pos: Vector2i) -> bool:
	var room := get_room(pos)
	return get_door_count(room) == 1

func get_door_count(room: RoomData) -> int:
	var count := 0

	if room.door_up:
		count += 1
	if room.door_down:
		count += 1
	if room.door_left:
		count += 1
	if room.door_right:
		count += 1

	return count

func get_room_distance_from_start(target_pos: Vector2i) -> int:
	# Because the dungeon door graph is generated as a tree,
	# there is exactly one path from start to any room.
	# We use BFS here anyway, which is robust and easy to extend later.

	var visited := {}
	var queue: Array = []

	queue.append({"pos": current_start_pos, "dist": 0})
	visited[current_start_pos] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		var pos: Vector2i = current["pos"]
		var dist: int = current["dist"]

		if pos == target_pos:
			return dist

		for neighbor in get_connected_neighbors(pos):
			if not visited.has(neighbor):
				visited[neighbor] = true
				queue.append({"pos": neighbor, "dist": dist + 1})

	return -1

func get_connected_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var room := get_room(pos)

	if room.door_up:
		result.append(pos + Vector2i.UP)
	if room.door_down:
		result.append(pos + Vector2i.DOWN)
	if room.door_left:
		result.append(pos + Vector2i.LEFT)
	if room.door_right:
		result.append(pos + Vector2i.RIGHT)

	return result

func get_start_room_position() -> Vector2i:
	if USE_RANDOM_START_ROOM:
		return Vector2i(
			randi_range(0, GRID_WIDTH - 1),
			randi_range(0, GRID_HEIGHT - 1)
		)

	return START_ROOM_POSITION

func create_empty_grid() -> void:
	rooms.clear()

	for y in range(GRID_HEIGHT):
		var row: Array[RoomData] = []
		for x in range(GRID_WIDTH):
			var room := RoomData.new()
			room.grid_pos = Vector2i(x, y)
			row.append(room)
		rooms.append(row)

func get_room(pos: Vector2i) -> RoomData:
	return rooms[pos.y][pos.x]

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < GRID_HEIGHT

func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	var directions: Array[Vector2i] = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	for dir in directions:
		var next := pos + dir
		if is_in_bounds(next):
			result.append(next)

	return result

func get_empty_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []

	for neighbor in get_neighbors(pos):
		if not get_room(neighbor).exists:
			result.append(neighbor)

	return result

func get_valid_new_neighbors(parent_pos: Vector2i) -> Array[Vector2i]:
	return get_empty_neighbors(parent_pos)

func choose_biased_position(positions: Array[Vector2i], start_pos: Vector2i, bias_strength: float) -> Vector2i:
	if positions.size() == 1:
		return positions[0]

	if bias_strength <= 0.0:
		return positions[randi() % positions.size()]

	var weights: Array[float] = []
	var total_weight := 0.0

	for pos in positions:
		var distance_from_start := manhattan_distance(pos, start_pos)
		var weight := 1.0 + (float(distance_from_start) * bias_strength)

		weights.append(weight)
		total_weight += weight

	var roll := randf() * total_weight
	var running_total := 0.0

	for i in range(positions.size()):
		running_total += weights[i]
		if roll <= running_total:
			return positions[i]

	return positions[positions.size() - 1]

func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func create_connection(a: Vector2i, b: Vector2i) -> void:
	var room_a := get_room(a)
	var room_b := get_room(b)

	room_a.exists = true
	room_b.exists = true

	var diff := b - a

	if diff == Vector2i.UP:
		room_a.door_up = true
		room_b.door_down = true
	elif diff == Vector2i.DOWN:
		room_a.door_down = true
		room_b.door_up = true
	elif diff == Vector2i.LEFT:
		room_a.door_left = true
		room_b.door_right = true
	elif diff == Vector2i.RIGHT:
		room_a.door_right = true
		room_b.door_left = true

func print_dungeon() -> void:
	print("")
	print("=== DUNGEON LAYOUT ===")

	for y in range(GRID_HEIGHT):
		var line := ""
		for x in range(GRID_WIDTH):
			var room: RoomData = rooms[y][x]
			if room.exists:
				if room.room_type == "start":
					line += " S "
				elif room.room_type == "boss":
					line += " B "
				else:
					line += " O "
			else:
				line += " . "
		print(line)

func print_room_details() -> void:
	print("")
	print("=== ROOM DETAILS ===")

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var room: RoomData = rooms[y][x]
			if room.exists:
				var doors: Array[String] = []

				if room.door_up:
					doors.append("U")
				if room.door_down:
					doors.append("D")
				if room.door_left:
					doors.append("L")
				if room.door_right:
					doors.append("R")

				var distance := get_room_distance_from_start(room.grid_pos)
				print("Room ", room.grid_pos, " | type=", room.room_type, " | distance=", distance, " | doors=", doors)
