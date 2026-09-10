class_name EnemyBossCommander
extends EnemyBase

## Boss 1.10: Thống Lĩnh Thiết Vệ (The Ironclad Commander) theo detail.md
## Phase 1 (HP >= 50%):
## - Vung đại kiếm uy lực cao (Windup 0.8s), báo hiệu vệt đỏ/sao vàng tập Parry
## - Tốc độ di chuyển chậm, giáp kiên cố
## Phase 2 (HP < 50% - Enrage):
## - Vứt bỏ khiên, chuyển sang cầm Song Đao tốc độ cao
## - Tốc độ di chuyển tăng mạnh (42 -> 78)
## - Đòn đánh liên hoàn tốc độ nhanh + bắn sóng xung kích chấn động mặt sàn (Ground Shockwave)
## - Khi tụt mỗi 25% HP (75%, 50%, 25%): Boss khựng và văng ra 2 Bình Máu Lớn (Mercy Drop theo detail.md)

signal phase_changed(new_phase: int)
signal boss_hp_updated(current: float, maximum: float, boss_name: String)
signal boss_defeated()

var current_phase: int = 1
var hp_threshold_75: bool = false
var hp_threshold_50: bool = false
var hp_threshold_25: bool = false

func _ready() -> void:
	super._ready()
	enemy_name = "Thống Lĩnh Thiết Vệ (The Ironclad Commander)"
	is_boss = true
	is_elite = true
	max_hp = 600.0
	current_hp = max_hp
	def = 10.0 # ARPG mitigation
	move_speed = 45.0
	attack_damage = 32.0
	windup_time = 0.8
	attack_cooldown = 1.8
	unparryable_chance = 0.35
	
	# Thông báo HP ban đầu cho UI Boss Bar
	call_deferred("_emit_boss_hp")

func _emit_boss_hp() -> void:
	boss_hp_updated.emit(current_hp, max_hp, enemy_name)

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Tạo vệt mờ (Ghost trail) trong Phase 2 khi lướt chém
	if current_phase == 2 and abs(velocity.x) > 40.0:
		if randf() < 0.18 and sprite and get_parent():
			var trail = GhostTrail.new()
			get_parent().add_child(trail)
			trail.setup(sprite, Color(1.0, 0.2, 0.4, 0.6))

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	super._on_hit_received(incoming_hitbox)
	_emit_boss_hp()

	# Kiểm tra cơ chế rơi bình máu theo ngưỡng 25% máu (detail.md Phần A.3)
	var hp_ratio = current_hp / max_hp
	if hp_ratio <= 0.75 and not hp_threshold_75:
		hp_threshold_75 = true
		_trigger_mercy_flask_drop()
	if hp_ratio <= 0.50 and not hp_threshold_50:
		hp_threshold_50 = true
		_trigger_phase_2()
		_trigger_mercy_flask_drop()
	if hp_ratio <= 0.25 and not hp_threshold_25:
		hp_threshold_25 = true
		_trigger_mercy_flask_drop()

func _trigger_mercy_flask_drop() -> void:
	# Khựng nhẹ và văng 2 bình máu lớn (Life Flask)
	HitStopManager.freeze(get_tree(), 0.12, 0.05)
	if drop_item_scene and get_parent():
		for i in range(2):
			var flask = drop_item_scene.instantiate()
			flask.item_type = "life_flask"
			flask.global_position = global_position + Vector2(randf_range(-30, 30), -20)
			flask.base_ground_pos_y = 192.0
			get_parent().call_deferred("add_child", flask)

func _trigger_phase_2() -> void:
	if current_phase == 2:
		return
	current_phase = 2
	phase_changed.emit(2)
	
	# Phase 2: Bỏ khiên, Song Đao cuồng bạo
	move_speed = 78.0
	attack_cooldown = 1.1
	windup_time = 0.45
	attack_damage = 38.0
	unparryable_chance = 0.45
	
	# Hiệu ứng nộ (Enrage roar / flash đỏ rực)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(3.0, 0.3, 0.3, 1.0), 0.3)
		tween.tween_property(sprite, "modulate", Color(1.2, 0.8, 0.8, 1.0), 0.4)
		
	# Báo hiệu lên màn hình
	VFXManager.spawn_combat_impact(get_parent(), global_position + Vector2(0, -35), Vector2.UP, 0, false, false)

func _execute_attack() -> void:
	if current_phase == 1:
		super._execute_attack()
	else:
		# Phase 2: Chém kép + Sóng chấn động mặt sàn (Ground Shockwave)
		current_state = State.ATTACK
		_hide_telegraph()
		
		if sprite:
			sprite.frame = min(sprite.hframes - 1, 2)
			
		# Nhát 1
		if attack_hitbox:
			attack_hitbox.damage = attack_damage * 0.7
			attack_hitbox.is_unparryable = next_attack_unparryable
			attack_hitbox.monitoring = true
			attack_hitbox.monitorable = true
			
		await get_tree().create_timer(0.12).timeout
		
		if attack_hitbox:
			attack_hitbox.monitoring = false
			attack_hitbox.monitorable = false
			
		# Nhát 2 tung sóng chấn động mặt sàn
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(self) and current_state != State.DEAD:
			if attack_hitbox:
				attack_hitbox.damage = attack_damage
				attack_hitbox.is_unparryable = true # Sóng chấn động không thể đỡ thường
				attack_hitbox.monitoring = true
				attack_hitbox.monitorable = true
			
			_spawn_ground_shockwave()
			await get_tree().create_timer(0.15).timeout
			
			if attack_hitbox:
				attack_hitbox.monitoring = false
				attack_hitbox.monitorable = false
				
			current_state = State.IDLE
			attack_timer = attack_cooldown

func _spawn_ground_shockwave() -> void:
	if get_parent():
		var shock_hitbox = Hitbox.new()
		shock_hitbox.damage = attack_damage * 0.8
		shock_hitbox.is_unparryable = true
		
		var col = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = Vector2(36, 24)
		col.shape = box
		shock_hitbox.add_child(col)
		
		shock_hitbox.collision_layer = 8
		shock_hitbox.collision_mask = 4
		shock_hitbox.global_position = global_position + Vector2(facing_direction * 25, -12)
		get_parent().add_child(shock_hitbox)
		
		var tween = get_tree().create_tween()
		var target_x = shock_hitbox.global_position.x + facing_direction * 180.0
		tween.tween_property(shock_hitbox, "global_position:x", target_x, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(col, "scale", Vector2(1.5, 1.5), 0.45)
		tween.tween_callback(func():
			if is_instance_valid(shock_hitbox):
				shock_hitbox.queue_free()
		)

func _die() -> void:
	boss_defeated.emit()
	super._die()
