class_name DamageNumber
extends Node2D

## Hiển thị số sát thương nhảy lên (Floating Combat Text)
## Dark Fantasy ARPG Styling:
## - Sát thương chí mạng: Vàng Hoàng Kim viền đổ bóng đậm, pop scale ấn tượng, giật nhẹ
## - Sát thương thường: Trắng cam viền đen sắc nét
## - Sát thương Player nhận: Đỏ thẫm máu (Blood Crimson)

func setup(amount: float, is_crit: bool = false, custom_color: Color = Color.WHITE) -> void:
	var label = Label.new()
	var font = preload("res://assets/fonts/pixel_font.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 9 if not is_crit else 13)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.06, 1.0))
	label.add_theme_constant_override("outline_size", 3 if is_crit else 2)
	
	if is_crit:
		label.text = "CRIT %d!" % round(amount)
		label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
	else:
		label.text = "%d" % round(amount)
		if custom_color != Color.WHITE:
			label.add_theme_color_override("font_color", custom_color)
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.88, 1.0))
			
	label.position = Vector2(-30, -10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(60, 20)
	add_child(label)
	
	# Random drift arc
	var drift_x = randf_range(-22.0, 22.0)
	var rise_y = -30.0 if not is_crit else -42.0
	
	scale = Vector2(0.4, 0.4)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35) if is_crit else Vector2(1.0, 1.0), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + rise_y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x + drift_x, 0.55)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.32)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.23)
	fade_tween.tween_callback(queue_free)
