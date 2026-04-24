extends Area2D

const EXPLOSION_SCENE = preload("res://scenes/explosion.tscn")

var speed: float = 300.0
var max_distance: float = 800.0
var damage: int = 10
var start_position: Vector2

func setup(p_damage: int, p_speed: float, p_range: float) -> void:
	add_to_group("bullets")
	damage = p_damage
	speed = p_speed
	max_distance = p_range
	start_position = global_position
	body_entered.connect(_on_body_entered)
	print("Bullet spawned, mask: ", collision_mask)


func _process(delta: float) -> void:
	global_position += transform.x * speed * delta
	
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

func on_hit(target) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		return
		
	if body.has_method("take_damage"):
		body.take_damage(damage)
		
	spawn_explosion()
	queue_free()

func spawn_explosion() -> void:
	var explosion_instance = EXPLOSION_SCENE.instantiate()
	get_tree().current_scene.call_deferred("add_child", explosion_instance)
	explosion_instance.global_position = global_position
