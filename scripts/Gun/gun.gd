extends Node2D

signal weapon_switched(weapon: WeaponResource)
signal reload_started(duration: float)
signal reload_finished()

@export var weapon_data: WeaponResource
const BULLET = preload("res://scenes/bullet.tscn")

@onready var muzzle: Marker2D = $Marker2D
@onready var sprite: Sprite2D = $Sprite2D 
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound
@onready var muzzle_flash: Sprite2D = $Marker2D/MuzzleFlash

var can_fire: bool = true
var is_reloading: bool = false
var current_ammo: int = 0
var fire_cooldown: float = 0.0 
var flash_tween: Tween # Keep track of the tween so we can interrupt it

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if weapon_data == null: return
	
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
		
	# --- NEW: Process the weapon cooldown safely every frame ---
	if fire_cooldown > 0.0:
		fire_cooldown -= delta
		can_fire = false
	else:
		can_fire = true
	
	var fire_input = Input.is_action_just_pressed("shoot") if not weapon_data.is_automatic else Input.is_action_pressed("shoot")
	
	if Input.is_action_just_pressed("reload") and current_ammo < weapon_data.mag_size and not is_reloading:
		reload()
	
	if fire_input and can_fire and not is_reloading:
		if current_ammo > 0:
			fire()
		else:
			reload()

func equip(data: WeaponResource) -> void:
	# --- NEW: Cancel the reload bar if we swap weapons mid-reload ---
	if is_reloading:
		reload_finished.emit()
		
	# 1. Save the ammo of the OLD weapon before swapping
	if weapon_data != null:
		weapon_data.current_ammo = current_ammo
		
	# 2. Load the new weapon
	weapon_data = data
	is_reloading = false
	
	# 3. Add a swap delay (This stops the burst bug AND acts as your "equip time" mechanic!)
	fire_cooldown = 0.25 
	
	# 4. Load the saved ammo, or give max ammo if it is a fresh pickup
	if weapon_data.current_ammo == -1:
		current_ammo = weapon_data.mag_size
		weapon_data.current_ammo = current_ammo
	else:
		current_ammo = weapon_data.current_ammo
	
	if sprite and weapon_data.weapon_sprite_side:
		sprite.texture = weapon_data.weapon_sprite_side
		
	SignalBus.ammo_changed.emit.call_deferred(current_ammo, weapon_data.mag_size)
	weapon_switched.emit(weapon_data)

func reload() -> void:
	is_reloading = true
	var reloading_weapon = weapon_data # Keep track of what we are reloading
	
	reload_started.emit(weapon_data.reload_time)
	await get_tree().create_timer(weapon_data.reload_time).timeout
	
	# Only finish the reload if we are still holding the same gun!
	if is_reloading and weapon_data == reloading_weapon:
		current_ammo = weapon_data.mag_size
		weapon_data.current_ammo = current_ammo
		is_reloading = false
		SignalBus.ammo_changed.emit(current_ammo, weapon_data.mag_size)
		# --- NEW: Tell the player to hide the bar ---
		reload_finished.emit()

func fire() -> void:
	# --- CHANGED: Start the cooldown manually ---
	fire_cooldown = weapon_data.fire_rate
	current_ammo -= 1
	
	SignalBus.ammo_changed.emit(current_ammo, weapon_data.mag_size)
	play_shoot_effects()
	
	match weapon_data.pattern:
		"single":
			fire_single()
		"spread":
			fire_spread()
		"circle":
			fire_circle()

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
	
	var bonus = get_parent().bonus_damage if get_parent().has_method("take_damage") else 0
	bullet.setup(weapon_data.damage + bonus, weapon_data.bullet_speed, weapon_data.bullet_range)

# --- NEW FUNCTION ---
func play_shoot_effects() -> void:
	# 1. Play the audio
	# Note: To avoid sounds cutting each other off on high-fire-rate weapons, 
	# AudioStreamPlayer2D handles rapid firing okay, but varying the pitch slightly adds great juice!
	shoot_sound.pitch_scale = randf_range(0.9, 1.1)
	shoot_sound.play()
	
	# 2. Trigger the muzzle flash
	if flash_tween:
		flash_tween.kill() # Stop previous animation if we shoot really fast
		
	muzzle_flash.visible = true
	muzzle_flash.modulate.a = 1.0
	muzzle_flash.scale = Vector2(randf_range(0.1, 0.15), randf_range(0.1, 0.15)) # Randomize size slightly
	muzzle_flash.rotation_degrees = randf_range(0, 360) # Randomize rotation for variety
	
	# Fade it out over 0.05 seconds
	flash_tween = create_tween()
	flash_tween.tween_property(muzzle_flash, "modulate:a", 0.0, 0.05)
	flash_tween.tween_callback(func(): muzzle_flash.visible = false)
