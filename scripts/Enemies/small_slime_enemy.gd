extends RangedEnemy

func on_ready() -> void:
	max_health = 80
	damage = 15
	fire_rate = 0.8
	preferred_range = 150.0


func _on_shoot() -> void:
	# Shoot 3 bullets in a spread
	for angle_offset in [-15, 0, 15]:
		var dir = (player.global_position - muzzle.global_position).normalized()
		_spawn_bullet(dir.rotated(deg_to_rad(angle_offset)).angle())

func on_death() -> void:
	pass
