class_name StageManager
extends Node2D

## StageManager quản lý Vòng lặp Vượt ải (Loop Pacing & Stage Progression) theo detail.md
## Cấu trúc: 
## X.1 -> X.4: Quái thường khởi động (Rusty Guard, Chain Hound, Archer)
## X.5: Quái Tinh Anh (Thủ Lĩnh Đao Phủ Quỷ - Elite Demon Executioner)
## X.6 -> X.8: Đẩy cao độ khó (Mật độ quái dày, bắn tỉa & giáp nặng)
## X.9: Trạm Nghỉ An Toàn (Safe Haven - Hồi máu, Rèn đồ, Checkpoint)
## X.10: Sàn Đấu Đại Trùm (Thống Lĩnh Thiết Vệ - Boss Ironclad Commander)

signal stage_changed(stage_str: String, stage_name: String)
signal stage_cleared(stage_str: String)
signal all_stages_completed()

@export var current_world: int = 1
@export var current_stage: int = 1
@export var is_loop_active: bool = true

@onready var world_node: Node2D = get_node_or_null("../World")
@onready var entities_node: Node2D = get_node_or_null("../World/Entities")
@onready var spawner_node: EnemySpawner = get_node_or_null("../World/EnemySpawner")
@onready var portal_node: Area2D = get_node_or_null("../World/Portal")
@onready var banner_label: Label = get_node_or_null("../UI_Layer/StageBanner/BannerLabel")
@onready var banner_panel: Control = get_node_or_null("../UI_Layer/StageBanner")

const ENEMY_GUARD = preload("res://scenes/enemies/EnemyRustyGuard.tscn")
const ENEMY_HOUND = preload("res://scenes/enemies/EnemyChainHound.tscn")
const ENEMY_ARCHER = preload("res://scenes/enemies/EnemyArcher.tscn")
const ENEMY_ELITE = preload("res://scenes/enemies/EnemyEliteExecutioner.tscn")
const ENEMY_BOSS = preload("res://scenes/enemies/EnemyBossCommander.tscn")

var active_enemies: Array[EnemyBase] = []
var stage_in_progress: bool = false
var enemies_to_spawn: int = 0

func _ready() -> void:
	if portal_node:
		portal_node.visible = false
		portal_node.body_entered.connect(_on_portal_entered)
	
	call_deferred("start_stage", current_world, current_stage)

func start_stage(world_idx: int, stage_idx: int) -> void:
	current_world = world_idx
	current_stage = stage_idx
	stage_in_progress = true
	
	if portal_node:
		portal_node.visible = false
		portal_node.set_deferred("monitoring", false)
		
	var stage_str = "%d.%d" % [current_world, current_stage]
	var title = _get_stage_title(current_stage)
	
	_show_banner(stage_str + ": " + title)
	stage_changed.emit(stage_str, title)
	
	_spawn_stage_wave(current_stage)

func _get_stage_title(stage: int) -> String:
	match stage:
		1: return "Cổ Thành Khởi Đầu"
		2: return "Tiền Tuyến Bị Phá Hủy"
		3: return "Chiến Hào Đẫm Máu"
		4: return "Quân Tiên Phong"
		5: return "QUÁI TINH ANH - Đao Phủ Quỷ"
		6: return "Thành Lũy Đổ Nát"
		7: return "Hào Chông Tàn Sát"
		8: return "Tử Địa Giáp Đen"
		9: return "TRẠM NGHỈ AN TOÀN (Lão Thợ Rèn)"
		10: return "ĐẠI TRÙM - Thống Lĩnh Thiết Vệ"
		_: return "Sàn Đấu Vượt Ải"

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

func _spawn_stage_wave(stage: int) -> void:
	# Clear any previous enemies
	for e in active_enemies:
		if is_instance_valid(e):
			e.queue_free()
	active_enemies.clear()

	if stage == 9:
		# Safe Haven: Không có quái, mở cổng ngay
		_on_wave_cleared()
		return

	var spawn_list = []
	match stage:
		1:
			spawn_list = [
				{"scene": ENEMY_GUARD, "pos": Vector2(400, 192)},
				{"scene": ENEMY_GUARD, "pos": Vector2(650, 192)}
			]
		2:
			spawn_list = [
				{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(680, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)}
			]
		3:
			spawn_list = [
				{"scene": ENEMY_HOUND, "pos": Vector2(400, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(620, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(850, 108)},
				{"scene": ENEMY_GUARD, "pos": Vector2(1050, 192)}
			]
		4:
			spawn_list = [
				{"scene": ENEMY_GUARD, "pos": Vector2(380, 192)},
				{"scene": ENEMY_GUARD, "pos": Vector2(580, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(820, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(980, 108)}
			]
		5:
			# Elite Mid-boss (1.5)
			spawn_list = [
				{"scene": ENEMY_ELITE, "pos": Vector2(750, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)},
				{"scene": ENEMY_GUARD, "pos": Vector2(550, 192)}
			]
		6:
			spawn_list = [
				{"scene": ENEMY_GUARD, "pos": Vector2(450, 192)},
				{"scene": ENEMY_GUARD, "pos": Vector2(650, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(850, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1050, 108)}
			]
		7:
			spawn_list = [
				{"scene": ENEMY_HOUND, "pos": Vector2(450, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(680, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(880, 108)},
				{"scene": ENEMY_GUARD, "pos": Vector2(1100, 192)}
			]
		8:
			spawn_list = [
				{"scene": ENEMY_ELITE, "pos": Vector2(700, 192)},
				{"scene": ENEMY_HOUND, "pos": Vector2(500, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(950, 108)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1150, 108)}
			]
		10:
			# Đại Trùm Cuối World 1 (1.10)
			spawn_list = [
				{"scene": ENEMY_BOSS, "pos": Vector2(900, 192)},
				{"scene": ENEMY_ARCHER, "pos": Vector2(1200, 108)}
			]

	for item in spawn_list:
		var scn: PackedScene = item["scene"]
		var pos: Vector2 = item["pos"]
		var enemy: EnemyBase = scn.instantiate()
		enemy.global_position = pos
		enemy.died.connect(_on_enemy_died)
		entities_node.add_child(enemy)
		active_enemies.append(enemy)

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

	# Mở cổng dịch chuyển
	if portal_node:
		portal_node.visible = true
		portal_node.global_position = Vector2(1380, 192) # Đặt ở cuối bản đồ
		portal_node.set_deferred("monitoring", true)

func _on_portal_entered(body: Node2D) -> void:
	if body is Player and not stage_in_progress:
		next_stage()

func next_stage() -> void:
	if current_stage < 10:
		start_stage(current_world, current_stage + 1)
	else:
		# Kết thúc vòng lặp World 1, lặp lại với độ khó tăng (New Game+ / World tiếp theo)
		_show_banner("CHÚC MỪNG BẠN ĐÃ ĐÁNH BẠI ĐẠI TRÙM THẾ GIỚI 1!")
		all_stages_completed.emit()
		await get_tree().create_timer(3.0).timeout
		start_stage(1, 1) # Loop lại ải 1
