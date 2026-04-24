extends CharacterBody2D

const SPEED = 150.0

#var last_direction: Vector2 = Vector2.RIGHT
#var movement_locked: bool = false
#var require_input_release: bool = false
const HEALTH_UPGRADE = preload("res://resources/HealthUpgrade.tres")
const DAMAGE_UPGRADE = preload("res://resources/DamageUpgrade.tres")
const SPEED_UPGRADE = preload("res://resources/SpeedUpgrade.tres")


@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var gun = $Gun
@onready var reload_bar: ProgressBar = $ReloadBar
var reload_tween: Tween
var damage_tween: Tween

var max_health: int = 100
var current_health: int = 100
var current_xp: int = 0
var current_level: int = 1
var xp_thresholds: Array[int] = [100, 250, 500, 900, 1400, 2000]
var is_dead: bool = false
@onready var upgrade_menu = $UpgradeMenu
var bonus_damage: int = 0
var speed_multiplier: float = 1.0
var upgrade_pool: Array[UpgradeResource] = [HEALTH_UPGRADE, DAMAGE_UPGRADE, SPEED_UPGRADE]

#For Dash
@onready var dash_particles: GPUParticles2D = $GPUParticles2D
const DASH_SPEED: float = 450.0
const DASH_DURATION: float = 0.15
const DASH_COOLDOWN: float = 0.8
var is_dashing: bool = false
var dash_cooldown_remaining: float = 0.0
var is_invincible: bool = false  # i-frames flag


# --- WEAPON INVENTORY SYSTEM ---
@export var starting_weapons: Array[WeaponResource] = [null, null]
var weapon_inventory: Array[WeaponResource] = [null, null]
var active_weapon_index: int = 0

func _ready():
	add_to_group("player")
	SignalBus.health_changed.emit(current_health, max_health)
	SignalBus.xp_changed.emit(current_xp, xp_thresholds[0])
	
	# --- NEW: Connect to the gun's reload signals ---
	gun.reload_started.connect(_on_gun_reload_started)
	gun.reload_finished.connect(_on_gun_reload_finished)
	
	for i in range(starting_weapons.size()):
		if starting_weapons[i] != null:
			weapon_inventory[i] = starting_weapons[i].duplicate()
			
	if weapon_inventory[0] != null:
		equip_weapon(0)
		
	SignalBus.hotbar_updated.emit.call_deferred(weapon_inventory, active_weapon_index)
	upgrade_menu.upgrade_chosen.connect(_apply_upgrade)
	SignalBus.level_changed.connect(_on_level_up)
	gun.special_shot_fired.connect(_on_sniper_fired)

func _physics_process(_delta: float) -> void:
	if get_tree().paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if dash_cooldown_remaining > 0.0:
		dash_cooldown_remaining -= _delta
	
	if not is_dashing:
		var _move_input := Input.get_vector("left", "right", "up", "down")
		process_movement()
		var aim_dir = get_aim_direction()
		$Gun.position.x = sign(aim_dir.x) * 3.5

		process_animation(aim_dir)
		process_weapon_switching()
		if Input.is_action_just_pressed("dash") and dash_cooldown_remaining <= 0.0:
			_start_dash()
			
	move_and_slide()
		

# --- NEW METHODS ---
func process_weapon_switching() -> void:
	if Input.is_action_just_pressed("equip_slot_1") and active_weapon_index != 0:
		equip_weapon(0) # 0 is the first array slot (AK67)
	elif Input.is_action_just_pressed("equip_slot_2") and active_weapon_index != 1:
		equip_weapon(1) # 1 is the second array slot (Pistol)

func equip_weapon(index: int) -> void:
	if has_sniper:
		return
	if weapon_inventory[index] != null:
		active_weapon_index = index
		gun.equip(weapon_inventory[index])
		SignalBus.hotbar_updated.emit(weapon_inventory, active_weapon_index)

func get_aim_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return (mouse_pos - global_position).normalized()

func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:
		velocity = direction * SPEED * speed_multiplier
		#last_direction = direction
	else:
		velocity = Vector2.ZERO

func process_animation(aim_dir: Vector2) -> void:
	if velocity != Vector2.ZERO:
		play_animation("run", aim_dir)
	else:
		play_animation("idle", aim_dir)

