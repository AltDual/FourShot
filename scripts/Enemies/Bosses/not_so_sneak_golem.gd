extends RangedEnemy

const MINI_GOLEM = preload("res://scenes/mini_golem.tscn")
const MINI_BOSS_GOLEM = preload("res://scenes/mini_boss_golem.tscn")
const SNIPER_PICKUP = preload("res://scenes/sniper_pickup.tscn")

var hits_remaining: int = 4
var mini_golems_killed: int = 0
var mini_golems_needed: int = 5
var mini_boss_alive: bool = false
var is_immune: bool = true
var player_has_sniper: bool = false  # boss reacts to this
var summon_timer: float = 0.0
var summon_interval: float = 8.0

# Evasion speeds
const NORMAL_SPEED: float = 60.0
const EVADE_SPEED: float = 200.0

func on_ready() -> void:
	max_health = 9999
	move_speed = NORMAL_SPEED
	preferred_range = 300.0
	detection_range = 9999
	xp_gain = 500
	_start_teleport_loop()

# ---------------------------------------------------------------------------
# Override physics to check sniper state every frame
# ---------------------------------------------------------------------------
func _physics_process(delta: float) -> void:
	# Check if player is holding sniper — boss reacts
	var p = get_tree().get_first_node_in_group("player")
	if p:
		player_has_sniper = p.has_special_weapon()
		move_speed = EVADE_SPEED if player_has_sniper else NORMAL_SPEED

	summon_timer += delta
	if summon_timer >= summon_interval:
		summon_timer = 0.0
		_summon_mini_golems()
	super._physics_process(delta)

# ---------------------------------------------------------------------------
# Immune to normal bullets
# ---------------------------------------------------------------------------
func take_damage(amount: int) -> void:
	if is_immune:
		_flash_immune()
		return

func hit_with_sniper() -> void:
	hits_remaining -= 1
	is_immune = true
	move_speed = NORMAL_SPEED
	_flash_hit()
	SignalBus.boss_progress.emit(hits_remaining, 4)
	if hits_remaining <= 0:
		_die()
	else:
		# Summon more aggressively each phase
		summon_interval = max(4.0, 4.0 - ((4 - hits_remaining) * 0.7))

# ---------------------------------------------------------------------------
# Summoning
# ---------------------------------------------------------a------------------
func _summon_mini_golems() -> void:
	var bounds = Rect2(80, 80, 1100, 560)
	var count = 2 + (4 - hits_remaining)  # more per phase
	for i in range(count):
		var mini = MINI_GOLEM.instantiate()
		get_parent().add_child(mini)
		mini.global_position = _random_pos(bounds)
		mini.tree_exited.connect(_on_mini_golem_killed)

func _on_mini_golem_killed() -> void:
	mini_golems_killed += 1
	SignalBus.boss_progress.emit(mini_golems_killed, mini_golems_needed)
	if mini_golems_killed >= mini_golems_needed and not mini_boss_alive:
		mini_golems_killed = 0
		_spawn_mini_boss()

func _spawn_mini_boss() -> void:
	mini_boss_alive = true
	var mini_boss = MINI_BOSS_GOLEM.instantiate()
	get_parent().add_child(mini_boss)
	mini_boss.global_position = global_position + Vector2(200, 0)
	mini_boss.boss = self
	mini_boss.tree_exited.connect(_on_mini_boss_killed)

func _on_mini_boss_killed() -> void:
	mini_boss_alive = false
	is_immune = false  # vulnerable now
	_spawn_sniper_pickup()

func _spawn_sniper_pickup() -> void:
	var pickup = SNIPER_PICKUP.instantiate()
	get_parent().add_child(pickup)
	pickup.global_position = global_position + Vector2(0, 100)
	pickup.boss = self

# ---------------------------------------------------------------------------
# Teleport — erratic when player has sniper
# ---------------------------------------------------------------------------
func _start_teleport_loop() -> void:
	while not is_dead:
		var delay = 1.0 if player_has_sniper else 3.5
		await get_tree().create_timer(delay).timeout
		if not is_dead:
			_teleport()

func _teleport() -> void:
	var bounds = Rect2(100, 100, 1080, 520)
	global_position = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)

func _random_pos(bounds: Rect2) -> Vector2:
	return Vector2(
		randf_range(bounds.position.x + 80, bounds.end.x - 80),
		randf_range(bounds.position.y + 80, bounds.end.y - 80)
	)

func _flash_immune() -> void:
	sprite.modulate = Color(0.5, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

func _flash_hit() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.3).timeout
	sprite.modulate = Color.WHITE
