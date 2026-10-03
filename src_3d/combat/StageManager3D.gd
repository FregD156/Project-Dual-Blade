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

var active_enemies: Array = []
var active_portals: Array = []
var active_altar: Node3D = null

func _ready() -> void:
	# Kết nối Bản đồ Fast Travel nếu có
	var map_ui = get_node_or_null("../FastTravelMapUI")
	if map_ui and map_ui.has_signal("checkpoint_selected"):
		map_ui.checkpoint_selected.connect(_on_fast_travel_selected)

	# Bắt đầu tại Ải 1.1 khi tải scene
	call_deferred("start_stage", current_world, current_stage, current_branch)

func _on_fast_travel_selected(world: int, stage: int) -> void:
	start_stage(world, stage, RoomBranch.STANDARD)


func start_stage(world: int, stage: int, branch: RoomBranch = RoomBranch.STANDARD) -> void:
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

	# Đặt lại vị trí người chơi và hồi giáp
	_reposition_player()
	_clear_portals()
	_spawn_stage_wave(current_world, current_stage, current_branch)

func _reposition_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		p.global_position = Vector3(-10.0, 0.5, 0.0)
		p.velocity = Vector3.ZERO
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

	if active_altar and is_instance_valid(active_altar):
		active_altar.queue_free()
		active_altar = null

	# 1.9: Safe Haven (Không có quái, chỉ có Bệ Thờ)
	if stage == 9:
		active_altar = SCENE_ALTAR.instantiate()
		add_child(active_altar)
		active_altar.global_position = Vector3(0.0, 0.0, 0.0)
		_on_all_enemies_defeated()
		return

	# Lấy danh sách quái theo từng Ải
	var spawn_list = _get_stage_spawn_config(stage, branch)
	for item in spawn_list:
		var scn: PackedScene = item["scene"]
		var pos: Vector3 = item["pos"]
		var enemy: EnemyBase3D = scn.instantiate()
		add_child(enemy)
		enemy.global_position = pos
		register_enemy(enemy)

	# Nếu là phòng Sustain: Sinh thêm bình máu an toàn
	if branch == RoomBranch.SUSTAIN:
		_spawn_sustain_caches()

