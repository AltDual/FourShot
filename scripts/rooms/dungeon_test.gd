extends Node

const ROOM_RUNTIME_SCENE := preload("res://scenes/room-main.tscn")
const ROOM_TRANSITION_COOLDOWN := 0.35

const RANGED_ENEMY = preload("res://scenes/ranged_enemy.tscn")
const BOSS_GOLEM = preload("res://scenes/not_so_sneak_golem.tscn")
const SMALL_SLIME_ENEMY = preload("res://scenes/small_slime_enemy.tscn")
const ELITE_SLIME_ENEMY = preload("res://scenes/elite_slime_enemy.tscn")

@onready var dungeon = $DungeonGenerator
@onready var room_view: Node2D = $RoomView
@onready var map_overlay = $MapCanvasLayer/MapOverlay
@onready var minimap = $MapCanvasLayer/Minimap
@onready var player: CharacterBody2D = $Player
@onready var boss_music: AudioStreamPlayer = $BossMusic
@onready var dungeon_music: AudioStreamPlayer = $DungeonMusic
#@onready var game_camera = $GameCamera

var current_room_instance: Node2D
var pending_entry_direction: Vector2i = Vector2i.ZERO
var is_transitioning: bool = false
var can_transition_rooms: bool = true

func _ready() -> void:
	#game_camera.set_target(player)
	map_overlay.set_references(dungeon, player)
	minimap.setup(player)
	load_current_room()
	dungeon_music.play()

func _process(_delta: float) -> void:
	var current_room: RoomData = dungeon.get_current_room()

	if Input.is_action_just_pressed("toggle_map"):
		if not current_room.doors_locked:
			map_overlay.visible = not map_overlay.visible
			map_overlay.refresh()
			# NEW: Set minimap visibility to the opposite of the big map
			minimap.visible = not map_overlay.visible

	# Auto-close the big map and restore the minimap if combat starts
	if current_room.doors_locked and map_overlay.visible:
		map_overlay.visible = false
		minimap.visible = true

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

	# NEW: Tell the minimap where the camera/room just moved to!
	minimap.set_current_room(current_room_instance.global_position)

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
		enemies_alive = 0
		spawn_enemies(room, randi() % 10 + 1)
	room.doors_locked = true
	map_overlay.visible = false
	refresh_current_room()

func enter_boss_room(room: RoomData) -> void:
	if not room.enemies_spawned:
		room.enemies_spawned = true
		enemies_alive = 0
		spawn_boss()
		dungeon_music.stop()
		boss_music.play()
	room.doors_locked = true
	map_overlay.visible = false
	refresh_current_room()

func spawn_boss() -> void:
	enemies_alive = 1
	var boss = BOSS_GOLEM.instantiate()
	current_room_instance.add_child(boss)
	# Spawn in center of room, away from player
	boss.global_position = Vector2(640, 360)
	boss.tree_exited.connect(_on_boss_killed)

func _on_boss_killed() -> void:
	boss_music.stop()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	clear_current_room()

func clear_current_room() -> void:
	var room: RoomData = dungeon.get_current_room()

	room.cleared = true
	room.doors_locked = false

	if room.room_type == "boss":
		_show_victory()
	player.heal(20)
	refresh_current_room()
	map_overlay.refresh()

func refresh_current_room() -> void:
	if current_room_instance:
		current_room_instance.refresh()

#TESTING CODE FOR ENEMIES
var enemies_alive: int = 0
func spawn_enemies(room: RoomData, count: int) -> void:
	var room_size = get_room_bounds() 
	
	for i in range(count):
		var enemy
		
		# 25% chance to spawn an Elite Slime
		if randf() <= 0.25:
			enemy = ELITE_SLIME_ENEMY.instantiate()
		else:
			enemy = SMALL_SLIME_ENEMY.instantiate()
			
		current_room_instance.add_child(enemy)
		enemy.global_position = _random_spawn_position(room_size)
		enemy.tree_exited.connect(_on_enemy_died)
		enemies_alive += 1

func _random_spawn_position(bounds: Rect2) -> Vector2:
	const MIN_DIST_FROM_PLAYER = 150.0
	const MARGIN = 80.0  # keep away from walls
	
	var pos: Vector2
	var attempts = 0
	
	while attempts < 20:
		pos = Vector2(
			randf_range(bounds.position.x + MARGIN, bounds.end.x - MARGIN),
			randf_range(bounds.position.y + MARGIN, bounds.end.y - MARGIN)
		)
		if pos.distance_to(player.global_position) >= MIN_DIST_FROM_PLAYER:
			return pos
		attempts += 1
	# Fallback if no valid position found after 20 tries
	return bounds.get_center()

func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0:
		clear_current_room()
func get_room_bounds() -> Rect2:
	return Rect2(0, 0, 1280, 720)
	
func _show_victory() -> void:
	# Stop all music tracks to ensure silence during the scene transition
	dungeon_music.stop()
	boss_music.stop()

	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.queue_free()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	get_tree().paused = true
	get_tree().change_scene_to_file("res://scenes/victory.tscn")
