class_name StageManager3D
extends Node3D

## StageManager3D: Quản lý vòng lặp Vượt Ải qua từng map 1.1 -> 1.10 trong không gian 2.5D Cel-Shaded
## Tuân thủ chuẩn Detail.md Phần A.IV, A.V, Phần C và Phần D:
## - Checkpoint 1.1, 1.5 (Quái Tinh Anh), 1.9 (Safe Haven Bệ Thờ), 1.10 (Boss Thống Lĩnh Thiết Vệ)
## - Cơ chế Phân Nhánh Phòng (Portal Choice): Cổng Đao Kiếm (Combat) vs Cổng Sinh Mệnh (Sustain)
## - Quái vật phân bố theo 4 tầng sàn của Cổ Thành Bastion (80m)
## - Cơ chế tính máu & dame ARPG chuẩn (Mitigation% = DEF/(DEF+50))

signal stage_changed(stage_str: String, title: String)
signal stage_cleared(stage_str: String)

enum RoomBranch { STANDARD = 0, COMBAT = 1, SUSTAIN = 2 }

@export var current_world: int = 1
@export var current_stage: int = 1
var current_branch: RoomBranch = RoomBranch.STANDARD
var stage_in_progress: bool = false

# Preload các Scene Quái 3D
const SCENE_GUARD = preload("res://scenes_3d/EnemyRustyGuard3D.tscn")
const SCENE_ARCHER = preload("res://scenes_3d/EnemyArcher3D.tscn")
const SCENE_HOUND = preload("res://scenes_3d/EnemyChainHound3D.tscn")
const SCENE_ELITE = preload("res://scenes_3d/EnemyEliteExecutioner3D.tscn")
const SCENE_BOSS = preload("res://scenes_3d/BossIroncladCommander3D.tscn")
const SCENE_PORTAL = preload("res://scenes_3d/Portal3D.tscn")
const SCENE_ALTAR = preload("res://scenes_3d/SafeHavenAltar3D.tscn")
const SCENE_DROP = preload("res://scenes_3d/DropItem3D.tscn")
const SCENE_SUMMON = preload("res://scenes_3d/SummonEffect3D.tscn")
const SpawnPoint3D = preload("res://src_3d/world/SpawnPoint3D.gd")
const PlayerStart3D = preload("res://src_3d/world/PlayerStart3D.gd")
const SoundManager3D = preload("res://src_3d/audio/SoundManager3D.gd")

var active_enemies: Array = []
var active_portals: Array = []
var active_altar: Node3D = null

var _stuck_watchdog_timer: float = 0.0
const WATCHDOG_INTERVAL: float = 1.0
var _debug_spawn_overlay: bool = false
var _debug_hud_layer: CanvasLayer = null
var _debug_hud_label: RichTextLabel = null

func _process(delta: float) -> void:
	if _debug_spawn_overlay:
		_update_debug_hud_content()
		
	if not stage_in_progress or active_enemies.is_empty():
		return
		
	_stuck_watchdog_timer += delta
	if _stuck_watchdog_timer >= WATCHDOG_INTERVAL:
		_stuck_watchdog_timer = 0.0
		_check_active_enemies_watchdog()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_debug_spawn_overlay = not _debug_spawn_overlay
			_toggle_spawn_debug(_debug_spawn_overlay)

