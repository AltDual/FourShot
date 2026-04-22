extends Node2D

const SPEED: int = 300
const MAX_DISTANCE = 800
var start_position: Vector2

func _ready():
	start_position = global_position

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.x * SPEED * delta
	
	if global_position.distance_to(start_position) > MAX_DISTANCE:
		queue_free()
