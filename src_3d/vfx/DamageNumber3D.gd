class_name DamageNumber3D
extends Label3D

func setup(amount: float, pos: Vector3, is_crit: bool = false, is_parry: bool = false) -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	global_position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(0.2, 0.5), 0.1)
	
	if is_parry:
		text = "PARRY!"
		modulate = Color(1.0, 0.9, 0.2)
		pixel_size = 0.009
	elif is_crit:
		text = "%d!" % int(amount)
		modulate = Color(1.0, 0.2, 0.2)
		pixel_size = 0.008
	else:
		text = "%d" % int(amount)
		modulate = Color(1.0, 0.9, 0.9)
		pixel_size = 0.006
		
	outline_modulate = Color(0.05, 0.05, 0.08)
	outline_size = 12
	
	var tween = create_tween().set_parallel(true)
	# Bay lên trên và tỏa nhẹ sang bên
	var target_pos = global_position + Vector3(randf_range(-0.4, 0.4), 0.9, 0.0)
	tween.tween_property(self, "global_position", target_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector3(1.25, 1.25, 1.25), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "scale", Vector3(0.8, 0.8, 0.8), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_delay(0.2)
	tween.chain().tween_callback(queue_free)
