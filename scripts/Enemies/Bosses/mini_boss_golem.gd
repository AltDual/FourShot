extends RangedEnemy

var boss = null

func on_ready() -> void:
	max_health = 100
	damage = 7
	move_speed = 55.0
	fire_rate = 1.5
	preferred_range = 180.0
	xp_gain = 0
