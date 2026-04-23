extends Camera2D

const CAMERA_SMOOTH_SPEED := 8.0

var target: Node2D = null

func _ready() -> void:
	top_level = true
	make_current()
	zoom = Vector2.ONE
	position_smoothing_enabled = true
	position_smoothing_speed = CAMERA_SMOOTH_SPEED
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	limit_enabled = true

func _physics_process(_delta: float) -> void:
	if target != null:
		global_position = target.global_position

func set_target(node: Node2D) -> void:
	target = node

func set_camera_limits(left: float, top: float, right: float, bottom: float) -> void:
	limit_left = int(left)
	limit_top = int(top)
	limit_right = int(right)
	limit_bottom = int(bottom)

func set_camera_rect(rect: Rect2) -> void:
	set_camera_limits(
		rect.position.x,
		rect.position.y,
		rect.position.x + rect.size.x,
		rect.position.y + rect.size.y
	)
