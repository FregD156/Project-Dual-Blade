class_name HitSparks3D
extends GPUParticles3D

func _ready() -> void:
	emitting = false
	one_shot = true

func trigger_burst(pos: Vector3, is_parry: bool = false) -> void:
	global_position = pos
	if is_parry:
		amount = 28
		lifetime = 0.35
		modulate = Color(1.5, 1.2, 0.3)
	else:
		amount = 16
		lifetime = 0.22
		modulate = Color(1.2, 0.4, 0.3)
	restart()
	emitting = true