func _setup_debug_hud() -> void:
	if _debug_hud_layer:
		return
	_debug_hud_layer = CanvasLayer.new()
	_debug_hud_layer.layer = 120
	add_child(_debug_hud_layer)
	
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(16, 120)
	panel.custom_minimum_size = Vector2(380, 220)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.1, 0.85)
	style.border_color = Color(0.2, 0.8, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	_debug_hud_layer.add_child(panel)
	
	_debug_hud_label = RichTextLabel.new()
	_debug_hud_label.bbcode_enabled = true
	_debug_hud_label.fit_content = true
	_debug_hud_label.custom_minimum_size = Vector2(360, 200)
	panel.add_child(_debug_hud_label)
	_debug_hud_layer.visible = false

func _update_debug_hud_content() -> void:
	if not _debug_hud_label or not _debug_spawn_overlay:
		return
	var text = "[color=#33e6ff][b]=== DEBUG OVERLAY (F3) ===[/b][/color]\n"
	text += "[color=#ffff66]Ải:[/color] %d.%d | [color=#ffff66]Nhánh:[/color] %s | [color=#ffff66]Tiến độ:[/color] %s\n" % [
		current_world, current_stage,
		"Đao Kiếm" if current_branch == RoomBranch.COMBAT else ("Sinh Mệnh" if current_branch == RoomBranch.SUSTAIN else "Tiêu Chuẩn"),
		"Đang Đấu" if stage_in_progress else "Đã Dọn Sạch (Cổng Mở)"
	]
	
	var p_start = get_tree().get_nodes_in_group("player_start")
	if p_start.size() > 0:
		text += "[color=#66ffb2]PlayerStart:[/color] %s (Hợp lệ trên sàn)\n" % str(p_start[0].global_position)
	else:
		text += "[color=#ff6666]PlayerStart:[/color] Không tìm thấy\n"
		
	var sps = get_tree().get_nodes_in_group("spawn_points")
	text += "[color=#ffb366]SpawnPoints:[/color] %d điểm đăng ký\n" % sps.size()
	
	text += "[color=#ff6666][b]Quái Đang Sống (%d):[/b][/color]\n" % active_enemies.size()
	if active_enemies.is_empty():
		text += "  [i]Không có quái (Sàn đấu an toàn)[/i]\n"
	else:
		for i in range(min(active_enemies.size(), 6)):
			var e = active_enemies[i]
			if is_instance_valid(e):
				text += "  • [b]%s[/b] (T%d) | HP: %.0f/%.0f | Pos: (%.1f, %.1f)\n" % [
					e.enemy_name, e.assigned_tier, e.current_hp, e.max_hp, e.global_position.x, e.global_position.y
				]
	_debug_hud_label.text = text

func _toggle_spawn_debug(p_visible: bool) -> void:
	var sps = get_tree().get_nodes_in_group("spawn_points")
	for sp in sps:
		if sp.has_method("set_debug_visible"):
			sp.set_debug_visible(p_visible)
			
	var p_starts = get_tree().get_nodes_in_group("player_start")
	for ps in p_starts:
		if ps.has_method("set_debug_visible"):
			ps.set_debug_visible(p_visible)
			
	if not _debug_hud_layer:
		_setup_debug_hud()
	if _debug_hud_layer:
		_debug_hud_layer.visible = p_visible
	if p_visible:
		_update_debug_hud_content()
		
	print("[StageManager3D] Debug Overlay: %s (SpawnPoints: %d, PlayerStart: %d)" % [
		"BẬT" if p_visible else "TẮT", sps.size(), p_starts.size()
	])

func _ready() -> void:
	# Kết nối Bản đồ Fast Travel nếu có
	var map_ui = get_node_or_null("../FastTravelMapUI")
	if map_ui and map_ui.has_signal("checkpoint_selected"):
		map_ui.checkpoint_selected.connect(_on_fast_travel_selected)

	# Khôi phục mốc stage từ CheckpointManager nếu trùng world
	var cp_mgr = CheckpointManager.get_instance()
	if cp_mgr.current_world == current_world and cp_mgr.current_checkpoint_stage > 0:
		current_stage = cp_mgr.current_checkpoint_stage

	# Bắt đầu tại Ải chỉ định khi tải scene
	call_deferred("start_stage", current_world, current_stage, current_branch)

func _on_fast_travel_selected(world: int, stage: int) -> void:
	if world != current_world:
		var target_scene = "res://scenes_3d/World1_Bastion_3D.tscn" if world == 1 else "res://scenes_3d/World2_Crimson_Catacombs_3D.tscn"
		if ResourceLoader.exists(target_scene):
			var cp_mgr = CheckpointManager.get_instance()
			cp_mgr.current_world = world
			cp_mgr.current_checkpoint_stage = stage
			get_tree().change_scene_to_file(target_scene)
			return
	start_stage(world, stage, RoomBranch.STANDARD, true)


func start_stage(world: int, stage: int, branch: RoomBranch = RoomBranch.STANDARD, is_fast_travel: bool = false) -> void:
	current_world = world
	current_stage = stage
	current_branch = branch
	stage_in_progress = true

	# Đăng ký Checkpoint tự động tại các mốc 1, 5, 9, 10
	if current_stage in [1, 5, 9, 10]:
		CheckpointManager.get_instance().activate_checkpoint(current_world, current_stage)

	var stage_str = "%d.%d" % [current_world, current_stage]
	var title = _get_stage_title(current_world, current_stage, current_branch)
	
	# Thông báo banner lên HUD
	var hud = get_node_or_null("../HUD3D")
	if hud and hud.has_method("show_stage_banner"):
		hud.show_stage_banner("ẢI " + stage_str + " — " + title)

	stage_changed.emit(stage_str, title)

	# Đặt lại vị trí người chơi và hồi giáp (tuân thủ mục G)
	_reposition_player(is_fast_travel)
	_clear_portals()
	_spawn_stage_wave(current_world, current_stage, current_branch)

func _reposition_player(is_fast_travel_checkpoint: bool = false) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		var spawn_pos = Vector3(-10.0, 0.5, 0.0)
		
		# Mục G: Khi vào World mới, bắt đầu ải, hoặc hồi sinh:
		# Luôn spawn tại PlayerStart ở đầu Map, tìm vị trí hợp lệ bằng Raycast
		if not is_fast_travel_checkpoint or current_stage == 1:
			var start_nodes = get_tree().get_nodes_in_group("player_start")
			var space_state = get_world_3d().direct_space_state if get_world_3d() else null
			if start_nodes.size() > 0 and is_instance_valid(start_nodes[0]):
				var ps = start_nodes[0]
				if ps.has_method("get_valid_spawn_position"):
					spawn_pos = ps.get_valid_spawn_position(space_state)
				else:
					spawn_pos = ps.global_position
		else:
			# Fast Travel đến checkpoint cụ thể đã mở
			if current_stage == 5:
				spawn_pos = Vector3(0.0, 0.5, 0.0)
			elif current_stage == 9:
				spawn_pos = Vector3(-3.0, 0.5, 0.0)
			elif current_stage == 10:
				spawn_pos = Vector3(-6.0, 0.5, 0.0)
				
		p.global_position = Vector3(spawn_pos.x, spawn_pos.y, 0.0)
		p.velocity = Vector3.ZERO
		
		# Kích hoạt hiệu ứng ma pháp triệu hồi giáng trần
		var summon_fx = SCENE_SUMMON.instantiate()
		add_child(summon_fx)
		summon_fx.global_position = Vector3(spawn_pos.x, 0.0, 0.0)
		
		# Hồi phục 100% Giáp sau mỗi round
		if "current_armor" in p and "max_armor" in p:
			p.current_armor = p.max_armor
			if p.has_signal("armor_changed"):
				p.armor_changed.emit(p.current_armor, p.max_armor)

func _get_stage_title(world: int, stage: int, branch: RoomBranch) -> String:
	var branch_suffix = ""
	if branch == RoomBranch.COMBAT:
		branch_suffix = " [⚔ Đao Kiếm]"
	elif branch == RoomBranch.SUSTAIN:
		branch_suffix = " [❤ Sinh Mệnh]"

	if world == 2:
		match stage:
			1: return "Hầm Ngục Huyết Rễ" + branch_suffix
			2: return "Vực Thẳm Bào Tử" + branch_suffix
			3: return "Đầm Lầy Axit Ăn Mòn" + branch_suffix
			4: return "Hang Rễ Ký Sinh" + branch_suffix
			5: return "QUÁI TINH ANH — Cổ Thụ Biến Dị"
			6: return "Tử Địa Bào Tử Độc" + branch_suffix
			7: return "Mạng Lưới Rễ Máu" + branch_suffix
			8: return "Vương Triều Ký Sinh" + branch_suffix
			9: return "TRẠM NGHỈ AN TOÀN — Đài Tế Cổ Xưa"
			10: return "ĐẠI TRÙM CUỐI — Mẫu Thể Ký Sinh"
			_: return "Sàn Đấu Huyết Rễ" + branch_suffix

	match stage:
		1: return "Cổ Thành Khởi Đầu" + branch_suffix
		2: return "Tiền Tuyến Bị Phá Hủy" + branch_suffix
		3: return "Chiến Hào Đẫm Máu" + branch_suffix
		4: return "Quân Tiên Phong" + branch_suffix
		5: return "QUÁI TINH ANH — Thủ Lĩnh Đao Phủ Quỷ"
		6: return "Thành Lũy Đổ Nát" + branch_suffix
		7: return "Hào Chông Tàn Sát" + branch_suffix
		8: return "Tử Địa Giáp Đen" + branch_suffix
		9: return "TRẠM NGHỈ AN TOÀN — Đài Tế Hoàng Gia"
		10: return "ĐẠI TRÙM CUỐI — Thống Lĩnh Thiết Vệ"
		_: return "Sàn Đấu Vượt Ải" + branch_suffix

func _spawn_stage_wave(world: int, stage: int, branch: RoomBranch) -> void:
	_clear_active_enemies()
	_reset_spawn_points_occupancy()

	if active_altar and is_instance_valid(active_altar):
		active_altar.queue_free()
		active_altar = null

	# X.9: Safe Haven (Không có quái, chỉ có Bệ Thờ)
	if stage == 9:
		active_altar = SCENE_ALTAR.instantiate()
		add_child(active_altar)
		active_altar.global_position = Vector3(0.0, 0.0, 0.0)
		_on_all_enemies_defeated()
		return

	var space_state = get_world_3d().direct_space_state if get_world_3d() else null
	# Lấy danh sách quái theo từng Ải và World
	var spawn_list = _get_stage_spawn_config(world, stage, branch)
	for item in spawn_list:
		var scn: PackedScene = item["scene"]
		var req_tier: int = item.get("tier", 1)
		var req_type: String = item.get("type", "guard")
		var fallback_pos: Vector3 = item.get("pos", Vector3.ZERO)
		
		# 1. Tìm SpawnPoint3D phù hợp theo tầng và loại quái
		var chosen_sp: SpawnPoint3D = _find_best_spawn_point(req_tier, req_type, space_state)
		var spawn_pos: Vector3 = fallback_pos
		var facing: int = -1
		
		if chosen_sp:
			var val = chosen_sp.validate_location(space_state)
			if val.get("valid", false):
				spawn_pos = val["spawn_pos"]
				facing = chosen_sp.default_facing
				chosen_sp.is_occupied = true
		else:
			# 2. Nếu không có Marker3D trống, kiểm tra bằng Raycast + Shape-query
			var val = _validate_custom_pos(fallback_pos, space_state)
			if val.get("valid", false):
				spawn_pos = val["spawn_pos"]
			else:
				spawn_pos = Vector3(fallback_pos.x, 0.1, 0.0)

		var enemy: EnemyBase3D = scn.instantiate()
		add_child(enemy)
		enemy.global_position = Vector3(spawn_pos.x, spawn_pos.y, 0.0)
		enemy.assigned_tier = req_tier
		enemy.facing_direction = facing
		enemy.last_valid_position = enemy.global_position
		register_enemy(enemy)

	# Nếu là phòng Sustain: Sinh thêm bình máu an toàn
	if branch == RoomBranch.SUSTAIN:
		_spawn_sustain_caches()

func _reset_spawn_points_occupancy() -> void:
	var sps = get_tree().get_nodes_in_group("spawn_points")
	for sp in sps:
		if sp is SpawnPoint3D:
			sp.is_occupied = false

func _find_best_spawn_point(req_tier: int, req_type: String, space_state: PhysicsDirectSpaceState3D) -> SpawnPoint3D:
	var sps = get_tree().get_nodes_in_group("spawn_points")
	var candidates: Array = []
	for sp in sps:
		if sp is SpawnPoint3D and sp.tier == req_tier and not sp.is_occupied:
			if sp.can_spawn_enemy_type(req_type):
				candidates.append(sp)
				
	# Nếu không có điểm khớp loại, tìm điểm bất kỳ cùng tầng
	if candidates.is_empty():
		for sp in sps:
			if sp is SpawnPoint3D and sp.tier == req_tier and not sp.is_occupied:
				candidates.append(sp)
				
	candidates.shuffle()
	for sp in candidates:
		if space_state:
			var res = sp.validate_location(space_state)
			if res.get("valid", false):
				return sp
		else:
			return sp
	return null

func _validate_custom_pos(check_pos: Vector3, space_state: PhysicsDirectSpaceState3D) -> Dictionary:
	var result = {"valid": false, "spawn_pos": check_pos}
	if not space_state:
		return result
	var ray_from = Vector3(check_pos.x, check_pos.y + 1.2, 0.0)
	var ray_to = Vector3(check_pos.x, check_pos.y - 3.0, 0.0)
	var ray_query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1)
	var ray_hit = space_state.intersect_ray(ray_query)
	if ray_hit.is_empty():
		return result
	var floor_y = ray_hit.position.y
	var valid_pos = Vector3(check_pos.x, floor_y + 0.1, 0.0)
	
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	var shape_query = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = shape
	shape_query.transform = Transform3D(Basis(), valid_pos + Vector3(0.0, 0.8, 0.0))
	shape_query.collision_mask = 1
	var overlaps = space_state.intersect_shape(shape_query, 4)
	if not overlaps.is_empty():
		return result
	result["valid"] = true
	result["spawn_pos"] = valid_pos
	return result

