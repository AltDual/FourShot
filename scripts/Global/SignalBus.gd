extends Node

# Emit these whenever health or XP changes
signal health_changed(current_health, max_health)
signal xp_changed(current_xp)
signal ammo_changed(current: int, max: int)
signal hotbar_updated(inventory: Array, active_index: int)
