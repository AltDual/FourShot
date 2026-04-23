extends Node2D

signal weapon_switched(weapon: WeaponResource)
signal ammo_changed(current: int, max: int) # Useful for your Ammo HUD later

@export var weapon_data: WeaponResource
const BULLET = preload("res://scenes/bullet.tscn")
@onready var muzzle: Marker2D = $Marker2D
@onready var sprite: Sprite2D = $Sprite2D

var can_fire: bool = true
var is_reloading: bool = false
var current_ammo: int = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if weapon_data == null: return
	
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	var fire_input = Input.is_action_just_pressed("shoot") if not weapon_data.is_automatic else Input.is_action_pressed("shoot")
	
	# Handle Reload Input
	if Input.is_action_just_pressed("reload") and current_ammo < weapon_data.mag_size and not is_reloading:
		reload()
	
	# Handle Firing
	if fire_input and can_fire and not is_reloading:
		if current_ammo > 0:
			fire()
		else:
			reload() # Auto-reload when empty (optional, but feels good)

func equip(data: WeaponResource) -> void:
	weapon_data = data
	is_reloading = false
	can_fire = true
	# Give full ammo on initial pickup, or you can track ammo per inventory slot later
	current_ammo = weapon_data.mag_size 
	# --- NEW: Update the visual sprite to match the weapon data ---
	if sprite and weapon_data.weapon_sprite_side:
		sprite.texture = weapon_data.weapon_sprite_side
	SignalBus.ammo_changed.emit.call_deferred(current_ammo, weapon_data.mag_size)

func reload() -> void:
	is_reloading = true
	# Simulate reload time
	await get_tree().create_timer(weapon_data.reload_time).timeout
	
	current_ammo = weapon_data.mag_size
	is_reloading = false
	SignalBus.ammo_changed.emit.call_deferred(current_ammo, weapon_data.mag_size)

func fire() -> void:
	can_fire = false
	current_ammo -= 1
	SignalBus.ammo_changed.emit.call_deferred(current_ammo, weapon_data.mag_size)
	
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
	bullet.setup(weapon_data.damage, weapon_data.bullet_speed, weapon_data.bullet_range)
