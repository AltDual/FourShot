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

# --- TILEMAP SETTINGS ---
@onready var wall_tilemap: TileMapLayer = $WallTileMap 
@onready var floor_tilemap: TileMapLayer = $FloorTileMap 

# --- WALL CONFIGURATION ---
const WALL_SOURCE_ID = 0
const WALL_ATLAS_COORDS_TOP = Vector2i(2,3)
const WALL_ATLAS_COORDS_BOTTOM = Vector2i(2,3)
const WALL_ATLAS_COORDS_LEFT = Vector2i(0,1)
const WALL_ATLAS_COORDS_RIGHT = Vector2i(0,1)

# Put the start and end coordinates of your gap in the arrays
const DOOR_UP_CELLS: Array[Vector2i] = [Vector2i(36, -1), Vector2i(44,-1)] 
const DOOR_DOWN_CELLS: Array[Vector2i] = [Vector2i(36, 45), Vector2i(44,45)]
const DOOR_LEFT_CELLS: Array[Vector2i] = [Vector2i(-1, 18), Vector2i(-1, 27)]
const DOOR_RIGHT_CELLS: Array[Vector2i] = [Vector2i(80, 18), Vector2i(80, 27)]

# --- FLOOR CONFIGURATION ---
const FLOOR_SOURCE_ID = 0
const FLOOR_ATLAS_COORDS_TOP = Vector2i(5,1)
const FLOOR_ATLAS_COORDS_BOTTOM = Vector2i(5,0)
const FLOOR_ATLAS_COORDS_LEFT = Vector2i(0,0)
const FLOOR_ATLAS_COORDS_RIGHT = Vector2i(0,0)
#const FLOOR_ATLAS_COORDS_MAIN = Vector2i(4, 0)

# The floor thresholds/doormats for the 4 doorways
const FLOOR_UP_CELLS: Array[Vector2i] = [Vector2i(36, 0), Vector2i(43,0)] 
const FLOOR_DOWN_CELLS: Array[Vector2i] = [Vector2i(36, 44), Vector2i(43,44)]
const FLOOR_LEFT_CELLS: Array[Vector2i] = [Vector2i(-1, 19), Vector2i(0, 27)]
const FLOOR_RIGHT_CELLS: Array[Vector2i] = [Vector2i(79, 19), Vector2i(80, 27)]
# ----------------------------------

# --- BOSS DOOR CONFIGURATION ---
# Replace these with the actual atlas coordinates of your two boss indicator tiles
const BOSS_TILE_1 = Vector2i(3, 0) 
const BOSS_TILE_2 = Vector2i(4, 0)

# Exact 2 coordinates for the boss indicators (DOES NOT fill between them)
const BOSS_INDICATOR_UP: Array[Vector2i] = [Vector2i(35, 0), Vector2i(44, 0)]
const BOSS_INDICATOR_DOWN: Array[Vector2i] = [Vector2i(35, 44), Vector2i(44, 44)]
const BOSS_INDICATOR_LEFT: Array[Vector2i] = [Vector2i(0, 18), Vector2i(0, 27)]
const BOSS_INDICATOR_RIGHT: Array[Vector2i] = [Vector2i(79, 18), Vector2i(79, 27)]
# ----------------------------------

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
	
	generate_obstacles()
	
	disable_doors_temporarily()

func apply_camera_limits() -> void:
	if player == null:
		return
	if not player.has_node("Camera2D"):
		return

	var camera: Camera2D = player.get_node("Camera2D")
	camera.apply_room_limits(global_position, Vector2(room_width, room_height))

# Universal Helper: Fills the rectangular gap between the first and last Vector2i in ANY array
func fill_area_from_array(tilemap: TileMapLayer, cells: Array[Vector2i], source_id: int, atlas_coords: Vector2i) -> void:
	if cells.is_empty() or tilemap == null: return
	
	var start_cell = cells[0]
	var end_cell = cells[-1] 
	
	var min_x = min(start_cell.x, end_cell.x)
	var max_x = max(start_cell.x, end_cell.x)
	var min_y = min(start_cell.y, end_cell.y)
	var max_y = max(start_cell.y, end_cell.y)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			tilemap.set_cell(Vector2i(x, y), source_id, atlas_coords)

