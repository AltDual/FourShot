extends GPUParticles2D

@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	emitting = true
	
	# Create a tween to animate the light fading out
	var tween = create_tween()
	# Smoothly transition the light's 'energy' to 0.0 over the exact lifetime of the particles
	tween.tween_property(light, "energy", 0.0, lifetime).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	await finished
	queue_free()
