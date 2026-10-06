class_name PlayerStart3D
extends Marker3D

## PlayerStart3D: Điểm xuất phát của nhân vật ở đầu Map (Mục G)
## Quản lý vị trí khởi đầu khi vào World mới, bắt đầu ải, hoặc hồi sinh khi chưa có checkpoint.
## Tự động kiểm tra tính hợp lệ bằng Raycast xuống sàn và Capsule Shape-cast.
## Nếu vị trí hiện tại bị vướng/rơi khoảng trống, tự động dịch sang phải từng bước (0.25m) để tìm vị trí hợp lệ.

const STEP_X: float = 0.25
const MAX_SEARCH_STEPS: int = 20 # Dò tối đa 5.0m sang phải
const CAPSULE_RADIUS: float = 0.35
const CAPSULE_HEIGHT: float = 1.6

# Node vẽ debug F3
var _debug_label: Label3D = null
var _debug_mesh: MeshInstance3D = null

func _ready() -> void:
	add_to_group("player_start")
	global_position.z = 0.0
	_setup_debug_visuals()

## Kiểm tra và trả về tọa độ spawn hợp lệ nhất trên sàn
func get_valid_spawn_position(space_state: PhysicsDirectSpaceState3D) -> Vector3:
	var base_x = global_position.x
	var start_y = global_position.y
	
	if not space_state:
		return Vector3(base_x, start_y, 0.0)
		
	for i in range(MAX_SEARCH_STEPS):
		var check_x = base_x + (float(i) * STEP_X)
		var ray_from = Vector3(check_x, start_y + 2.0, 0.0)
		var ray_to = Vector3(check_x, start_y - 4.0, 0.0)
		var ray_query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1) # Layer 1: Terrain
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true
		
		var ray_hit = space_state.intersect_ray(ray_query)
		if not ray_hit.is_empty():
			var floor_y = ray_hit.position.y
			var candidate_pos = Vector3(check_x, floor_y + 0.1, 0.0)
			
			# Kiểm tra không bị lồng vào collider tường hoặc bậc thang
			var shape = CapsuleShape3D.new()
			shape.radius = CAPSULE_RADIUS
			shape.height = CAPSULE_HEIGHT
			var shape_query = PhysicsShapeQueryParameters3D.new()
			shape_query.shape = shape
			shape_query.transform = Transform3D(Basis(), candidate_pos + Vector3(0.0, CAPSULE_HEIGHT * 0.5, 0.0))
			shape_query.collision_mask = 1
			shape_query.exclude = [ray_hit.collider.get_rid()]
			
			var overlaps = space_state.intersect_shape(shape_query, 4)
			if overlaps.is_empty():
				return candidate_pos
				
	return Vector3(base_x, start_y, 0.0)

# --- VISUAL DEBUG CHO F3 ---
func _setup_debug_visuals() -> void:
	_debug_label = Label3D.new()
	_debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_debug_label.no_depth_test = true
	_debug_label.font_size = 20
	_debug_label.outline_size = 4
	_debug_label.position = Vector3(0.0, 2.0, 0.0)
	_debug_label.text = "[★] PlayerStart\nX=%.1f" % global_position.x
	_debug_label.modulate = Color(0.2, 1.0, 0.8, 1.0)
	_debug_label.visible = false
	add_child(_debug_label)
	
	_debug_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 0.15
	_debug_mesh.mesh = cyl
	_debug_mesh.position = Vector3(0.0, 0.08, 0.0)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 1.0, 0.8, 0.85)
	_debug_mesh.material_override = mat
	_debug_mesh.visible = false
	add_child(_debug_mesh)

func set_debug_visible(p_visible: bool) -> void:
	if _debug_label:
		_debug_label.visible = p_visible
	if _debug_mesh:
		_debug_mesh.visible = p_visible
