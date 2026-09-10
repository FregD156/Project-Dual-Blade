class_name SlashSparks
extends Node2D

## Hiệu ứng vệt chém song đao bùng nổ tia lửa (Slash Impact Sparks)
## Tạo các vệt phát quang và tia lửa pixel văng ra theo hướng vung đao

var particles: Array[Dictionary] = []

var total_lifetime: float = 0.3

func setup(impact_dir: Vector2, is_crit: bool = false) -> void:
	var count = 10 if not is_crit else 16
	var base_color = Color(0.1, 0.9, 1.0, 1.0) if not is_crit else Color(1.0, 0.85, 0.2, 1.0) # Cyan vs Gold
	
	for i in range(count):
		var angle = impact_dir.angle() + randf_range(-1.0, 1.0)
		var speed = randf_range(60.0, 160.0) if not is_crit else randf_range(90.0, 220.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed,
			"color": base_color,
			"size": randf_range(1.5, 3.0),
			"life": randf_range(0.15, 0.28)
		})

func _process(delta: float) -> void:
	total_lifetime -= delta
	if total_lifetime <= 0.0:
		queue_free()
		return
	for p in particles:
		p["pos"] += p["vel"] * delta
		p["vel"] = p["vel"].move_toward(Vector2.ZERO, 300.0 * delta)
		p["life"] -= delta
		p["color"].a = clampf(p["life"] / 0.25, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	for p in particles:
		if p["life"] > 0:
			draw_rect(Rect2(p["pos"], Vector2(p["size"], p["size"])), p["color"])
			# Đốm sáng lõi trắng
			draw_rect(Rect2(p["pos"] + Vector2(0.5, 0.5), Vector2(1, 1)), Color(1, 1, 1, p["color"].a))
