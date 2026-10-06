class_name SpawnPoint3D
extends Marker3D

## SpawnPoint3D: Điểm sinh quái vật thông minh 2.5D theo tầng (Tier-based Spawn Point)
## Quản lý phân tầng địa hình, loại quái vật cho phép, hướng quay mặc định,
## và tự động kiểm tra tính hợp lệ bằng Raycast + Shape-cast trước khi sinh quái.

@export_range(1, 4) var tier: int = 1 ## Tầng sàn: 1=Sàn chính, 2=Cầu vòm/Bậc thềm, 3=Đài cao/Tháp canh, 4=Đỉnh tháp
@export var allowed_enemy_types: PackedStringArray = PackedStringArray(["guard", "hound", "archer", "elite", "boss", "shambler", "lurker", "spitter"]) ## Loại quái cho phép
@export var default_facing: int = -1 ## Hướng nhìn ban đầu: -1 = Trái, 1 = Phải
@export var is_occupied: bool = false ## Đang có quái vật chiếm giữ điểm này hay không

# Cấu hình kiểm tra va chạm
const CAPSULE_RADIUS: float = 0.35
const CAPSULE_HEIGHT: float = 1.6
const FLOOR_CHECK_RAY_UP: float = 1.2
const FLOOR_CHECK_RAY_DOWN: float = 3.0

# Node vẽ debug
var _debug_label: Label3D = null
var _debug_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("spawn_points")
	# Khóa cứng trục Z = 0
	global_position.z = 0.0
	_setup_debug_visuals()

## Kiểm tra xem điểm spawn này có hợp lệ trên sàn và không bị lồng collider hay không
func validate_location(space_state: PhysicsDirectSpaceState3D) -> Dictionary:
	var result = {
		"valid": false,
		"spawn_pos": global_position,
		"reason": ""
	}
	
	if not space_state:
		result["reason"] = "Không tìm thấy DirectSpaceState3D"
		return result
		
	# 1. Khóa Z = 0
	var check_origin = Vector3(global_position.x, global_position.y, 0.0)
	
	# 2. Raycast từ trên xuống tìm mặt sàn cứng (collision_mask = 1: Stage Geometry)
	var ray_from = check_origin + Vector3(0.0, FLOOR_CHECK_RAY_UP, 0.0)
	var ray_to = check_origin - Vector3(0.0, FLOOR_CHECK_RAY_DOWN, 0.0)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1)
	ray_query.collide_with_areas = false
	ray_query.collide_with_bodies = true
	
	var ray_hit = space_state.intersect_ray(ray_query)
	if ray_hit.is_empty():
		result["reason"] = "Không tìm thấy mặt sàn (hố sâu hoặc khoảng không)"
		return result
		
	var floor_y = ray_hit.position.y
	var valid_spawn_pos = Vector3(check_origin.x, floor_y + 0.1, 0.0)
	
	# 3. Shape query kiểm tra không giao cắt lồng vào vật cản/tường
	var shape = CapsuleShape3D.new()
	shape.radius = CAPSULE_RADIUS
	shape.height = CAPSULE_HEIGHT
	
	var shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = shape
	shape_query.transform = Transform3D(Basis(), valid_spawn_pos + Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0))
	shape_query.collision_mask = 1 # Va chạm với địa hình
	shape_query.exclude = [ray_hit.collider.get_rid()]
	
	var overlaps = space_state.intersect_shape(shape_query, 4)
	if not overlaps.is_empty():
		result["reason"] = "Bị lồng vào collider tường hoặc bậc thang"
		return result
		
	result["valid"] = true
	result["spawn_pos"] = valid_spawn_pos
	result["reason"] = "Hợp lệ trên sàn"
	return result

## Kiểm tra loại quái có phù hợp với điểm này không
func can_spawn_enemy_type(enemy_type: String) -> bool:
	if is_occupied:
		return false
	if allowed_enemy_types.is_empty():
		return true
	for t in allowed_enemy_types:
		if t.to_lower() == enemy_type.to_lower():
			return true
	return false

# --- HỆ THỐNG DEBUG TRỰC QUAN (F3) ---
func _setup_debug_visuals() -> void:
	# Label hiển thị thông tin tầng
	_debug_label = Label3D.new()
	_debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_debug_label.no_depth_test = true
	_debug_label.font_size = 18
	_debug_label.outline_size = 4
	_debug_label.position = Vector3(0.0, 1.8, 0.0)
	_debug_label.visible = false
	add_child(_debug_label)
	
	# Mesh chỉ báo vòng tròn
	_debug_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.35
	cyl.height = 0.1
	_debug_mesh.mesh = cyl
	_debug_mesh.position = Vector3(0.0, 0.05, 0.0)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = _get_tier_color()
	_debug_mesh.material_override = mat
	_debug_mesh.visible = false
	add_child(_debug_mesh)
	
	_update_debug_text()

func _get_tier_color() -> Color:
	match tier:
		1: return Color(0.2, 0.9, 0.3, 0.8) # Xanh lá: Sàn 1
		2: return Color(0.2, 0.7, 1.0, 0.8) # Xanh lam: Cầu vòm 2
		3: return Color(1.0, 0.8, 0.2, 0.8) # Vàng cam: Đài cao 3
		_: return Color(0.9, 0.3, 0.9, 0.8) # Tím: Đỉnh cao 4

func _update_debug_text() -> void:
	if not _debug_label:
		return
	var types_str = ",".join(allowed_enemy_types)
	_debug_label.text = "[T%d] %s\n%s" % [tier, name, types_str]
	_debug_label.modulate = _get_tier_color()

func set_debug_visible(p_visible: bool) -> void:
	if _debug_label:
		_debug_label.visible = p_visible
	if _debug_mesh:
		_debug_mesh.visible = p_visible
