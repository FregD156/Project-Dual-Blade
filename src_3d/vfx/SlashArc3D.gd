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
		var slash_col = Color(0.3, 0.7, 1.0) if not is_overdrive else Color(1.0, 0.2, 0.4)
		mat.set_shader_parameter("slash_color", slash_col)
		mat.set_shader_parameter("progress", 0.0)
		
	# Xoay góc vệt chém theo từng nhát combo (X chéo, ngang, v.v.)
	match combo_index:
		1:
			rotation_degrees = Vector3(25, 0, 35)
		2:
			rotation_degrees = Vector3(-25, 0, -35)
		3:
			rotation_degrees = Vector3(0, 0, 0) # Ngang
		4:
			rotation_degrees = Vector3(0, 0, 90) # Dọc Finisher
			
	tween = create_tween()
	tween.tween_method(func(v: float):
		if mat:
			mat.set_shader_parameter("progress", v)
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		visible = false
	)
