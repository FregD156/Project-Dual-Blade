class_name SlashArc3D
extends MeshInstance3D

@export var duration: float = 0.18
var tween: Tween = null

func _ready() -> void:
	visible = false

func play_slash(combo_index: int, is_overdrive: bool = false) -> void:
	visible = true
	if tween:
		tween.kill()
		
	# Đổi màu vệt chém khi ở trạng thái Xuất Quỷ (màu đỏ rực rỡ / tím huyền ảo)
	var mat = get_active_material(0)
	if mat and mat is ShaderMaterial:
		var slash_col = Color(0.35, 0.75, 1.0) if not is_overdrive else Color(1.0, 0.15, 0.45)
		mat.set_shader_parameter("slash_color", slash_col)
		mat.set_shader_parameter("progress", 0.0)
		
	# Căn chỉnh kích thước và góc chém khớp tuyệt đối với hoạt họa sprite
	match combo_index:
		1:
			# Nhát 1: Chém chéo xuống góc 32 độ
			scale = Vector3(1.15, 1.15, 1.15)
			rotation_degrees = Vector3(12, 0, 32)
		2:
			# Nhát 2: Chém hất chéo lên ngược lại -32 độ (tạo chữ X hoàn chỉnh)
			scale = Vector3(1.2, 1.2, 1.2)
			rotation_degrees = Vector3(-12, 0, -32)
		3:
			# Nhát 3: Xoay người chém ngang góc rộng 360 độ
			scale = Vector3(1.45, 1.45, 1.45)
			rotation_degrees = Vector3(0, 0, 0)
		4:
			# Nhát 4 (Finisher): Kéo đại đao phóng lưỡi kiếm khí khổng lồ
			scale = Vector3(1.7, 1.7, 1.7)
			rotation_degrees = Vector3(0, 0, 85)
			
	tween = create_tween()
	tween.tween_method(func(v: float):
		if mat:
			mat.set_shader_parameter("progress", v)
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		visible = false
	)
