class_name BladeDanceSlashVFX
extends Node2D

## Hiệu ứng Nhát Chém Vũ Điệu Bão Đao (Blade Dance Cinematic Slash Arc)
## Vẽ các đường cung kiếm quang cực đại xé gió (Arc Slash) chém chéo Anime / ARPG
## Kèm tia chớp phát quang lướt qua mục tiêu và tia sáng vỡ tung

var arc_angle: float = 0.0
var arc_radius: float = 46.0
var slash_color: Color = Color(0.0, 0.95, 1.0, 1.0)
var core_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var life: float = 0.22
var max_life: float = 0.22
var is_ssr: bool = false
var spark_lines: Array[Dictionary] = []

func setup(pos: Vector2, angle: float, radius: float = 46.0, ssr: bool = false) -> void:
	global_position = pos
	arc_angle = angle
	arc_radius = radius
	is_ssr = ssr
	z_index = 40 # Hiển thị trên đầu nhân vật và quái
	
	if is_ssr:
		slash_color = Color(1.0, 0.2, 0.85, 1.0) # Hồng tím Thần Khí SSR
	else:
		slash_color = Color(0.05, 0.95, 1.0, 1.0) # Neon Cyan phát quang
		
	# Tạo các tia kiếm khí phóng ra xé toạc không gian
	for i in range(10):
		var sp_ang = arc_angle + randf_range(-0.7, 0.7)
		var sp_len = randf_range(16.0, 38.0)
		spark_lines.append({
			"start": Vector2.RIGHT.rotated(sp_ang) * (arc_radius * 0.35),
			"end": Vector2.RIGHT.rotated(sp_ang) * (arc_radius * 0.35 + sp_len),
			"width": randf_range(1.5, 3.0)
		})

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var progress = 1.0 - (life / max_life)
	var alpha = clampf(life / max_life, 0.0, 1.0)
	
	# Vẽ cung kiếm quang (Slash Arc)
	var start_angle = arc_angle - PI * 0.42
	var end_angle = arc_angle + PI * 0.42
	var current_end = lerp(start_angle, end_angle, clampf(progress * 2.2, 0.0, 1.0))
	
	var outer_col = slash_color
	outer_col.a = alpha * 0.9
	var core_col = core_color
	core_col.a = alpha
	
	# Vệt quầng sáng rộng
	draw_arc(Vector2.ZERO, arc_radius + 2.0, start_angle, current_end, 20, Color(outer_col.r, outer_col.g, outer_col.b, alpha * 0.4), 8.0, true)
	# Vệt kiếm quang phát sáng
	draw_arc(Vector2.ZERO, arc_radius, start_angle, current_end, 20, outer_col, 4.0, true)
	# Lõi ánh sáng trắng cực bén
	draw_arc(Vector2.ZERO, arc_radius, start_angle, current_end, 20, core_col, 1.8, true)
	
	# Tia kiếm khí phóng ra
	for sp in spark_lines:
		var line_col = slash_color
		line_col.a = alpha * 0.85
		draw_line(sp["start"], sp["end"], line_col, sp["width"] * alpha)
