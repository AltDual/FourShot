extends CanvasLayer

@onready var health_bar = $MarginContainer/TopLeft/HealthBar
@onready var xp_bar = $MarginContainer/TopLeft/XPBar
@onready var ammo_text: Label = $MarginContainer/BottomRight/AmmoText

func _ready():
	# Connect the global signals to functions in this script
	SignalBus.health_changed.connect(_on_health_changed)
	SignalBus.xp_changed.connect(_on_xp_changed)

func _on_health_changed(current_health: int, max_health: int):
	health_bar.max_value = max_health
	health_bar.value = current_health
func _on_xp_changed(current_xp: int):
	xp_bar.value = current_xp
func _on_ammo_changed(current_ammo: int, reserve_ammo: int) -> void:
	# This formats the text to look like "30 / 90"
	ammo_text.text = str(current_ammo) + " / " + str(reserve_ammo)
