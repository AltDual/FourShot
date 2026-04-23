extends Camera2D

# Separate padding for horizontal (X) and vertical (Y) walls
const PADDING_X = 11
const PADDING_Y = 16

func _ready() -> void:
	make_current()
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false

func apply_room_limits(room_top_left: Vector2, room_size: Vector2) -> void:
	# Subtract/add PADDING_X for the left and right sides
	limit_left = int(room_top_left.x - PADDING_X)
	limit_right = int(room_top_left.x + room_size.x + PADDING_X)
	
	# Subtract/add PADDING_Y for the top and bottom sides
	limit_top = int(room_top_left.y - PADDING_Y)
	limit_bottom = int(room_top_left.y + room_size.y + PADDING_Y)
