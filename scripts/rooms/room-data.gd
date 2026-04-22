extends RefCounted
class_name RoomData

var grid_pos: Vector2i
var exists: bool = false

var door_up: bool = false
var door_down: bool = false
var door_left: bool = false
var door_right: bool = false

var room_type: String = "normal"

var visited: bool = false
var cleared: bool = false
var doors_locked: bool = false
var enemies_spawned: bool = false
