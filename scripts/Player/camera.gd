extends Camera2D

@export var room_width: int = 1280
@export var room_height: int = 720

@export var view_width: int = 640
@export var view_height: int = 360

func _ready() -> void:
	make_current()
	zoom = Vector2.ONE

	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	limit_enabled = true

	apply_room_limits(Vector2.ZERO, Vector2(room_width, room_height))

func apply_room_limits(room_top_left: Vector2, room_size: Vector2) -> void:
	limit_left = int(room_top_left.x)
	limit_top = int(room_top_left.y)
	limit_right = int(room_top_left.x + room_size.x)
	limit_bottom = int(room_top_left.y + room_size.y)