func _check_active_enemies_watchdog() -> void:
	var to_remove = []
	for e in active_enemies:
		if not is_instance_valid(e) or e.is_queued_for_deletion():
			to_remove.append(e)
			continue
		if e.is_dead:
			continue
		if e.global_position.y < -4.0:
			if e.stuck_count >= 3:
				to_remove.append(e)
				e.die()
			else:
				e.stuck_count += 1
				if e.last_valid_position != Vector3.ZERO:
					e.global_position = e.last_valid_position
					e.velocity = Vector3.ZERO
		elif e.stuck_count >= 3:
			to_remove.append(e)
			e.die()
			
	for r in to_remove:
		active_enemies.erase(r)
		
	if active_enemies.is_empty() and stage_in_progress:
		_on_all_enemies_defeated()

func _get_stage_spawn_config(world: int, stage: int, branch: RoomBranch) -> Array:
	if world == 2:
		return _get_world2_spawn_config(stage, branch)
	return _get_world1_spawn_config(stage, branch)

func _get_world1_spawn_config(stage: int, branch: RoomBranch) -> Array:
	var list = []
	match stage:
		1:
			list = [
				{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "type": "guard", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		2:
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(6.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "type": "archer", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)}
				]
		3:
			list = [
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(-26.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(26.0, 3.8, 0.0)}
			]
		4:
			list = [
				{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		5:
			list = [
				{"scene": SCENE_ELITE, "type": "elite", "tier": 1, "pos": Vector3(3.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(-26.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(26.0, 3.8, 0.0)}
			]
		6:
			list = [
				{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "type": "guard", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		7:
			list = [
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "type": "guard", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(-26.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 3, "pos": Vector3(26.0, 3.8, 0.0)}
			]
		8:
			list = [
				{"scene": SCENE_ELITE, "type": "elite", "tier": 1, "pos": Vector3(3.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "type": "hound", "tier": 1, "pos": Vector3(6.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "type": "archer", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		10:
			list = [
				{"scene": SCENE_BOSS, "type": "boss", "tier": 1, "pos": Vector3(8.0, 0.5, 0.0)}
			]
	return list

func _get_w2_shambler_scene() -> PackedScene:
	if ResourceLoader.exists("res://scenes_3d/EnemySporeShambler3D.tscn"):
		return load("res://scenes_3d/EnemySporeShambler3D.tscn")
	return SCENE_GUARD

func _get_w2_lurker_scene() -> PackedScene:
	if ResourceLoader.exists("res://scenes_3d/EnemyRootLurker3D.tscn"):
		return load("res://scenes_3d/EnemyRootLurker3D.tscn")
	return SCENE_HOUND

func _get_w2_spitter_scene() -> PackedScene:
	if ResourceLoader.exists("res://scenes_3d/EnemyAcidSpitter3D.tscn"):
		return load("res://scenes_3d/EnemyAcidSpitter3D.tscn")
	return SCENE_ARCHER

func _get_w2_elite_tree_scene() -> PackedScene:
	if ResourceLoader.exists("res://scenes_3d/EnemyEliteMutatedTree3D.tscn"):
		return load("res://scenes_3d/EnemyEliteMutatedTree3D.tscn")
	return SCENE_ELITE

func _get_w2_boss_scene() -> PackedScene:
	if ResourceLoader.exists("res://scenes_3d/BossParasiticMatriarch3D.tscn"):
		return load("res://scenes_3d/BossParasiticMatriarch3D.tscn")
	return SCENE_BOSS

func _get_world2_spawn_config(stage: int, branch: RoomBranch) -> Array:
	var list = []
	var s_shambler = _get_w2_shambler_scene()
	var s_lurker = _get_w2_lurker_scene()
	var s_spitter = _get_w2_spitter_scene()
	var s_elite = _get_w2_elite_tree_scene()
	var s_boss = _get_w2_boss_scene()

	match stage:
		1:
			list = [
				{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		2:
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(6.0, 0.5, 0.0)},
					{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
					{"scene": s_spitter, "type": "spitter", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
				]
			else:
				list = [
					{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)}
				]
		3:
			list = [
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(21.0, 3.8, 0.0)}
			]
		4:
			list = [
				{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		5:
			list = [
				{"scene": s_elite, "type": "elite", "tier": 1, "pos": Vector3(3.0, 0.5, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(21.0, 3.8, 0.0)}
			]
		6:
			list = [
				{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": s_shambler, "type": "shambler", "tier": 1, "pos": Vector3(14.0, 0.5, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		7:
			list = [
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": s_shambler, "type": "shambler", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 3, "pos": Vector3(21.0, 3.8, 0.0)}
			]
		8:
			list = [
				{"scene": s_elite, "type": "elite", "tier": 1, "pos": Vector3(3.0, 0.5, 0.0)},
				{"scene": s_lurker, "type": "lurker", "tier": 1, "pos": Vector3(6.0, 0.5, 0.0)},
				{"scene": s_spitter, "type": "spitter", "tier": 2, "pos": Vector3(0.0, 4.0, 0.0)}
			]
		10:
			list = [
				{"scene": s_boss, "type": "boss", "tier": 1, "pos": Vector3(8.0, 0.5, 0.0)}
			]
	return list

func _spawn_sustain_caches() -> void:
	for offset_x in [-4.0, 4.0]:
		var drop = SCENE_DROP.instantiate()
		add_child(drop)
		drop.global_position = Vector3(offset_x, 0.5, 0.0)
		drop.setup(1, 0, "Bình Máu Lớn")

func register_enemy(enemy: EnemyBase3D) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)
			
		# Nếu là Tinh Anh hoặc Boss, liên kết thanh máu Boss trên HUD
		if "Thủ Lĩnh" in enemy.enemy_name or "Boss" in enemy.enemy_name or "Thống Lĩnh" in enemy.enemy_name:
			var hud = get_node_or_null("../HUD3D")
			if hud and hud.has_method("show_boss_bar"):
				hud.show_boss_bar(enemy.enemy_name, enemy.max_hp)
				if enemy.has_signal("hp_changed"):
					enemy.hp_changed.connect(func(c, _m): hud.update_boss_bar(c))
					
			var cam = get_viewport().get_camera_3d()
			if cam and cam.has_method("set_boss_mode"):
				cam.set_boss_mode(true)
			if SoundManager3D.get_instance():
				SoundManager3D.get_instance().play_boss_roar()

func _on_enemy_died(enemy: EnemyBase3D) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty() and stage_in_progress:
		_on_all_enemies_defeated()

func _on_all_enemies_defeated() -> void:
	stage_in_progress = false
	var stage_str = "%d.%d" % [current_world, current_stage]
	stage_cleared.emit(stage_str)

	# Khôi phục camera về chế độ bình thường
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("set_boss_mode"):
		cam.set_boss_mode(false)

	var hud = get_node_or_null("../HUD3D")
	if hud and hud.has_method("show_stage_banner"):
		if current_stage == 9:
			hud.show_stage_banner("✨ TRẠM NGHỈ AN TOÀN — HỒI PHỤC, NÂNG CẤP ĐỒ RỒI TIẾN VÀO CỬA BOSS 1.10 ✨")
		elif current_stage == 10:
			hud.show_stage_banner("🏆 CHIẾN THẮNG ĐẠI TRÙM THỐNG LĨNH THIẾT VỆ! TIẾN VÀO WORLD 2! 🏆")
			if SoundManager3D.get_instance():
				SoundManager3D.get_instance().play_victory_bell()
		else:
			hud.show_stage_banner("✨ ẢI " + stage_str + " ĐÃ DỌN SẠCH! TIẾN VÀO CỔNG PHÍA TRƯỚC ✨")

	_open_portals()

func _clear_active_enemies() -> void:
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
	active_enemies.clear()

func _clear_portals() -> void:
	for p in active_portals:
		if is_instance_valid(p):
			p.queue_free()
	active_portals.clear()

func _open_portals() -> void:
	_clear_portals()
	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_portal_warp()

	# Các ải đặc biệt (X.4, X.8, X.9, X.10) chỉ xuất hiện 1 Cổng Dịch Chuyển duy nhất ở cuối cầu
	if current_stage in [4, 8, 9, 10]:
		var p: Portal3D = SCENE_PORTAL.instantiate()
		add_child(p)
		p.global_position = Vector3(18.0, 0.0, 0.0)
		p.setup(Portal3D.PortalType.STANDARD)
		p.portal_chosen.connect(_on_portal_chosen)
		p.set_active(true)
		active_portals.append(p)
		return

	# Các ải thông thường: Xuất hiện 2 cổng phân nhánh (Đao Kiếm & Sinh Mệnh) ngay cuối cầu (X=14 và X=19)
	var p_combat: Portal3D = SCENE_PORTAL.instantiate()
	add_child(p_combat)
	p_combat.global_position = Vector3(14.0, 0.0, 0.0)
	p_combat.setup(Portal3D.PortalType.COMBAT)
	p_combat.portal_chosen.connect(_on_portal_chosen)
	p_combat.set_active(true)
	active_portals.append(p_combat)

	var p_sustain: Portal3D = SCENE_PORTAL.instantiate()
	add_child(p_sustain)
	p_sustain.global_position = Vector3(19.0, 0.0, 0.0)
	p_sustain.setup(Portal3D.PortalType.SUSTAIN)
	p_sustain.portal_chosen.connect(_on_portal_chosen)
	p_sustain.set_active(true)
	active_portals.append(p_sustain)

func _on_portal_chosen(type: int) -> void:
	match type:
		Portal3D.PortalType.COMBAT:
			next_stage(RoomBranch.COMBAT)
		Portal3D.PortalType.SUSTAIN:
			next_stage(RoomBranch.SUSTAIN)
		_:
			next_stage(RoomBranch.STANDARD)

func next_stage(branch: RoomBranch = RoomBranch.STANDARD) -> void:
	if current_stage < 10:
		start_stage(current_world, current_stage + 1, branch)
	else:
		var hud = get_node_or_null("../HUD3D")
		if current_world == 1:
			if hud and hud.has_method("show_stage_banner"):
				hud.show_stage_banner("👑 THẮNG LỢI! BẠN ĐÃ TIÊU DIỆT THỐNG LĨNH THIẾT VỆ!")
			await get_tree().create_timer(3.5).timeout
			# Chuyển tiếp sang World 2: Hầm Ngục Huyết Rễ
			if ResourceLoader.exists("res://scenes_3d/World2_Crimson_Catacombs_3D.tscn"):
				var cp_mgr = CheckpointManager.get_instance()
				cp_mgr.activate_checkpoint(2, 1)
				get_tree().change_scene_to_file("res://scenes_3d/World2_Crimson_Catacombs_3D.tscn")
				return
			start_stage(1, 1, RoomBranch.STANDARD)
		elif current_world == 2:
			if hud and hud.has_method("show_stage_banner"):
				hud.show_stage_banner("👑 THẮNG LỢI TOÀN DIỆN! BẠN ĐÃ TIÊU DIỆT MẪU THỂ KÝ SINH!")
			await get_tree().create_timer(3.5).timeout
			start_stage(2, 1, RoomBranch.STANDARD)
		else:
			start_stage(current_world, 1, RoomBranch.STANDARD)
