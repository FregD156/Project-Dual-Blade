class_name HitSparks3D
extends CPUParticles3D

## HitSparks3D - Hiệu ứng tia lửa va chạm đao kiếm & phản đòn (Cross-Parry) chuẩn HD-2D
## Tự động căn chỉnh góc văng tia lửa, màu sắc rực rỡ và tự giải phóng bộ nhớ khi hoàn tất.

static func spawn_at(parent_node: Node, pos: Vector3, is_parry: bool = false, is_crit: bool = false, dir_x: float = 1.0) -> HitSparks3D:
	if not parent_node:
		return null
	var sparks = HitSparks3D.new()
	parent_node.add_child(sparks)
	sparks.trigger_burst(pos, is_parry, is_crit, dir_x)
	return sparks

func _init() -> void:
	emitting = false
	one_shot = true
	explosiveness = 0.95
	randomness = 0.6
	lifetime = 0.28
	amount = 20
	
	# Mesh tia lửa hình thoi nhỏ
	var quad = QuadMesh.new()
	quad.size = Vector2(0.08, 0.16)
	mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_override = mat

func trigger_burst(pos: Vector3, is_parry: bool = false, is_crit: bool = false, dir_x: float = 1.0) -> void:
	global_position = pos
	direction = Vector3(dir_x * 0.8, randf_range(0.2, 0.9), 0.0).normalized()
	spread = 45.0
	gravity = Vector3(0, -9.8, 0)
	initial_velocity_min = 4.5
	initial_velocity_max = 9.0
	
	if is_parry:
		amount = 32
		lifetime = 0.38
		color = Color(2.5, 2.2, 0.6, 1.0) # Vàng ánh kim chói lọi
		initial_velocity_min = 7.0
		initial_velocity_max = 14.0
		spread = 75.0
	elif is_crit:
		amount = 26
		lifetime = 0.32
		color = Color(2.5, 0.9, 0.2, 1.0) # Cam lửa chí mạng
		initial_velocity_min = 6.0
		initial_velocity_max = 11.0
	else:
		amount = 16
		lifetime = 0.24
		color = Color(2.0, 1.4, 0.8, 1.0) # Trắng bạc đao kiếm
		initial_velocity_min = 3.5
		initial_velocity_max = 7.5
		
	emitting = true
	
	# Tự hủy sau khi phát xong
	var timer = get_tree().create_timer(lifetime + 0.1)
	timer.timeout.connect(queue_free)