func update_room_tiles() -> void:
	if room_data == null: return

	# 1. Update the Plugs (Walls and Floors)
	if not room_data.door_up: 
		fill_area_from_array(wall_tilemap, DOOR_UP_CELLS, WALL_SOURCE_ID, WALL_ATLAS_COORDS_TOP)
		fill_area_from_array(floor_tilemap, FLOOR_UP_CELLS, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS_TOP)
		
	if not room_data.door_down: 
		fill_area_from_array(wall_tilemap, DOOR_DOWN_CELLS, WALL_SOURCE_ID, WALL_ATLAS_COORDS_BOTTOM)
		fill_area_from_array(floor_tilemap, FLOOR_DOWN_CELLS, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS_BOTTOM)
		
	if not room_data.door_left: 
		fill_area_from_array(wall_tilemap, DOOR_LEFT_CELLS, WALL_SOURCE_ID, WALL_ATLAS_COORDS_LEFT)
		fill_area_from_array(floor_tilemap, FLOOR_LEFT_CELLS, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS_LEFT)
		
	if not room_data.door_right: 
		fill_area_from_array(wall_tilemap, DOOR_RIGHT_CELLS, WALL_SOURCE_ID, WALL_ATLAS_COORDS_RIGHT)
		fill_area_from_array(floor_tilemap, FLOOR_RIGHT_CELLS, FLOOR_SOURCE_ID, FLOOR_ATLAS_COORDS_RIGHT)

	# 2. Draw Boss Door Indicators (Only if the door exists AND leads to the boss)
	if dungeon != null:
		if room_data.door_up and dungeon.door_leads_to_boss(room_grid_pos, Vector2i.UP):
			floor_tilemap.set_cell(BOSS_INDICATOR_UP[0], FLOOR_SOURCE_ID, BOSS_TILE_1)
			floor_tilemap.set_cell(BOSS_INDICATOR_UP[1], FLOOR_SOURCE_ID, BOSS_TILE_2)
			
		if room_data.door_down and dungeon.door_leads_to_boss(room_grid_pos, Vector2i.DOWN):
			floor_tilemap.set_cell(BOSS_INDICATOR_DOWN[0], FLOOR_SOURCE_ID, BOSS_TILE_1)
			floor_tilemap.set_cell(BOSS_INDICATOR_DOWN[1], FLOOR_SOURCE_ID, BOSS_TILE_2)
			
		if room_data.door_left and dungeon.door_leads_to_boss(room_grid_pos, Vector2i.LEFT):
			floor_tilemap.set_cell(BOSS_INDICATOR_LEFT[0], FLOOR_SOURCE_ID, BOSS_TILE_2) # Left only uses 2
			floor_tilemap.set_cell(BOSS_INDICATOR_LEFT[1], FLOOR_SOURCE_ID, BOSS_TILE_2)
			
		if room_data.door_right and dungeon.door_leads_to_boss(room_grid_pos, Vector2i.RIGHT):
			floor_tilemap.set_cell(BOSS_INDICATOR_RIGHT[0], FLOOR_SOURCE_ID, BOSS_TILE_1) # Right only uses 1
			floor_tilemap.set_cell(BOSS_INDICATOR_RIGHT[1], FLOOR_SOURCE_ID, BOSS_TILE_1)

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

	update_room_tiles()

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
		
#Obstacles
func generate_obstacles() -> void:
	# Keep start and boss rooms clear of random clutter
	if room_data.room_type in ["start", "boss"]:
		return

	# Seed the RNG based on the room's grid position. 
	# This guarantees the same layout if the player re-enters the room!
	var room_seed = hash(str(room_grid_pos.x) + "_" + str(room_grid_pos.y))
	var rng = RandomNumberGenerator.new()
	rng.seed = room_seed

	# Define inner bounds (Tile coordinates).
	# Assuming 16x16 tiles (80x45 grid for a 1280x720 room).
	# Margins keep the edges and doorways clear.
	var min_x = 15
	var max_x = 65
	var min_y = 10
	var max_y = 35

	# Decide how cluttered this specific room should be
	var num_obstacle_clusters = rng.randi_range(5, 15)

	for i in range(num_obstacle_clusters):
		var center_x = rng.randi_range(min_x, max_x)
		var center_y = rng.randi_range(min_y, max_y)
		
		# Keep the dead center clear so we don't spawn on top of the player
		if Rect2(35, 18, 10, 8).has_point(Vector2(center_x, center_y)):
			continue

		# Make small clusters instead of single tiles
		var cluster_width = rng.randi_range(1, 5)
		var cluster_height = rng.randi_range(1, 4)
		
		for ox in range(cluster_width):
			for oy in range(cluster_height):
				# Using your existing wall tile for the obstacles
				wall_tilemap.set_cell(Vector2i(center_x + ox, center_y + oy), WALL_SOURCE_ID, WALL_ATLAS_COORDS_TOP)
				
