class_name BrazierFire3D
extends Node3D

## BrazierFire3D - Ngọn lửa vạc Gothic bập bùng với ánh sáng động và tàn lửa bốc lên
## Tự động tạo OmniLight3D nhấp nháy và cụm hạt than hồng bốc lên từ chậu than.

@export var light_color: Color = Color(1.0, 0.65, 0.22, 1.0)
@export var base_energy: float = 2.8
@export var light_range: float = 9.0

var _light: OmniLight3D = null
var _time_offset: float = 0.0

func _ready() -> void:
	_time_offset = randf_range(0.0, 100.0)
	
	# 1. Đèn Omni hắt sáng lập lòe
	_light = OmniLight3D.new()
	_light.light_color = light_color
	_light.light_energy = base_energy
	_light.omni_range = light_range
	_light.omni_attenuation = 1.4
	_light.position = Vector3(0.0, 0.8, 0.3)
	_light.shadow_enabled = false # Không bật shadow để tối ưu FPS cao
	add_child(_light)
	
	# 2. Hạt tia lửa bốc lên từ miệng vạc
	var p = CPUParticles3D.new()
	p.position = Vector3(0.0, 0.6, 0.05)
	p.amount = 14
	p.lifetime = 0.85
	p.explosiveness = 0.0
	p.randomness = 0.7
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 22.0
	p.gravity = Vector3(0.0, 0.5, 0.0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 2.2
	p.color = Color(2.2, 1.2, 0.3, 0.8)
	
	var quad = QuadMesh.new()
	quad.size = Vector2(0.06, 0.09)
	p.mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p.material_override = mat
	
	add_child(p)

func _process(delta: float) -> void:
	if _light:
		var t = (Time.get_ticks_msec() * 0.001) + _time_offset
		# Kết hợp 2 hàm sóng sin tần số khác nhau tạo nhịp bập bùng tự nhiên của ngọn lửa
		var flicker = (sin(t * 8.5) * 0.25) + (sin(t * 19.3) * 0.15)
		_light.light_energy = base_energy + flicker
