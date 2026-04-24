extends RangedEnemy

var boss = null

func on_ready() -> void:
	max_health = 200
	damage = 10
	move_speed = 55.0
	fire_rate = 1.0
	preferred_range = 180.0
	xp_gain = 0
