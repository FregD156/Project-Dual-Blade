class_name Camera25D
extends Camera3D

## Camera25D - Hệ thống Camera 2.5D Cinematic phong cách HD-2D
## Hỗ trợ:
## - Khóa trục Z, bám sát nhân vật với độ trễ chuyển động mượt mà (smooth follow & lookahead)
## - Giới hạn biên bản đồ 120m (Clamp boundaries [-52, 52])
## - Hiệu ứng Rung lắc màn hình (Screen Shake) chân thực theo cường độ va chạm
## - Chế độ Đấu Trùm (Boss Mode): Tự động nới rộng góc nhìn (FOV & Distance) bao trọn đấu trường
## - Chiều sâu trường ảnh (Depth of Field Bokeh): Giữ nét mặt phẳng chiến đấu Z=0, làm mờ nhẹ kiến trúc xa

@export var target: Node3D = null
@export var follow_speed: float = 8.5
@export var horizontal_lead: float = 1.3
@export var vertical_lead: float = 0.5
@export var default_distance: float = 6.5
@export var height_offset: float = 1.2

@export var clamp_x_min: float = -52.0
@export var clamp_x_max: float = 54.0

var shake_intensity: float = 0.0
var shake_decay: float = 10.0

var is_boss_mode: bool = false
var target_distance: float = 6.5
var target_fov: float = 55.0

func _ready() -> void:
	target_distance = default_distance
	target_fov = fov
	_setup_dof_bokeh()

func _setup_dof_bokeh() -> void:
	var cam_attr = CameraAttributesPractical.new()
	cam_attr.dof_blur_far_enabled = true
	cam_attr.dof_blur_far_distance = 8.5
	cam_attr.dof_blur_far_transition = 6.5
	cam_attr.dof_blur_near_enabled = true
	cam_attr.dof_blur_near_distance = 2.5
	cam_attr.dof_blur_near_transition = 2.0
	cam_attr.dof_blur_amount = 0.06
	attributes = cam_attr

func set_boss_mode(enabled: bool) -> void:
	is_boss_mode = enabled
	if is_boss_mode:
		target_distance = 7.8
		target_fov = 62.0
	else:
		target_distance = default_distance
		target_fov = 55.0

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
		
	var facing_sign: float = 1.0
	if "facing_direction" in target:
		facing_sign = float(target.facing_direction)
		
	var raw_x: float = target.global_position.x + (facing_sign * horizontal_lead)
	var target_x: float = clampf(raw_x, clamp_x_min, clamp_x_max)
	var target_y: float = target.global_position.y + height_offset
	
	# Smooth lerp distance & FOV
	default_distance = lerpf(default_distance, target_distance, 3.5 * delta)
	fov = lerpf(fov, target_fov, 3.5 * delta)
	
	var desired_pos = Vector3(target_x, target_y, default_distance)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
	# Screenshake
	if shake_intensity > 0.001:
		var offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity),
			0.0
		)
		global_position += offset
		shake_intensity = max(0.0, shake_intensity - (shake_decay * delta))

func apply_shake(intensity: float = 0.15, decay: float = 8.0) -> void:
	shake_intensity = intensity
	shake_decay = decay
