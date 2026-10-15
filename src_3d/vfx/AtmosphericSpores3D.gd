class_name AtmosphericSpores3D
extends CPUParticles3D

## Bào Tử Huyết Mộc & Axit Lơ Lửng 3D (World 2 Atmospheric Spores)
## Tạo không gian cống ngầm ma quái với các hạt bào tử phát quang trôi bồng bềnh trong không khí.

func _ready() -> void:
	amount = 140
	lifetime = 8.0
	preprocess = 4.0
	speed_scale = 0.75
	explosiveness = 0.0
	randomness = 0.85

	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = Vector3(60.0, 7.5, 2.0)

	direction = Vector3(0.5, 0.8, 0.0).normalized()
	spread = 60.0
	gravity = Vector3(0.02, 0.08, 0.0) # Bồng bềnh bay lượn
	initial_velocity_min = 0.3
	initial_velocity_max = 1.2

	scale_amount_min = 0.5
	scale_amount_max = 1.6

	color = Color(1.8, 0.35, 0.65, 0.5) # Bào tử đỏ tím ma mị

	var quad = QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	mesh = quad

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_override = mat

	emitting = true
