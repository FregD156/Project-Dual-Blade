class_name DamageNumber
extends Node2D

## Hiển thị số sát thương nhảy lên (Floating Combat Text)
## Sát thương thường: Màu trắng cam, font pixel
## Sát thương chí mạng: Màu vàng kim rực rỡ, to hơn x1.4

func setup(amount: float, is_crit: bool = false, custom_color: Color = Color.WHITE) -> void:
	var label = Label.new()
	var font = preload("res://assets/fonts/pixel_font.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 8 if not is_crit else 11)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	if is_crit:
		label.text = "%d!" % round(amount)
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		label.text = "%d" % round(amount)
		if custom_color != Color.WHITE:
			label.add_theme_color_override("font_color", custom_color)
		else:
			label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9, 1.0))
			
	label.position = Vector2(-20, -10)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.custom_minimum_size = Vector2(40, 20)
	add_child(label)
	
	# Random drift arc
	var drift_x = randf_range(-18.0, 18.0)
	var rise_y = -26.0 if not is_crit else -34.0
	
	scale = Vector2(0.5, 0.5)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3) if is_crit else Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + rise_y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", position.x + drift_x, 0.5)
	
	var fade_tween = create_tween()
	fade_tween.tween_interval(0.28)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	fade_tween.tween_callback(queue_free)
