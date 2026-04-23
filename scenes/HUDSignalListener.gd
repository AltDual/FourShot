extends CanvasLayer

@onready var health_bar = $MarginContainer/TopLeft/HealthBar
@onready var xp_bar = $MarginContainer/TopLeft/XPBar
@onready var ammo_text: Label = $MarginContainer/BottomRight/AmmoText

@onready var slot1_icon: TextureRect = $MarginContainer/BottomRight/Hotbar/Slot1/VBoxContainer/WeaponIcon
@onready var slot1_name: Label = $MarginContainer/BottomRight/Hotbar/Slot1/VBoxContainer/WeaponName
@onready var slot2_icon: TextureRect = $MarginContainer/BottomRight/Hotbar/Slot2/VBoxContainer/WeaponIcon
@onready var slot2_name: Label = $MarginContainer/BottomRight/Hotbar/Slot2/VBoxContainer/WeaponName

func _ready():
	# Connect the global signals to functions in this script
	SignalBus.health_changed.connect(_on_health_changed)
	SignalBus.xp_changed.connect(_on_xp_changed)
	SignalBus.ammo_changed.connect(_on_ammo_changed)
	
	SignalBus.hotbar_updated.connect(_on_hotbar_updated)

func _on_health_changed(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
func _on_xp_changed(current_xp: int):
	xp_bar.value = current_xp
func _on_ammo_changed(current_ammo: int, reserve_ammo: int) -> void:
	ammo_text.text = str(current_ammo) + " / " + str(reserve_ammo)

# --- Function to populate the hotbar and highlight the active gun ---
func _on_hotbar_updated(inventory: Array, active_index: int) -> void:
	# Update Slot 1 (Primary)
	if inventory[0] != null:
		slot1_icon.texture = inventory[0].weapon_sprite_side
		slot1_name.text = inventory[0].weapon_name
	
	# Update Slot 2 (Secondary)
	if inventory[1] != null:
		slot2_icon.texture = inventory[1].weapon_sprite_side
		slot2_name.text = inventory[1].weapon_name
		
	# Visual highlight for active weapon (Dims the unequipped one)
	if active_index == 0:
		slot1_icon.modulate.a = 1.0 # Fully visible
		slot2_icon.modulate.a = 0.4 # Dimmed
	else:
		slot1_icon.modulate.a = 0.4 # Dimmed
		slot2_icon.modulate.a = 1.0 # Fully visible
