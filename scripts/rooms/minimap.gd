extends Control

# Decreased from 0.15 to 0.12 to make the overall map smaller
@export var map_scale: float = 0.12 
@export var room_size := Vector2(1280, 720)

var player: Node2D = null
var current_room_top_left := Vector2.ZERO

func setup(_player: Node2D) -> void:
	player = _player

func set_current_room(top_left_pos: Vector2) -> void:
	current_room_top_left = top_left_pos

func _process(_delta: float) -> void:
	# Forces the screen to update the dots every single frame
	queue_redraw()

func _draw() -> void:
	if player == null:
		return

	# 1. Draw the Room Background
	var scaled_room = Rect2(Vector2.ZERO, room_size * map_scale)
	draw_rect(scaled_room, Color(0.1, 0.1, 0.1, 0.4)) # Dark gray background
	draw_rect(scaled_room, Color(0.8, 0.8, 0.8, 0.7), false, 2.0) # White border outline

	# 2. Draw the Player (Green Dot)
	var relative_player_pos = player.global_position - current_room_top_left
	var map_player_pos = relative_player_pos * map_scale
	
	# Clamp prevents the dot from visibly bleeding over the white border
	map_player_pos.x = clamp(map_player_pos.x, 0, scaled_room.size.x)
	map_player_pos.y = clamp(map_player_pos.y, 0, scaled_room.size.y)
	draw_circle(map_player_pos, 4.0, Color.GREEN)

	# 3. Draw the Enemies (Red Dots)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			var relative_enemy_pos = enemy.global_position - current_room_top_left
			var map_enemy_pos = relative_enemy_pos * map_scale
			
			map_enemy_pos.x = clamp(map_enemy_pos.x, 0, scaled_room.size.x)
			map_enemy_pos.y = clamp(map_enemy_pos.y, 0, scaled_room.size.y)
			
			# Check if this specific enemy is the boss!
			if enemy.is_in_group("boss"):
				# Draw a larger (6.0), darker red dot for the boss
				draw_circle(map_enemy_pos, 6.0, Color.DARK_RED)
			else:
				# Draw the standard (3.0) red dot for normal enemies
				draw_circle(map_enemy_pos, 3.0, Color.RED)
