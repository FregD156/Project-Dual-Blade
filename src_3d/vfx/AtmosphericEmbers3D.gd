class_name AtmosphericEmbers3D
extends CPUParticles3D

## AtmosphericEmbers3D - Bụi tro và tàn lửa bay lơ lửng trong không khí Gothic
## Tạo chiều sâu không gian (Atmospheric Depth) đặc trưng của game Dark Fantasy HD-2D.

func _ready() -> void:
	amount = 120
	lifetime = 7.0
	preprocess = 4.0
	speed_scale = 0.8
	explosiveness = 0.0
	randomness = 0.8
	
	# Hạt lơ lửng trong hộp chữ nhật bao trọn hành lang 120m x 15m x 4m
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = Vector3(60.0, 7.5, 2.0)
	
	# Hạt gió trôi nhẹ sang phải và bay lên từ từ
	direction = Vector3(1.0, 0.35, 0.0).normalized()
	spread = 35.0
	gravity = Vector3(0.05, 0.12, 0.0) # Nổi bồng bềnh
	initial_velocity_min = 0.4
	initial_velocity_max = 1.6
	
	scale_amount_min = 0.6
	scale_amount_max = 1.8
	
	color = Color(1.8, 1.1, 0.45, 0.45) # Ánh vàng cam tro tàn
	
	var quad = QuadMesh.new()
	quad.size = Vector2(0.045, 0.045)
	mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_override = mat
	
	emitting = true
