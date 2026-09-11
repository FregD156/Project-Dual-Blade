class_name StageManager
extends Node2D

## StageManager quản lý Vòng lặp Vượt ải (Loop Pacing & Stage Progression) theo detail.md
## Hỗ trợ:
## - World 1: Cổ Thành Hoang Tàn (The Forsaken Bastion) - Boss: Thống Lĩnh Thiết Vệ
## - World 2: Hầm Ngục Huyết Rễ (The Crimson Catacombs) - Quái Tinh Anh: Cổ Thụ Biến Dị, Boss: Mẫu Thể Ký Sinh
##
## Phân Nhánh Phòng (Portal Choice - detail.md IV.2):
## - Cổng Đao Kiếm (Combat Portal)
## - Cổng Sinh Mệnh (Sustain Portal)

signal stage_changed(stage_str: String, stage_name: String)
signal stage_cleared(stage_str: String)
signal all_stages_completed()

@export var current_world: int = 1
@export var current_stage: int = 1
@export var is_loop_active: bool = true

enum RoomBranch {
	STANDARD,
	COMBAT,
	SUSTAIN
}
var current_branch: RoomBranch = RoomBranch.STANDARD

@onready var world_node: Node2D = get_node_or_null("../World")
@onready var entities_node: Node2D = get_node_or_null("../World/Entities")
@onready var spawner_node: EnemySpawner = get_node_or_null("../World/EnemySpawner")
@onready var portal_node: Area2D = get_node_or_null("../World/Portal")
@onready var banner_label: Label = get_node_or_null("../UI_Layer/StageBanner/BannerLabel")
@onready var banner_panel: Control = get_node_or_null("../UI_Layer/StageBanner")

# Cổng dịch chuyển
const PORTAL_SCENE = preload("res://scenes/Portal.tscn")
const PortalScript = preload("res://src/combat/Portal.gd")

# Quái World 1
const ENEMY_GUARD = preload("res://scenes/enemies/EnemyRustyGuard.tscn")
const ENEMY_HOUND = preload("res://scenes/enemies/EnemyChainHound.tscn")
const ENEMY_ARCHER = preload("res://scenes/enemies/EnemyArcher.tscn")
const ENEMY_ELITE_W1 = preload("res://scenes/enemies/EnemyEliteExecutioner.tscn")
const ENEMY_BOSS_W1 = preload("res://scenes/enemies/EnemyBossCommander.tscn")

# Quái & Môi Trường World 2
const ENEMY_MUSHROOM = preload("res://scenes/enemies/EnemyToxicMushroom.tscn")
const ENEMY_SPIDER = preload("res://scenes/enemies/EnemyCrimsonSpider.tscn")
const ENEMY_ELITE_TREE = preload("res://scenes/enemies/EnemyEliteTree.tscn")
const ENEMY_BOSS_BROODMOTHER = preload("res://scenes/enemies/EnemyBossBroodmother.tscn")
const BOUNCY_MUSHROOM_SCENE = preload("res://scenes/environment/BouncyMushroom.tscn")
const TOXIC_ACID_SCENE = preload("res://scenes/environment/ToxicAcidPool.tscn")

# Texture Background World 1 & 2
const BG_WORLD_1 = preload("res://assets/sprites/environment/world1_bastion_bg.png")
const BG_WORLD_2 = preload("res://assets/sprites/environment/world2_catacombs_bg.png")

const SAFE_ALTAR = preload("res://scenes/SafeHavenAltar.tscn")
const DROP_ITEM_SCENE = preload("res://scenes/DropItem.tscn")

var active_enemies: Array[EnemyBase] = []
var active_altar: Node2D = null
var active_portals: Array[Node2D] = []
var active_hazards: Array[Node2D] = []
var stage_in_progress: bool = false
var enemies_to_spawn: int = 0

func _ready() -> void:
	if portal_node and is_instance_valid(portal_node):
		portal_node.visible = false
		portal_node.set_deferred("monitoring", false)
	
	call_deferred("start_stage", current_world, current_stage, RoomBranch.STANDARD)