func _get_stage_spawn_config(stage: int, branch: RoomBranch) -> Array:
	var list = []
	match stage:
		1:
			# 1.1 Khởi đầu: 4 quái (2 Lính gác sàn trước/sau, 1 Lính gác trên cầu vòm đá, 1 Chó săn)
			list = [
				{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(8.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(0.0, 4.0, 0.0)},
				{"scene": SCENE_HOUND, "pos": Vector3(18.0, 0.5, 0.0)}
			]
		2:
			# 1.2: 5-7 quái (Lính gác + Đàn chó săn + Cung thủ trên đỉnh cầu vòm đá và đài quan sát)
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(6.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(12.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(20.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(28.0, 0.5, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(5.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(12.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(18.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)}
				]
		3:
			# 1.3: 6-8 quái (Cung thủ 2 đài quan sát X=-21, X=21 + Bầy chó săn tuần tra + Đội lính gác)
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_HOUND, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(12.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(18.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(26.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_HOUND, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(5.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(15.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(22.0, 0.5, 0.0)}
				]
		4:
			# 1.4: 7-8 quái (Trước cửa Tinh Anh - Đội tiên phong tinh nhuệ & Lính bắn tỉa)
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(12.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(18.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(25.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(6.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(14.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(22.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
				]
		5:
			# 1.5: QUÁI TINH ANH — Thủ Lĩnh Đao Phủ Quỷ + 2 Cung thủ đài quan sát + 2 Lính gác thiết vệ bảo hộ
			list = [
				{"scene": SCENE_ELITE, "pos": Vector3(4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(12.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
			]
		6:
			# 1.6: 7-9 quái (Thành Lũy Đổ Nát sau Tinh Anh - Đội hình dày đặc)
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(10.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(18.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(25.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(32.0, 0.5, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(6.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(14.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(20.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
				]
		7:
			# 1.7: 8-10 quái (Hào Chông Tàn Sát — Quái tràn ngập sàn đấu, đỉnh cầu và 2 đài quan sát)
			if branch == RoomBranch.COMBAT:
				list = [
					{"scene": SCENE_HOUND, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(12.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(18.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(24.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(30.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(0.0, 4.0, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)}
				]
			else:
				list = [
					{"scene": SCENE_HOUND, "pos": Vector3(-4.0, 0.5, 0.0)},
					{"scene": SCENE_HOUND, "pos": Vector3(5.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(14.0, 0.5, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(22.0, 0.5, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
					{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)},
					{"scene": SCENE_GUARD, "pos": Vector3(0.0, 4.0, 0.0)}
				]
		8:
			# 1.8: 8 quái (Trước Trạm Nghỉ — Quái Tinh Anh dẫn đầu cùng bầy chó săn và cung thủ)
			list = [
				{"scene": SCENE_ELITE, "pos": Vector3(5.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(-4.0, 0.5, 0.0)},
				{"scene": SCENE_GUARD, "pos": Vector3(14.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "pos": Vector3(8.0, 0.5, 0.0)},
				{"scene": SCENE_HOUND, "pos": Vector3(20.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(0.0, 4.0, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
			]
		10:
			# 1.10: ĐẠI TRÙM CUỐI WORLD 1 — Thống Lĩnh Thiết Vệ 2-phase + 2 Cung thủ yểm trợ
			list = [
				{"scene": SCENE_BOSS, "pos": Vector3(10.0, 0.5, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(-21.0, 3.8, 0.0)},
				{"scene": SCENE_ARCHER, "pos": Vector3(21.0, 3.8, 0.0)}
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

func _on_enemy_died(enemy: EnemyBase3D) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty() and stage_in_progress:
		_on_all_enemies_defeated()

func _on_all_enemies_defeated() -> void:
	stage_in_progress = false
	var stage_str = "%d.%d" % [current_world, current_stage]
	stage_cleared.emit(stage_str)

	var hud = get_node_or_null("../HUD3D")
	if hud and hud.has_method("show_stage_banner"):
		if current_stage == 9:
			hud.show_stage_banner("✨ TRẠM NGHỈ AN TOÀN — HỒI PHỤC, NÂNG CẤP ĐỒ RỒI TIẾN VÀO CỬA BOSS 1.10 ✨")
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

	# Các ải đặc biệt (X.4, X.8, X.9, X.10) chỉ xuất hiện 1 Cổng Dịch Chuyển duy nhất ở cuối sàn
	if current_stage in [4, 8, 9, 10]:
		var p: Portal3D = SCENE_PORTAL.instantiate()
		add_child(p)
		p.global_position = Vector3(18.0, 0.0, 0.0)
		p.setup(Portal3D.PortalType.STANDARD)
		p.portal_chosen.connect(_on_portal_chosen)
		p.set_active(true)
		active_portals.append(p)
		return

	# Các ải thông thường (1.1, 1.2, 1.3, 1.6, 1.7): Xuất hiện 2 cổng phân nhánh (Đao Kiếm & Sinh Mệnh) gần hơn (X=14 và X=19)
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
		# Hạ gục Boss 1.10 -> Hoàn thành World 1
		var hud = get_node_or_null("../HUD3D")
		if hud and hud.has_method("show_stage_banner"):
			hud.show_stage_banner("👑 THẮNG LỢI! BẠN ĐÃ TIÊU DIỆT THỐNG LĨNH THIẾT VỆ!")
		await get_tree().create_timer(3.5).timeout
		# Chuyển tiếp New Game+ hoặc World kế tiếp
		start_stage(1, 1, RoomBranch.STANDARD)
