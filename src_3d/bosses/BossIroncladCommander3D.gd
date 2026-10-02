class_name BossIroncladCommander3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Boss 1.10 — Thống Lĩnh Thiết Vệ 2.5D (The Ironclad Commander)
## Thiết kế theo chuẩn Detail.md Phần A.V và Phần D.V:
## - Tổng HP: 3,800 | DEF: 4 (Mitigation 7.4%)
## - Phase 1 (50% HP = 1,900 HP): Đại kiếm & Đại khiên, vung kiếm báo đỏ 0.8s (tập Cross-Parry)
## - Phase 2 (<50% HP = 1,900 HP): Bỏ khiên, chuyển sang Song Đao cuồng nộ, tốc độ tăng vọt, combo 3 nhát chém chéo + sóng xung kích
## - Cơ chế Mercy Drop: Cứ mỗi mốc 25% HP mất -> khựng 0.8s và rơi 2 Bình Máu Lớn

signal phase_changed(new_phase: int)
signal boss_defeated()

const TOTAL_HP: float = 3800.0
var current_phase: int = 1
var hp_milestone_threshold: float = TOTAL_HP * 0.75 # Mốc 75%, 50%, 25%

var is_staggered: bool = false
var stagger_timer: float = 0.0

var attack_timer: float = 2.4
var is_attacking: bool = false
var is_warning: bool = false
var warning_timer: float = 0.0
const WARNING_DURATION: float = 0.8

@onready var telegraph_light: OmniLight3D = get_node_or_null("VisualRoot/TelegraphLight")
@onready var boss_sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")

func _ready() -> void:
	enemy_name = "Thống Lĩnh Thiết Vệ (Boss 1.10)"
	max_hp = TOTAL_HP
	current_hp = TOTAL_HP
	def = 4.0 # Mitigation 7.4% chuẩn Detail.md
	base_atk = 28.0
	move_speed = 2.4
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
			_execute_boss_attack()
		return

	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		return

	attack_timer -= delta

	# Tiếp cận người chơi
	var engage_dist = 3.0 if current_phase == 1 else 2.4
	if abs(dist_x) > engage_dist:
		var speed_mult = 1.0 if current_phase == 1 else 1.35
		velocity.x = facing_direction * (move_speed * speed_mult)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		if attack_timer <= 0.0:
			_start_attack_windup()

func _start_attack_windup() -> void:
	is_warning = true
	warning_timer = WARNING_DURATION if current_phase == 1 else 0.55
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_color = Color(1.0, 0.85, 0.1) if current_phase == 1 else Color(1.0, 0.2, 0.3)
	if boss_sprite:
		boss_sprite.modulate = Color(2.0, 1.4, 0.4) if current_phase == 1 else Color(2.5, 0.5, 0.5)

func _execute_boss_attack() -> void:
	is_warning = false
	is_attacking = true
	if telegraph_light:
		telegraph_light.visible = false
	if boss_sprite:
		boss_sprite.modulate = Color.WHITE

	var player = get_player()
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < (4.2 if current_phase == 1 else 3.8):
			var dmg = base_atk * (1.0 if current_phase == 1 else 1.4)
			if player.has_method("take_damage"):
				player.take_damage(dmg, global_position)

	# Cooldown sau đòn đánh
	await get_tree().create_timer(0.3).timeout
	is_attacking = false
	attack_timer = 2.0 if current_phase == 1 else 1.2

func take_hit(amount: float, attacker_pos: Vector3, incoming_crit: bool = false) -> void:
	super.take_hit(amount, attacker_pos, incoming_crit)
	
	# Kiểm tra mốc rơi 2 Bình Máu Lớn mỗi khi mất 25% HP
	if current_hp <= hp_milestone_threshold and hp_milestone_threshold > 0:
		hp_milestone_threshold -= (TOTAL_HP * 0.25)
		_trigger_milestone_drop()

	# Chuyển Phase 2 khi < 50% HP (1,900 HP)
	if current_phase == 1 and current_hp <= (TOTAL_HP * 0.5):
		_enter_phase_2()

func _trigger_milestone_drop() -> void:
	is_staggered = true
	stagger_timer = 0.8
	# Rơi 2 Bình Máu Lớn
	for i in range(2):
		var flask = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(flask)
		flask.global_position = global_position + Vector3(randf_range(-1.2, 1.2), 0.5, 0)
		flask.setup(1, 0, "Bình Máu Lớn")

func _enter_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	move_speed = 3.6
	base_atk = 34.0
	
	# Hiệu ứng nổ hào quang đỏ cuồng nộ
	if boss_sprite:
		var tw = create_tween()
		tw.tween_property(boss_sprite, "modulate", Color(3.0, 0.4, 0.6), 0.2)
		tw.tween_property(boss_sprite, "modulate", Color(1.3, 0.8, 0.8), 0.3)

func die() -> void:
	boss_defeated.emit()
	super.die()