func play_animation(prefix: String, dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	else:
		animated_sprite_2d.play(prefix + "_down")

#Damage
func take_damage(amount: int):
	if is_dead or is_invincible:
		return
	current_health = max(0, current_health - amount)
	SignalBus.health_changed.emit(current_health, max_health)
	
	flash_damage()
	
	if current_health == 0:
		_die()

func _die() -> void:
	is_dead = true
	set_physics_process(false)  # stop movement
	gun.can_fire = false         # stop shooting
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.queue_free()
	get_tree().paused = true
	
	if animated_sprite_2d.sprite_frames.has_animation("dying"):
		animated_sprite_2d.play("dying")
		await animated_sprite_2d.animation_finished
		await get_tree().create_timer(0.5).timeout

	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

#XP
func gain_xp(amount: int):
	current_xp += amount
	var threshold_index = current_level - 1
	var cap = xp_thresholds[threshold_index] if threshold_index < xp_thresholds.size() else 9999
	print("XP gained: ", current_xp, " / ", cap, " level: ", current_level)
	SignalBus.xp_changed.emit(current_xp, cap)
	_check_level_up()


func _check_level_up() -> void:
	var threshold_index = current_level - 1
	if threshold_index >= xp_thresholds.size():
		return  # max level reached
	if current_xp >= xp_thresholds[threshold_index]:
		current_xp -= xp_thresholds[threshold_index]
		current_level += 1
		print("Leveled up to: ", current_level)
		SignalBus.level_changed.emit(current_level)
		SignalBus.xp_changed.emit(current_xp, xp_thresholds[current_level - 1])

func _on_level_up(_level: int) -> void:
	var offered = _pick_random_upgrades(3)
	upgrade_menu.show_upgrades(offered)

func _pick_random_upgrades(count: int) -> Array[UpgradeResource]:
	var pool = upgrade_pool.duplicate()
	pool.shuffle()
	return pool.slice(0, count)

func _apply_upgrade(upgrade: UpgradeResource) -> void:
	match upgrade.type:
		UpgradeResource.UpgradeType.MAX_HEALTH:
			max_health += int(upgrade.value)
			current_health = min(current_health + int(upgrade.value), max_health)
			SignalBus.health_changed.emit(current_health, max_health)

		UpgradeResource.UpgradeType.SPEED:
			speed_multiplier += upgrade.value  # e.g. 0.2 = +20% speed

		UpgradeResource.UpgradeType.DAMAGE:
			bonus_damage += int(upgrade.value)

		UpgradeResource.UpgradeType.FIRE_RATE:
			if gun.weapon_data:
				gun.weapon_data.fire_rate = max(0.05, gun.weapon_data.fire_rate - upgrade.value)

		UpgradeResource.UpgradeType.BULLET_SPEED:
			if gun.weapon_data:
				gun.weapon_data.bullet_speed += upgrade.value

		UpgradeResource.UpgradeType.PIERCING:
			if gun.weapon_data:
				gun.weapon_data.piercing = true

		UpgradeResource.UpgradeType.PELLET_COUNT:
			if gun.weapon_data:
				gun.weapon_data.pellet_count += int(upgrade.value)

func _on_gun_reload_started(duration: float) -> void:
	reload_bar.visible = true
	reload_bar.max_value = duration
	reload_bar.value = 0.0

	# Kill the old animation if one is somehow still running
	if reload_tween:
		reload_tween.kill()

	# Create a smooth animation from 0 to the reload time
	reload_tween = create_tween()
	reload_tween.tween_property(reload_bar, "value", duration, duration)

func _on_gun_reload_finished() -> void:
	reload_bar.visible = false
	if reload_tween:
		reload_tween.kill()

#Code for first Boss
var special_weapon_boss = null  # reference to boss golem
var has_sniper: bool = false

const SNIPER_RESOURCE = preload("res://scripts/Gun/weapontypes/sniper_weapon.tres")

func equip_special_weapon(boss) -> void:
	has_sniper = true
	special_weapon_boss = boss
	gun.equip(SNIPER_RESOURCE)
	SignalBus.special_weapon_acquired.emit()

func has_special_weapon() -> bool:
	return has_sniper

func _on_sniper_fired() -> void:
	# Called by gun after the special weapon fires
	if has_sniper and special_weapon_boss:
		special_weapon_boss.hit_with_sniper()
	has_sniper = false
	special_weapon_boss = null
	# Re-equip previous weapon
	equip_weapon(active_weapon_index)
	SignalBus.special_weapon_used.emit()
func flash_damage() -> void:
	# Kill the previous tween if the player is hit rapidly
	if damage_tween:
		damage_tween.kill()
		
	# Ensure the sprite starts at its default color (white)
	animated_sprite_2d.modulate = Color(1, 1, 1, 1) 
	
	damage_tween = create_tween()
	
	# Step 1: Instantly turn the sprite red (or change 0.05 to make it fade to red)
	damage_tween.tween_property(animated_sprite_2d, "modulate", Color(1, 0, 0, 1), 0.05)
	
	# Step 2: Fade it back to normal over 0.15 seconds
	damage_tween.tween_property(animated_sprite_2d, "modulate", Color(1, 1, 1, 1), 0.15)
#Heal
func heal(amount: int) -> void:
	if is_dead:
		return
	current_health = min(current_health + amount, max_health)
	SignalBus.health_changed.emit(current_health, max_health)

#Dash
func _start_dash() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	# If no input, dash toward mouse instead
	if direction == Vector2.ZERO:
		direction = get_aim_direction()

	is_dashing = true
	is_invincible = true
	dash_cooldown_remaining = DASH_COOLDOWN

	# Particles
	dash_particles.emitting = true
	
	# Override velocity for the dash
	velocity = direction * DASH_SPEED
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.3, 0.05)

	await get_tree().create_timer(DASH_DURATION).timeout
	is_dashing = false

	# Small i-frame window after dash ends
	await get_tree().create_timer(0.2).timeout
	is_invincible = false
	dash_particles.emitting = false
	
	tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
