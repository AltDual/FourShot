extends Area2D

var speed: float = 300.0
var max_distance: float = 800.0
var damage: int = 10
var start_position: Vector2

#TODO: Get Rid of debug messages when done
func setup(p_damage: int, p_speed: float, p_range: float) -> void:
	add_to_group("bullets")
	damage = p_damage
	speed = p_speed
	max_distance = p_range
	# --- CHANGED: Record the start position here, AFTER it is moved to the muzzle! ---
	start_position = global_position
	body_entered.connect(_on_body_entered)
	print("Bullet spawned, mask: ", collision_mask)

# (Removed the _ready function completely)

func _process(delta: float) -> void:
	# Using global_position here is safer when working with Area2D nodes
	global_position += transform.x * speed * delta
	
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

func on_hit(target) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
func _on_body_entered(body: Node) -> void:
	# 1. Prevent the bullet from deleting itself on the player who shot it
	if body.name == "Player" or body.is_in_group("player"):
		return
		
	# 2. Damage the target if it's an enemy
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	# 3. Destroy the bullet on ANY other body it touches (Walls, Obstacles, Enemies)
	queue_free()
