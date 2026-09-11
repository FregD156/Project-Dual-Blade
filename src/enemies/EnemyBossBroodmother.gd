class_name EnemyBossBroodmother
extends EnemyBase

## Đại Trùm Cuối World 2 (2.10): Mẫu Thể Ký Sinh (The Parasitic Broodmother)
## - Phase 1 (HP 100% -> 50%): Tốc độ di chuyển vừa, quất chân nhọn, phun tơ độc.
## - Phase 2 (HP < 50% Cuồng Nộ): Tăng tốc độ vọt lên 90, triệu hồi nhện con, càn quét mặt sàn liên hồi!

signal phase_changed(new_phase: int)
signal boss_hp_updated(current: float, maximum: float, boss_name: String)
signal boss_defeated()

var current_phase: int = 1
var is_enraged: bool = false
var has_dropped_phase_flask: bool = false

func _ready() -> void:
	is_boss = true
	is_elite = false
	enemy_name = "Mẫu Thể Ký Sinh (The Parasitic Broodmother)"
	max_hp = 750.0
	current_hp = 750.0
	def = 4.0
	move_speed = 55.0
	attack_damage = 25.0
	attack_range = 55.0
	detection_range = 300.0
	attack_cooldown = 1.8
	windup_time = 0.65
	unparryable_chance = 0.35
	super._ready()

func _update_sprite_animation(delta: float) -> void:
	# Nhện khổng lồ rung lắc thân bụng chứa túi trứng khi di chuyển
	anim_step_timer += delta * (7.0 if current_phase == 2 else 4.0)
	if sprite:
		sprite.position.y = base_sprite_pos_y + sin(anim_step_timer) * 2.5

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	super._on_hit_received(incoming_hitbox)
	boss_hp_updated.emit(current_hp, max_hp, enemy_name)
	
	# Kiểm tra chuyển Phase khi máu dưới 50%
	if current_phase == 1 and (current_hp / max_hp) <= 0.5:
		_enter_phase_2()

func _enter_phase_2() -> void:
	current_phase = 2
	is_enraged = true
	phase_changed.emit(2)
	
	# Cuồng nộ: Tăng tốc chạy, tăng sát thương, giảm hồi chiêu
	move_speed = 90.0
	attack_damage = 32.0
	attack_cooldown = 1.2
	windup_time = 0.45
	unparryable_chance = 0.45
	
	# Rơi 2 Bình Máu Lớn theo cơ chế Mercy Drop của Boss (detail.md VII.3)
	if not has_dropped_phase_flask:
		has_dropped_phase_flask = true
		_drop_item("life_flask")
		_drop_item("life_flask")

	# Hiệu ứng đỏ rực toàn thân gầm rú
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.2)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)

func _die() -> void:
	boss_defeated.emit()
	super._die()