func start_stage(world_idx: int, stage_idx: int, branch: RoomBranch = RoomBranch.STANDARD) -> void:
	current_world = world_idx
	current_stage = stage_idx
	current_branch = branch
	stage_in_progress = true
	
	_update_environment_theme()
	_reposition_player()
	
	_clear_portals()
	_clear_hazards()

	if portal_node and is_instance_valid(portal_node):
		portal_node.visible = false
		portal_node.set_deferred("monitoring", false)
		
	var stage_str = "%d.%d" % [current_world, current_stage]
	var title = _get_stage_title(current_world, current_stage, current_branch)
	
	_show_banner(stage_str + ": " + title)
	stage_changed.emit(stage_str, title)
	
	_spawn_stage_wave(current_world, current_stage, current_branch)

func _update_environment_theme() -> void:
	# Cập nhật hình nền ParallaxBackground tùy theo World
	var par_bg = get_node_or_null("../ParallaxBackground/ParallaxLayer")
	if par_bg:
		var target_tex = BG_WORLD_2 if current_world == 2 else BG_WORLD_1
		for child in par_bg.get_children():
			if child is Sprite2D:
				child.texture = target_tex

func _reposition_player() -> void:
	if not entities_node:
		entities_node = get_node_or_null("../World/Entities")
	var player: Player = null
	if entities_node:
		player = entities_node.get_node_or_null("Player")
	if not player and get_tree():
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
	if player and is_instance_valid(player):
		player.global_position = Vector2(100, 192)
		player.velocity = Vector2.ZERO
		if player.has_method("refill_armor_after_round"):
			player.refill_armor_after_round()

func _get_stage_title(world: int, stage: int, branch: RoomBranch = RoomBranch.STANDARD) -> String:
	var branch_suffix = ""
	if branch == RoomBranch.COMBAT:
		branch_suffix = " [⚔ Đao Kiếm]"
	elif branch == RoomBranch.SUSTAIN:
		branch_suffix = " [❤ Sinh Mệnh]"

	if world == 2:
		match stage:
			1: return "Cống Ngầm Huyết Rễ" + branch_suffix
			2: return "Mê Cung Bào Tử" + branch_suffix
			3: return "Vực Nấm Gai Độc" + branch_suffix
			4: return "Hang Ổ Ký Sinh" + branch_suffix
			5: return "QUÁI TINH ANH - Cổ Thụ Biến Dị"
			6: return "Địa Ngục Rễ Cây" + branch_suffix
			7: return "Vũng Axit Ăn Mòn" + branch_suffix
			8: return "Tử Địa Mạng Nhện" + branch_suffix
			9: return "TRẠM NGHỈ AN TOÀN (Thầy Lang Điên & Lão Thợ Rèn)"
			10: return "ĐẠI TRÙM - Mẫu Thể Ký Sinh"
			_: return "Hầm Ngục Huyết Rễ" + branch_suffix

	# World 1
	match stage:
		1: return "Cổ Thành Khởi Đầu" + branch_suffix
		2: return "Tiền Tuyến Bị Phá Hủy" + branch_suffix
		3: return "Chiến Hào Đẫm Máu" + branch_suffix
		4: return "Quân Tiên Phong" + branch_suffix
		5: return "QUÁI TINH ANH - Đao Phủ Quỷ"
		6: return "Thành Lũy Đổ Nát" + branch_suffix
		7: return "Hào Chông Tàn Sát" + branch_suffix
		8: return "Tử Địa Giáp Đen" + branch_suffix
		9: return "TRẠM NGHỈ AN TOÀN (Lão Thợ Rèn & Đài Tế)"
		10: return "ĐẠI TRÙM - Thống Lĩnh Thiết Vệ"
		_: return "Sàn Đấu Vượt Ải" + branch_suffix

func _show_banner(text: String) -> void:
	if banner_panel and banner_label:
		banner_label.text = text
		banner_panel.visible = true
		banner_panel.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(banner_panel, "modulate:a", 1.0, 0.3)
		tween.tween_interval(1.8)
		tween.tween_property(banner_panel, "modulate:a", 0.0, 0.4)
		tween.tween_callback(func(): banner_panel.visible = false)

