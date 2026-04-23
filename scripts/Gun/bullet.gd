extends Node2D

var speed: int = 300
var max_distance = 800
var damage: int = 10
var start_position: Vector2

func setup(p_damage: int, p_speed: float, p_range: float) -> void:
	damage = p_damage
	speed = p_speed
	max_distance = p_range

func _ready():
	start_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * speed * delta
	
	if global_position.distance_to(start_position) > max_distance:
		queue_free()

#TODO: fix collision masks/hitboxes
func on_hit(target) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
