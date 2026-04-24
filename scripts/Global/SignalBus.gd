extends Node

# Emit these whenever health or XP changes
signal health_changed(current_health, max_health)
signal ammo_changed(current: int, max: int)
signal hotbar_updated(inventory: Array, active_index: int)
signal xp_changed(current_xp: int, max_xp: int)
signal level_changed(new_level: int)

signal special_weapon_acquired
signal special_weapon_used
signal boss_progress(current: int, total: int)