func _clear_hazards() -> void:
	for h in active_hazards:
		if is_instance_valid(h):
			h.queue_free()
	active_hazards.clear()

func _spawn_stage_wave(world: int, stage: int, branch: RoomBranch) -> void:
	# Clear previous enemies
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
	active_enemies.clear()
	
	# Clear previous altar if any
	if active_altar and is_instance_valid(active_altar):
		active_altar.queue_free()
		active_altar = null

	if stage == 9:
		# Safe Haven: Không có quái, dựng Đài Tế Hồi Phục & Bàn Thợ Rèn
		if SAFE_ALTAR and entities_node:
			active_altar = SAFE_ALTAR.instantiate()
			active_altar.global_position = Vector2(500, 192)
			entities_node.add_child(active_altar)
		_on_wave_cleared()
		return

	var spawn_list = []
	if world == 2:
		spawn_list = _get_world2_spawns(stage, branch)
		_spawn_world2_hazards(stage)
	else:
		spawn_list = _get_world1_spawns(stage, branch)

	for item in spawn_list:
		var scn: PackedScene = item["scene"]
		var pos: Vector2 = item["pos"]
		var enemy: EnemyBase = scn.instantiate()
		enemy.global_position = pos
		enemy.stage_number = current_stage
		enemy.is_combat_room = (branch == RoomBranch.COMBAT)
		enemy.died.connect(_on_enemy_died)
		
		# Kết nối thanh máu Boss nếu là boss
		if enemy is EnemyBossCommander or enemy is EnemyBossBroodmother:
			var ui = get_node_or_null("../UI_Layer")
			if ui and ui.has_method("bind_boss"):
				ui.bind_boss(enemy)
				
		entities_node.add_child(enemy)
		active_enemies.append(enemy)

	# Nếu là phòng Sustain (Sinh Mệnh): Chắc chắn sinh ra bình chứa Hạt Sinh Mệnh & Bình Máu Lớn
	if branch == RoomBranch.SUSTAIN and DROP_ITEM_SCENE and entities_node:
		call_deferred("_spawn_sustain_room_caches")

func _spawn_world2_hazards(stage: int) -> void:
	if not entities_node:
		return
		
	# Spawn búp nấm nảy (Bouncy Mushroom) để người chơi leo bục né bẫy
	if stage in [2, 3, 4, 6, 7]:
		var shroom = BOUNCY_MUSHROOM_SCENE.instantiate()
		shroom.position = Vector2(720, 192)
		entities_node.add_child(shroom)
		active_hazards.append(shroom)

	# Spawn vũng Axit ăn mòn (Toxic Acid Pool) ở các ải nguy hiểm
	if stage in [3, 7, 8]:
		var acid = TOXIC_ACID_SCENE.instantiate()
		acid.position = Vector2(520, 192)
		entities_node.add_child(acid)
		active_hazards.append(acid)

