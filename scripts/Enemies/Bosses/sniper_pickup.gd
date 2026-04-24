extends Area2D

var boss = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.equip_special_weapon(boss)
		queue_free()
