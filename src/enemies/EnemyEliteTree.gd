class_name EnemyEliteTree
extends EnemyBase

## Quái Tinh Anh 2.5: Cổ Thụ Biến Dị (Aberrant Tree Elite - detail.md V & VI)
## - Đòn vung rễ gai nặng nề (Unparryable báo đỏ 0.8s)
## - Phun phấn độc diện rộng (Toxic Spore Burst)
## - Khi máu xuống thấp, đâm rễ gai từ dưới sàn

func _ready() -> void:
	is_elite = true
	enemy_name = "Cổ Thụ Biến Dị"
	max_hp = 320.0
	current_hp = 320.0
	def = 5.0
	move_speed = 32.0
	attack_damage = 24.0
	attack_range = 50.0
	detection_range = 240.0
	attack_cooldown = 2.2
	windup_time = 0.8
	unparryable_chance = 0.5 # 50% đòn tấn công là đòn rễ gai không thể đỡ (báo đỏ)
	super._ready()

func _update_sprite_animation(delta: float) -> void:
	# Cổ Thụ to lớn hơi nhấp nhô theo nhịp thở của rễ cây
	anim_step_timer += delta * (4.0 if current_state == State.CHASE else 2.0)
	if sprite:
		sprite.position.y = base_sprite_pos_y + sin(anim_step_timer) * 2.0

func _execute_attack() -> void:
	current_state = State.ATTACK
	_hide_telegraph()
	
	# Đòn vung rễ đập sàn
	if attack_hitbox:
		attack_hitbox.damage = attack_damage
		attack_hitbox.is_unparryable = next_attack_unparryable
		attack_hitbox.monitoring = true
		attack_hitbox.monitorable = true
		
	await get_tree().create_timer(0.3).timeout
	
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
		
	# Khi máu < 60%, tung thêm chiêu Rễ Gai đâm từ dưới sàn (Root Spikes)
	if is_instance_valid(self) and current_state != State.DEAD and (current_hp / max_hp) <= 0.6:
		_spawn_root_spikes()

	if current_state != State.DEAD:
		current_state = State.IDLE
		attack_timer = attack_cooldown

func _spawn_root_spikes() -> void:
	if not get_parent():
		return
	var spike_hitbox = Hitbox.new()
	spike_hitbox.damage = attack_damage * 0.75
	spike_hitbox.is_unparryable = true
	
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(40, 30)
	col.shape = box
	spike_hitbox.add_child(col)
	
	spike_hitbox.collision_layer = 8
	spike_hitbox.collision_mask = 4
	spike_hitbox.global_position = global_position + Vector2(facing_direction * 65.0, 0)
	get_parent().add_child(spike_hitbox)
	
	# Hiệu ứng rễ gai nhô lên từ sàn
	var tween = get_tree().create_tween()
	tween.tween_property(spike_hitbox, "position:y", spike_hitbox.position.y - 12.0, 0.15)
	tween.tween_interval(0.2)
	tween.tween_property(spike_hitbox, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		if is_instance_valid(spike_hitbox):
			spike_hitbox.queue_free()
	)
