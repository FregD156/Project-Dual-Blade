class_name BloodSplatter
extends Node2D

## Hiệu ứng văng máu đỏ thẫm / chất nhờn quái vật (Pixel Blood Splatter)
## Tạo các hạt máu rơi parabol và đọng lại vệt máu mờ trên sàn

var drops: Array[Dictionary] = []

var total_lifetime: float = 0.4

func setup(impact_dir: Vector2, color_type: String = "red") -> void:
	var count = randi_range(8, 14)
	var blood_color = Color(0.75, 0.08, 0.08, 1.0) # Đỏ thẫm
	if color_type == "acid":
		blood_color = Color(0.2, 0.85, 0.2, 1.0) # Xanh axit
	elif color_type == "dark":
		blood_color = Color(0.4, 0.1, 0.5, 1.0) # Tím hư không
		
	for i in range(count):
		var angle = impact_dir.angle() + randf_range(-0.8, 0.8)
		var speed = randf_range(50.0, 140.0)
		drops.append({
			"pos": Vector2.ZERO,
			"vel": Vector2.RIGHT.rotated(angle) * speed + Vector2(0, -randf_range(30, 80)),
			"color": blood_color,
			"size": randf_range(1.5, 2.5),
			"life": randf_range(0.2, 0.4)
		})

func _process(delta: float) -> void:
	total_lifetime -= delta
	if total_lifetime <= 0.0:
		queue_free()
		return
	for d in drops:
		d["vel"].y += 400.0 * delta # Trọng lực hạt máu
		d["vel"].x = move_toward(d["vel"].x, 0.0, 80.0 * delta)
		d["pos"] += d["vel"] * delta
		d["life"] -= delta
		d["color"].a = clampf(d["life"] / 0.35, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	for d in drops:
		if d["life"] > 0:
			draw_rect(Rect2(d["pos"], Vector2(d["size"], d["size"])), d["color"])
