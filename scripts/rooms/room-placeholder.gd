extends Control

@onready var background: ColorRect = $Background
@onready var label_room_type: Label = $MarginContainer/VBoxContainer/RoomType
@onready var label_coords: Label = $MarginContainer/VBoxContainer/Coords
@onready var label_info: Label = $MarginContainer/VBoxContainer/Info

@onready var door_up: ColorRect = $DoorUp
@onready var door_down: ColorRect = $DoorDown
@onready var door_left: ColorRect = $DoorLeft
@onready var door_right: ColorRect = $DoorRight


func setup(room: RoomData, current_pos: Vector2i, dungeon) -> void:
	label_room_type.text = "ROOM TYPE: " + room.room_type.to_upper()
	label_coords.text = "GRID: " + str(current_pos)

	if room.room_type == "boss":
		background.color = Color(0.25, 0.05, 0.05)
	elif room.room_type == "start":
		background.color = Color(0.05, 0.2, 0.05)
	else:
		background.color = Color(0.12, 0.12, 0.12)

	door_up.visible = room.door_up
	door_down.visible = room.door_down
	door_left.visible = room.door_left
	door_right.visible = room.door_right

	update_room_info(room)
	update_door_colors(room, current_pos, dungeon)

func update_room_info(room: RoomData) -> void:
	if room.room_type == "boss":
		if room.cleared:
			label_info.text = "Boss defeated"
		elif room.doors_locked:
			label_info.text = "Boss active - doors locked"
		else:
			label_info.text = "Boss room"
	elif room.room_type == "start":
		label_info.text = "Start room"
	else:
		if room.cleared:
			label_info.text = "Room cleared"
		elif room.doors_locked:
			label_info.text = "Combat active - doors locked"
		else:
			label_info.text = "Normal room"

func update_door_colors(room: RoomData, current_pos: Vector2i, dungeon) -> void:
	var default_color := Color.CYAN
	var locked_color := Color.RED
	var boss_lead_color := Color(1.0, 0.65, 0.15)

	if room.doors_locked:
		door_up.color = locked_color
		door_down.color = locked_color
		door_left.color = locked_color
		door_right.color = locked_color
		return

	door_up.color = boss_lead_color if dungeon.door_leads_to_boss(current_pos, Vector2i.UP) and room.door_up else default_color
	door_down.color = boss_lead_color if dungeon.door_leads_to_boss(current_pos, Vector2i.DOWN) and room.door_down else default_color
	door_left.color = boss_lead_color if dungeon.door_leads_to_boss(current_pos, Vector2i.LEFT) and room.door_left else default_color
	door_right.color = boss_lead_color if dungeon.door_leads_to_boss(current_pos, Vector2i.RIGHT) and room.door_right else default_color
