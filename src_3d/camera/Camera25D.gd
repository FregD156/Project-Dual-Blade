class_name Camera25D
extends Camera3D

@export var target: Node3D = null
@export var follow_speed: float = 8.0
@export var horizontal_lead: float = 1.2
@export var vertical_lead: float = 0.5
@export var default_distance: float = 6.5
@export var height_offset: float = 1.2

var shake_intensity: float = 0.0
var shake_decay: float = 10.0

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
		
	var facing_sign: float = 1.0
	if "facing_direction" in target:
		facing_sign = float(target.facing_direction)
		
	var target_x: float = target.global_position.x + (facing_sign * horizontal_lead)
	var target_y: float = target.global_position.y + height_offset
	var target_z: float = default_distance
	
	var desired_pos = Vector3(target_x, target_y, target_z)
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
