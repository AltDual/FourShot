extends Node2D

@export var weapon_data: WeaponResource

const BULLET = preload("res://scenes/bullet.tscn")
@export var offset := 10.0
@onready var muzzle: Marker2D = $Marker2D

var can_fire: bool = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	var fire_input = Input.is_action_just_pressed("shoot") if not weapon_data.is_automatic else Input.is_action_pressed("shoot")
	
	if fire_input and can_fire:
		fire()
	


func fire() -> void:
	can_fire = false
	
	match weapon_data.pattern:
		"single":
			fire_single()
		"spread":
			fire_spread()
		"circle":
			fire_circle()

	await get_tree().create_timer(weapon_data.fire_rate).timeout
	can_fire = true

func fire_single() -> void:
	spawn_bullet(rotation)


func fire_spread() -> void:
	var count := weapon_data.pellet_count
	var spread := deg_to_rad(weapon_data.spread_angle)

	for i in range(count):
		var t := 0.0 if count == 1 else float(i) / (count - 1)
		var angle_offset: float = lerp(-spread / 2.0, spread / 2.0, t)
		spawn_bullet(rotation + angle_offset)


func fire_circle() -> void:
	var count := weapon_data.pellet_count

	for i in range(count):
		var angle := (TAU / count) * i
		spawn_bullet(angle)

func spawn_bullet(angle: float) -> void:
	var bullet = BULLET.instantiate()
	get_tree().root.add_child(bullet)

	bullet.global_position = muzzle.global_position
	bullet.rotation = angle

	# Optional if you implement it
	# bullet.setup(weapon_data.damage, weapon_data.bullet_speed, weapon_data.bullet_range)
