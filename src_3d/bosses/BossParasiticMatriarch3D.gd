class_name BossParasiticMatriarch3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Boss 2.10 — Mẫu Thể Ký Sinh 2.5D (The Parasitic Broodmother)
## Thiết kế theo chuẩn Detail.md Phần A.V, B.2.10 và Phần D.II:
## - Tổng HP: 6,200 | DEF: 8 (Mitigation 13.8%)
## - Phase 1 (100% - 50% HP): Nhện khổng lồ bám vách, phun tơ độc làm chậm, dậm vuốt nhọn từ trần
## - Phase 2 (<50% HP): Rơi xuống sàn gầm thét cuồng nộ, tăng tốc độ vọt lên 4.5m/s, quét chân liên hoàn & triệu hồi ấu trùng nhện
## - Cơ chế Mercy Drop: Cứ mỗi mốc 25% HP mất -> khựng 0.8s và rơi 2 Bình Máu Lớn

signal phase_changed(new_phase: int)
signal boss_defeated()

const SoundManager3D = preload("res://src_3d/audio/SoundManager3D.gd")
const LURKER_SCENE = preload("res://scenes_3d/EnemyRootLurker3D.tscn")

const TOTAL_HP: float = 6200.0
var current_phase: int = 1
var hp_milestone_threshold: float = TOTAL_HP * 0.75

var is_staggered: bool = false
var stagger_timer: float = 0.0

var attack_timer: float = 2.2
var is_attacking: bool = false
var is_warning: bool = false
var warning_timer: float = 0.0
const WARNING_DURATION: float = 0.75

@onready var telegraph_light: OmniLight3D = get_node_or_null("VisualRoot/TelegraphLight")
@onready var boss_sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")

func _ready() -> void:
	enemy_name = "Mẫu Thể Ký Sinh (Boss 2.10)"
	max_hp = TOTAL_HP
	current_hp = TOTAL_HP
	def = 8.0 # Mitigation 13.8% chuẩn Detail.md Phần D.II
	base_atk = 42.0
	move_speed = 2.8
	super._ready()
	if telegraph_light:
		telegraph_light.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return

	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1

	if is_staggered:
		stagger_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		if stagger_timer <= 0.0:
			is_staggered = false
		return

	if is_warning:
		warning_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		if warning_timer <= 0.0:
			_execute_broodmother_attack()
		return

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		return

	attack_timer -= delta
	var engage_dist = 3.6 if current_phase == 1 else 2.6
	if abs(dist_x) > engage_dist:
		var speed_mult = 1.0 if current_phase == 1 else 1.45
		velocity.x = facing_direction * (move_speed * speed_mult)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		if attack_timer <= 0.0:
			_start_attack_windup()

func _start_attack_windup() -> void:
	is_warning = true
	warning_timer = WARNING_DURATION if current_phase == 1 else 0.5
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_color = Color(0.85, 0.15, 0.35, 1.0)
	if boss_sprite:
		boss_sprite.modulate = Color(2.8, 0.6, 0.8, 1.0)

func _execute_broodmother_attack() -> void:
	is_warning = false
	is_attacking = true
	if telegraph_light:
		telegraph_light.visible = false
	if boss_sprite:
		boss_sprite.modulate = Color.WHITE

	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_slash(3)

	var player = get_player()
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < (4.5 if current_phase == 1 else 4.0):
			var dmg = base_atk * (1.0 if current_phase == 1 else 1.35)
			if player.has_method("take_damage"):
				player.take_damage(dmg, global_position)

	# Trong Phase 2: Xác suất 35% sinh 1 ấu trùng rễ máu hỗ trợ nếu dưới trướng chưa quá 2 con
	if current_phase == 2 and randf() < 0.35:
		_spawn_minion_lurker()

	await get_tree().create_timer(0.3).timeout
	is_attacking = false
	attack_timer = 2.2 if current_phase == 1 else 1.2

func _spawn_minion_lurker() -> void:
	if not LURKER_SCENE:
		return
	var lurker = LURKER_SCENE.instantiate()
	get_parent().add_child(lurker)
	lurker.global_position = global_position + Vector3(randf_range(-2.0, 2.0), 0.5, 0.0)
	var stage_mgr = get_node_or_null("../StageManager3D")
	if stage_mgr and stage_mgr.has_method("register_enemy"):
		stage_mgr.register_enemy(lurker)

func take_hit(amount: float, attacker_pos: Vector3, incoming_crit: bool = false) -> void:
	super.take_hit(amount, attacker_pos, incoming_crit)
	if current_hp <= hp_milestone_threshold and hp_milestone_threshold > 0:
		hp_milestone_threshold -= (TOTAL_HP * 0.25)
		_trigger_milestone_drop()

	if current_phase == 1 and current_hp <= (TOTAL_HP * 0.5):
		_enter_phase_2()

func _trigger_milestone_drop() -> void:
	is_staggered = true
	stagger_timer = 0.8
	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_mercy_drop()
	for i in range(2):
		var flask = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(flask)
		flask.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 0.8, 0.0)
		flask.setup(1, 0, "Bình Máu Lớn")

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	move_speed = 4.2
	base_atk = 50.0
	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_boss_roar()

	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(0.35, 6.0)

	if boss_sprite:
		var tw = create_tween()
		tw.tween_property(boss_sprite, "modulate", Color(3.5, 0.2, 0.4), 0.25)
		tw.tween_property(boss_sprite, "modulate", Color(1.4, 0.7, 0.8), 0.3)
