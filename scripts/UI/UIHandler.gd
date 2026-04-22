extends MarginContainer

@onready var slot1 = $VBoxContainer/Hotbar/Slot1
@onready var slot2 = $VBoxContainer/Hotbar/Slot2
@onready var ammo_text = $VBoxContainer/AmmoText

# Call this when the player picks up a new gun or spell
func update_slot_contents(slot_number: int, item_name: String, item_icon: Texture2D):
	var target_slot = slot1 if slot_number == 1 else slot2
	target_slot.get_node("VBoxContainer/WeaponName").text = item_name
	target_slot.get_node("VBoxContainer/WeaponIcon").texture = item_icon

# Call this when the player presses '1' or '2'
func set_active_slot(active_slot_number: int):
	if active_slot_number == 1:
		slot1.modulate = Color(1.0, 1.0, 1.0, 1.0) # Full brightness
		slot2.modulate = Color(0.5, 0.5, 0.5, 0.8) # Greyed out and slightly transparent
	else:
		slot1.modulate = Color(0.5, 0.5, 0.5, 0.8)
		slot2.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Call this when shooting, reloading, or switching items
func update_ammo(current: int, reserve: int, uses_ammo: bool):
	if uses_ammo:
		ammo_text.show()
		ammo_text.text = str(current) + " / " + str(reserve)
	else:
		# Hide the ammo text completely if holding a spell
		ammo_text.hide()
