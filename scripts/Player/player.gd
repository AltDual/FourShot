extends CharacterBody2D

const SPEED = 300.0

var last_direction: Vector2 = Vector2.RIGHT
#var movement_locked: bool = false
#var require_input_release: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var max_health: int = 100
var current_health: int = 100
var current_xp: int = 0

func _ready():
	# Initialize the UI when the player spawns
	SignalBus.health_changed.emit(current_health, max_health)
	SignalBus.xp_changed.emit(current_xp)

func _physics_process(_delta: float) -> void:
	var _move_input := Input.get_vector("left", "right", "up", "down")

	#if require_input_release:
		#if move_input == Vector2.ZERO:
			#require_input_release = false
		#else:
			#velocity = Vector2.ZERO
			#move_and_slide()
			#return

	#if movement_locked:
		#velocity = Vector2.ZERO
		#move_and_slide()
		#return

	process_movement()

	var aim_dir = get_aim_direction()
	$Gun.position.x = sign(aim_dir.x) * 10

	process_animation(aim_dir)
	move_and_slide()

func get_aim_direction() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	return (mouse_pos - global_position).normalized()

func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")

	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
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

#Damage and XP
func take_damage(amount: int):
	current_health -= amount
	# Emit the signal to tell the rest of the game the health changed
	SignalBus.health_changed.emit(current_health, max_health)

func gain_xp(amount: int):
	current_xp += amount
	SignalBus.xp_changed.emit(current_xp)
