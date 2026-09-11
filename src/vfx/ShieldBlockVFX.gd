class_name ShieldBlockVFX
extends Node2D

## Hiệu ứng Khiên Chặn Đòn Tấn Công (Shield Barrier Block Arc & Flash)
## Hiển thị vòng bảo hộ ma thuật hình bán nguyệt phát quang khi Khiên chặn đứng đòn đánh

var barrier_color: Color = Color(0.1, 0.8, 1.0, 1.0) # Cobalt Blue
var life: float = 0.2
var max_life: float = 0.2
var radius: float = 24.0
var facing_dir: float = 1.0

func setup(pos: Vector2, direction: float = 1.0, color: Color = Color(0.1, 0.8, 1.0, 1.0)) -> void:
	global_position = pos
	facing_dir = direction
	barrier_color = color
	z_index = 35

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha = clampf(life / max_life, 0.0, 1.0)
	var progress = 1.0 - (life / max_life)
	var base_ang = 0.0 if facing_dir > 0 else PI
	var start_ang = base_ang - PI * 0.45
	var end_ang = base_ang + PI * 0.45
	
	var cur_radius = radius + progress * 8.0
	
	# Vòng hào quang ngoài
	var glow_col = barrier_color
	glow_col.a = alpha * 0.5
	draw_arc(Vector2.ZERO, cur_radius + 2.0, start_ang, end_ang, 16, glow_col, 5.0, true)
	
	# Vòng khiên chính
	var main_col = barrier_color
	main_col.a = alpha * 0.95
	draw_arc(Vector2.ZERO, cur_radius, start_ang, end_ang, 16, main_col, 2.5, true)
	
	# Lõi trắng kim loại phát sáng
	var white_col = Color(1.0, 1.0, 1.0, alpha)
	draw_arc(Vector2.ZERO, cur_radius - 1.0, start_ang, end_ang, 16, white_col, 1.2, true)
