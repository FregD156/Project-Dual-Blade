class_name EnemyEliteTree
extends EnemyBase

## Quái Tinh Anh 2.5: Cổ Thụ Biến Dị (Aberrant Tree Elite - detail.md V & VI)
## - Đòn vung rễ gai nặng nề (Unparryable báo đỏ 0.8s)
## - Phun phấn độc diện rộng (Toxic Spore Burst)
## - Khi máu xuống thấp, đâm rễ gai từ dưới sàn

func _ready() -> void:
	is_elite = true
	enemy_name = "Cổ Thụ Biến Dị"
	max_hp = 260.0
	current_hp = 260.0
	def = 3.5
	move_speed = 30.0
	attack_damage = 22.0
	attack_range = 45.0
	detection_range = 220.0
	attack_cooldown = 2.4
	windup_time = 0.8
	unparryable_chance = 0.5 # 50% đòn tấn công là đòn búa/gai không thể đỡ
	super._ready()

func _update_sprite_animation(delta: float) -> void:
	# Cổ Thụ to lớn hơi nhấp nhô theo nhịp thở của rễ cây
	anim_step_timer += delta * (4.0 if current_state == State.CHASE else 2.0)
	if sprite:
		sprite.position.y = base_sprite_pos_y + sin(anim_step_timer) * 2.0