func _get_world2_spawns(stage: int, branch: RoomBranch) -> Array:
	var spawn_list = []
	match stage:
		1:
			spawn_list = [
				{"scene": ENEMY_MUSHROOM, "pos": Vector2(420, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(680, 192)}
			]
		2:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(380, 192)},
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(580, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(750, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(920, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(450, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(750, 192)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(400, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(650, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)}
				]
		3:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_SPIDER, "pos": Vector2(380, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(560, 192)},
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(740, 192)},
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(920, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1100, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_SPIDER, "pos": Vector2(480, 192)},
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(800, 192)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_SPIDER, "pos": Vector2(420, 192)},
					{"scene": ENEMY_MUSHROOM, "pos": Vector2(640, 192)},
					{"scene": ENEMY_SPIDER, "pos": Vector2(860, 192)}
				]
		4:
			spawn_list = [
				{"scene": ENEMY_MUSHROOM, "pos": Vector2(400, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(600, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(800, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)}
			]
		5:
			# Quái Tinh Anh 2.5: Cổ Thụ Biến Dị
			spawn_list = [
				{"scene": ENEMY_ELITE_TREE, "pos": Vector2(780, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(450, 192)},
				{"scene": ENEMY_MUSHROOM, "pos": Vector2(980, 192)}
			]
		6:
			spawn_list = [
				{"scene": ENEMY_MUSHROOM, "pos": Vector2(420, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(640, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(850, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1050, 108)}
			]
		7:
			spawn_list = [
				{"scene": ENEMY_SPIDER, "pos": Vector2(450, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(680, 192)},
				{"scene": ENEMY_MUSHROOM, "pos": Vector2(880, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1100, 108)}
			]
		8:
			# Đẩy cao độ khó trước boss
			spawn_list = [
				{"scene": ENEMY_ELITE_TREE, "pos": Vector2(720, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(500, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(920, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)}
			]
		10:
			# Đại Trùm Cuối World 2 (2.10): Mẫu Thể Ký Sinh
			spawn_list = [
				{"scene": ENEMY_BOSS_BROODMOTHER, "pos": Vector2(880, 192)},
				{"scene": ENEMY_SPIDER, "pos": Vector2(1150, 192)}
			]
	return spawn_list

func _get_world1_spawns(stage: int, branch: RoomBranch) -> Array:
	var spawn_list = []
	match stage:
		1:
			spawn_list = [
				{"scene": ENEMY_GUARD, "pos": Vector2(400, 192)},
				{"scene": ENEMY_GUARD, "pos": Vector2(650, 192)}
			]
		2:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(350, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(550, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(750, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1100, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(500, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(680, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)}
				]
		3:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(550, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(720, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)},
					{"scene": ENEMY_GUARD, "pos": Vector2(1000, 192)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(500, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(800, 192)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(400, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(620, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)},
					{"scene": ENEMY_GUARD, "pos": Vector2(1050, 192)}
				]
		4:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(350, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(520, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(700, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(880, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(980, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1200, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(450, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(750, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(980, 108)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(580, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(820, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(980, 108)}
				]
		5:
			# Elite Mid-boss (1.5)
			spawn_list = [
				{"scene": ENEMY_ELITE_W1, "pos": Vector2(750, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)},
				{"scene": ENEMY_GUARD, "pos": Vector2(550, 192)}
			]
		6:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(550, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(720, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(900, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1050, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1250, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(500, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(800, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1050, 108)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_GUARD, "pos": Vector2(450, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(650, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(850, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1050, 108)}
				]
		7:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(400, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(600, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(800, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(1000, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(880, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(500, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(800, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(880, 108)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(450, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(680, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(880, 108)},
					{"scene": ENEMY_GUARD, "pos": Vector2(1100, 192)}
				]
		8:
			if branch == RoomBranch.COMBAT:
				spawn_list = [
					{"scene": ENEMY_ELITE_W1, "pos": Vector2(700, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(450, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(550, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)}
				]
			elif branch == RoomBranch.SUSTAIN:
				spawn_list = [
					{"scene": ENEMY_HOUND, "pos": Vector2(500, 192)},
					{"scene": ENEMY_GUARD, "pos": Vector2(750, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)}
				]
			else:
				spawn_list = [
					{"scene": ENEMY_ELITE_W1, "pos": Vector2(700, 192)},
					{"scene": ENEMY_HOUND, "pos": Vector2(500, 192)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)},
					{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)}
				]
		10:
			# Đại Trùm Cuối World 1 (1.10)
			spawn_list = [
				{"scene": ENEMY_BOSS_W1, "pos": Vector2(900, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1200, 108)}
			]
	return spawn_list

func _spawn_sustain_room_caches() -> void:
	# Sinh bình chứa hồi phục tại các vị trí an toàn trên sàn/bục
	var drop_flask: DropItem = DROP_ITEM_SCENE.instantiate()
	drop_flask.item_type = "life_flask"
	drop_flask.position = Vector2(600, 180)
	entities_node.add_child(drop_flask)

	var drop_shard: DropItem = DROP_ITEM_SCENE.instantiate()
	drop_shard.item_type = "life_shard"
	drop_shard.position = Vector2(630, 180)
	entities_node.add_child(drop_shard)

	var drop_shard2: DropItem = DROP_ITEM_SCENE.instantiate()
	drop_shard2.item_type = "life_shard"
	drop_shard2.position = Vector2(850, 95) # Trên platform cao
	entities_node.add_child(drop_shard2)

func _on_enemy_died(enemy: EnemyBase) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	if active_enemies.size() == 0 and stage_in_progress:
		_on_wave_cleared()

func _on_wave_cleared() -> void:
	stage_in_progress = false
	var stage_str = "%d.%d" % [current_world, current_stage]
	stage_cleared.emit(stage_str)
	_show_banner("ẢI " + stage_str + " HOÀN THÀNH!")

	# Mở cổng chuyển ải theo cơ chế Phân Nhánh (Portal Choice)
	_open_portals()

func _clear_portals() -> void:
	for p in active_portals:
		if is_instance_valid(p):
			p.queue_free()
	active_portals.clear()

func _open_portals() -> void:
	_clear_portals()
	
	var parent_node = world_node if world_node else self
	
	# Các ải đặc biệt (X.4 trước quái tinh anh X.5, X.8 trước trạm nghỉ X.9, X.9 trước Boss X.10, và Boss X.10 sang World sau)
	# chỉ mở 1 Cổng Tiến Bước duy nhất
	if current_stage in [4, 8, 9, 10]:
		var p = PORTAL_SCENE.instantiate()
		parent_node.add_child(p)
		p.global_position = Vector2(1380, 192)
		p.setup(PortalScript.PortalType.STANDARD)
		p.player_chosen_portal.connect(_on_portal_chosen)
		p.activate()
		active_portals.append(p)
		return

	# Các ải thông thường (X.1, X.2, X.3, X.6, X.7):
	# Xuất hiện 2 cánh cổng: Cổng Đao Kiếm & Cổng Sinh Mệnh
	var p_combat = PORTAL_SCENE.instantiate()
	parent_node.add_child(p_combat)
	p_combat.global_position = Vector2(1280, 192)
	p_combat.setup(PortalScript.PortalType.COMBAT)
	p_combat.player_chosen_portal.connect(_on_portal_chosen)
	p_combat.activate()
	active_portals.append(p_combat)

	var p_sustain = PORTAL_SCENE.instantiate()
	parent_node.add_child(p_sustain)
	p_sustain.global_position = Vector2(1440, 192)
	p_sustain.setup(PortalScript.PortalType.SUSTAIN)
	p_sustain.player_chosen_portal.connect(_on_portal_chosen)
	p_sustain.activate()
	active_portals.append(p_sustain)

func _on_portal_chosen(type: int) -> void:
	match type:
		PortalScript.PortalType.COMBAT:
			next_stage(RoomBranch.COMBAT)
		PortalScript.PortalType.SUSTAIN:
			next_stage(RoomBranch.SUSTAIN)
		PortalScript.PortalType.STANDARD:
			next_stage(RoomBranch.STANDARD)

func next_stage(branch: RoomBranch = RoomBranch.STANDARD) -> void:
	if current_stage < 10:
		start_stage(current_world, current_stage + 1, branch)
	else:
		# Đánh bại Boss 10 của World hiện tại -> Chuyển sang World tiếp theo!
		if current_world == 1:
			_show_banner("VƯỢT THÀNH CÔNG THẾ GIỚI 1! TIẾN VÀO HẦM NGỤC HUYẾT RỄ (WORLD 2)!")
			await get_tree().create_timer(3.0).timeout
			start_stage(2, 1, RoomBranch.STANDARD)
		elif current_world == 2:
			_show_banner("CHÚC MỪNG BẠN ĐÃ TIÊU DIỆT MẪU THỂ KÝ SINH!")
			all_stages_completed.emit()
			await get_tree().create_timer(3.0).timeout
			start_stage(1, 1, RoomBranch.STANDARD) # Loop lại New Game+
