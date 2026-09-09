class_name BossIroncladCommander
extends CharacterBody2D

## Boss 1.10 — Thống Lĩnh Thiết Vệ (The Ironclad Commander)
## HP: 3,800 | DEF: 4 (Mitigation 7.4%) | Kháng Choáng: 300
## Phase 1: 1,900 HP - Đại kiếm vung uy lực, báo đỏ 0.8s (tập parry)
## Phase 2: 1,900 HP - Bỏ khiên dùng song đao, combo 3 nhát + sóng chấn động sàn
## Boss Room Rule: Cứ mỗi 25% HP mất -> khựng + rơi 2 Bình Máu; 3 Parry liên tiếp -> rơi 1 Hạt Sinh Mệnh

signal phase_changed(new_phase: int)
signal boss_defeated
signal drop_life_flasks(count: int, pos: Vector2)
signal drop_life_shard(pos: Vector2)

const TOTAL_HP: float = 3800.0
var current_hp: float = 3800.0
var def: float = 4.0
var current_phase: int = 1

# Ngưỡng máu 25% rơi bình máu
var hp_milestone_threshold: float = TOTAL_HP * 0.75 # mốc 75%, 50%, 25%
var is_staggered: bool = false
var stagger_timer: float = 0.0

# Combat State
var attack_timer: float = 2.5
var is_attacking: bool = false
var is_warning: bool = false
var warning_timer: float = 0.0
const WARNING_DURATION: float = 0.8

@onready var visual: AnimatedSprite2D = $AnimSprite
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hp_bar_label: Label = $BossUI/HPLabel
@onready var phase_label: Label = $BossUI/PhaseLabel

func _ready() -> void:
	current_hp = TOTAL_HP
	hurtbox.hit_received.connect(_on_hit_received)
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	_setup_animations()
	_update_ui()

func _setup_animations() -> void:
	if visual and visual.sprite_frames == null:
		var sf := SpriteFrames.new()
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", 4.0)
		for i in range(3):
			sf.add_frame("idle", load("res://assets/sprites/enemies/boss_commander_anim_%d.png" % i))
		visual.sprite_frames = sf
		visual.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 900.0 * delta
		move_and_slide()

	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0.0:
			is_staggered = false
		return

	if is_warning:
		warning_timer -= delta
		if warning_timer <= 0.0:
			_execute_attack()
	elif not is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_start_attack_windup()

func _start_attack_windup() -> void:
	is_warning = true
	warning_timer = WARNING_DURATION
	visual.modulate = Color(1.2, 0.8, 0.2) # Báo vàng (Phase 1 tập parry)
	if phase_label:
		phase_label.text = "BOSS: Vung Đại Kiếm! (Parry [K] ngay khi chém!)"

func _execute_attack() -> void:
	is_warning = false
	is_attacking = true
	visual.modulate = Color(1.0, 1.0, 1.0)
	
	attack_hitbox.damage = 35.0 if current_phase == 1 else 45.0
	attack_hitbox.skill_mult = 1.0
	attack_hitbox.is_unparryable = false # Phase 1 cho phép parry
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	
	await get_tree().create_timer(0.18).timeout
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	is_attacking = false
	attack_timer = 2.0 if current_phase == 1 else 1.2
	if phase_label:
		phase_label.text = "Phase %d — Thống Lĩnh Thiết Vệ" % current_phase

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	var result = DamageCalculator.calculate_damage(
		incoming_hitbox.damage,
		incoming_hitbox.skill_mult,
		def,
		0.0,
		50.0,
		incoming_hitbox.is_crit
	)
	var dmg: float = result["damage"]
	current_hp = max(0.0, current_hp - dmg)
	_update_ui()
	
	# Kiểm tra mốc 25% HP để rơi 2 Bình Máu Lớn & khựng nhẹ
	if current_hp <= hp_milestone_threshold and hp_milestone_threshold > 0:
		hp_milestone_threshold -= (TOTAL_HP * 0.25)
		_trigger_stagger_and_drop_flasks()
		
	# Kiểm tra chuyển Phase 2 (< 50% HP = 1,900 HP)
	if current_phase == 1 and current_hp <= 1900.0:
		_transition_to_phase_2()

	if current_hp <= 0:
		_on_defeated()

func _trigger_stagger_and_drop_flasks() -> void:
	is_staggered = true
	stagger_timer = 0.8
	drop_life_flasks.emit(2, global_position)
	print("[BOSS MECHANIC] Boss mất 25% HP! Khựng nhẹ và văng 2 Bình Máu Lớn!")

func _transition_to_phase_2() -> void:
	current_phase = 2
	phase_changed.emit(2)
	visual.modulate = Color(1.2, 0.4, 0.4) # Đổi sắc đỏ rực rỡ ở Phase 2
	print("[BOSS PHASE 2] Thống Lĩnh vứt bỏ khiên! Vào trạng thái Cuồng Nộ Song Đao!")

func _on_defeated() -> void:
	boss_defeated.emit()
	print("[BOSS DEFEATED] THỐNG LĨNH THIẾT VỆ ĐÃ BỊ HẠ GỤC! WORLD 1 HOÀN THÀNH!")

func _update_ui() -> void:
	if hp_bar_label:
		hp_bar_label.text = "THỐNG LĨNH THIẾT VỆ: %d / %d HP" % [round(current_hp), round(TOTAL_HP)]
