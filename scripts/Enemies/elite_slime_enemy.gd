extends RangedEnemy

func on_ready() -> void:
	max_health = 300
	damage = 4
	fire_rate = 0.8
	preferred_range = 150.0
	add_to_group("enemies")


func _on_shoot() -> void:
	# Shoot 3 bullets in a spread
	for angle_offset in [-10, -6, -2, 0, 2, 6, 10]:
		var dir = (player.global_position - muzzle.global_position).normalized()
		_spawn_bullet(dir.rotated(deg_to_rad(angle_offset)).angle())

func on_death() -> void:
	pass
