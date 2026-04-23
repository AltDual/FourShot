extends CharacterBody2D


# ---------------------------------------------------------------------------
# Stats
# ---------------------------------------------------------------------------
@export var max_health: int = 40
@export var move_speed: float = 60.0
@export var damage: int = 8
@export var bullet_speed: float = 400.0
@export var bullet_range: float = 600.0
@export var fire_rate: float = 1.5        # seconds between shots
@export var preferred_range: float = 200.0  # tries to stay this far away
@export var detection_range: float = 350.0  # must match DetectionArea radius
 
# ---------------------------------------------------------------------------
# Scene refs  (update paths if your nodes are named differently)
# ---------------------------------------------------------------------------
const ENEMY_BULLET = preload("res://scenes/enemy_bullet.tscn")
 
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea
 
# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------
enum State { IDLE, CHASE, STRAFE, SHOOT }
var state: State = State.IDLE
 
var current_health: int
var player: Node = null
var can_fire: bool = true
 
# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------
func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	detection_area.body_entered.connect(_on_body_entered_detection)
	detection_area.body_exited.connect(_on_body_exited_detection)
 
# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	_update_state()
 
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			_move_toward_player(delta)
		State.STRAFE:
			_strafe(delta)
		State.SHOOT:
			velocity = Vector2.ZERO
			_face_player()
			if can_fire:
				_shoot()
 
	move_and_slide()
	_update_animation()
 
# ---------------------------------------------------------------------------
# State logic
# ---------------------------------------------------------------------------
func _update_state() -> void:
	if player == null:
		state = State.IDLE
		return
 
	var dist = global_position.distance_to(player.global_position)
 
	if dist > detection_range:
		state = State.IDLE
	elif dist > preferred_range + 40:
		state = State.CHASE
	elif dist < preferred_range - 40:
		# Too close — back away via strafe/retreat
		state = State.STRAFE
	else:
		state = State.SHOOT
 
func _move_toward_player(delta: float) -> void:
	nav_agent.target_position = player.global_position
	var next = nav_agent.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * move_speed
 
func _strafe(delta: float) -> void:
	# Move perpendicular to the player to dodge while backing off
	var away = (global_position - player.global_position).normalized()
	var perp = Vector2(-away.y, away.x)
	velocity = (away + perp).normalized() * move_speed
 
func _face_player() -> void:
	var dir = (player.global_position - global_position).normalized()
	# Flip sprite based on player direction
	sprite.flip_h = dir.x < 0
 
# ---------------------------------------------------------------------------
# Shooting
# ---------------------------------------------------------------------------
func _shoot() -> void:
	can_fire = false
	_spawn_bullet()
	await get_tree().create_timer(fire_rate).timeout
	can_fire = true
 
func _spawn_bullet() -> void:
	var bullet = ENEMY_BULLET.instantiate()
	get_tree().root.add_child(bullet)
	bullet.global_position = muzzle.global_position
 
	var dir = (player.global_position - muzzle.global_position).normalized()
	bullet.rotation = dir.angle()
	bullet.setup(damage, bullet_speed, bullet_range)
 
# ---------------------------------------------------------------------------
# Damage & death
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	current_health -= amount
	# Flash or play hurt animation here
	if current_health <= 0:
		_die()
 
func _die() -> void:
	# Drop loot, emit signal, play death anim — stub for now
	queue_free()
 
# ---------------------------------------------------------------------------
# Detection area callbacks
# ---------------------------------------------------------------------------
func _on_body_entered_detection(body: Node) -> void:
	if body.is_in_group("player"):
		player = body
 
func _on_body_exited_detection(body: Node) -> void:
	if body == player:
		player = null
		state = State.IDLE
 
# ---------------------------------------------------------------------------
# Animation
# ---------------------------------------------------------------------------
func _update_animation() -> void:
	if velocity != Vector2.ZERO:
		sprite.play("walk")
	#elif state == State.SHOOT:
		#sprite.play("shoot")
	else:
		sprite.play("idle")
 
