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
var hp_threshold_75: bool = false
var hp_threshold_50: bool = false
var hp_threshold_25: bool = false

const SPIDER_MINION_SCENE = preload("res://scenes/enemies/EnemyCrimsonSpider.tscn")

func _ready() -> void:
	is_boss = true
	is_elite = true
	enemy_name = "Mẫu Thể Ký Sinh (The Parasitic Broodmother)"
	max_hp = 780.0
	current_hp = 780.0
	def = 8.0 # detail.md Part D: Boss 2.10 DEF = 8 (Mitigation 13.8%)
	move_speed = 52.0
	attack_damage = 26.0
	attack_range = 60.0
	detection_range = 320.0
	attack_cooldown = 1.9
	windup_time = 0.65
	unparryable_chance = 0.35
	super._ready()
	call_deferred("_emit_boss_hp")

func _emit_boss_hp() -> void:
	boss_hp_updated.emit(current_hp, max_hp, enemy_name)

func _update_sprite_animation(delta: float) -> void:
	# Nhện khổng lồ rung lắc thân bụng chứa túi trứng khi di chuyển
	anim_step_timer += delta * (7.0 if current_phase == 2 else 4.0)
	if sprite:
		sprite.position.y = base_sprite_pos_y + sin(anim_step_timer) * 2.5

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	super._on_hit_received(incoming_hitbox)
	_emit_boss_hp()
	
	# Cơ chế Mercy Drop phòng Boss theo detail.md VII.3: Mỗi mốc 25% rơi 2 bình máu lớn
	var hp_ratio = current_hp / max_hp
	if hp_ratio <= 0.75 and not hp_threshold_75:
		hp_threshold_75 = true
		_trigger_mercy_flask_drop()
	if hp_ratio <= 0.50 and not hp_threshold_50:
		hp_threshold_50 = true
		_enter_phase_2()
		_trigger_mercy_flask_drop()
	if hp_ratio <= 0.25 and not hp_threshold_25:
		hp_threshold_25 = true
		_trigger_mercy_flask_drop()

func _trigger_mercy_flask_drop() -> void:
	HitStopManager.freeze(get_tree(), 0.1, 0.05)
	if drop_item_scene and get_parent():
		for i in range(2):
			var flask = drop_item_scene.instantiate()
			flask.item_type = "life_flask"
			flask.global_position = global_position + Vector2(randf_range(-35, 35), -20)
			flask.base_ground_pos_y = 192.0
			get_parent().call_deferred("add_child", flask)

func _enter_phase_2() -> void:
	if current_phase == 2:
		return
	current_phase = 2
	is_enraged = true
	phase_changed.emit(2)
	
	# Cuồng nộ Phase 2 (detail.md V & P6.1): Rơi sàn, càn quét, tốc độ cao, triệu hồi nhện con
	move_speed = 85.0
	attack_damage = 34.0
	attack_cooldown = 1.2
	windup_time = 0.45
	unparryable_chance = 0.45
	
	# Triệu hồi 2 nhện con từ túi trứng vỡ
	call_deferred("_spawn_spider_minions", 2)

	# Hiệu ứng đỏ rực toàn thân gầm rú nộ khí
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(3.0, 0.3, 0.5, 1.0), 0.25)
		tw.tween_property(sprite, "modulate", Color(1.2, 0.8, 0.9, 1.0), 0.35)

func _execute_attack() -> void:
	current_state = State.ATTACK
	_hide_telegraph()
	
	if current_phase == 1:
		# Phase 1: Quất chân nhọn + Phun tơ làm chậm diện rộng
		if attack_hitbox:
			attack_hitbox.damage = attack_damage
			attack_hitbox.is_unparryable = next_attack_unparryable
			attack_hitbox.monitoring = true
			attack_hitbox.monitorable = true
			
		await get_tree().create_timer(0.25).timeout
		
		if attack_hitbox:
			attack_hitbox.monitoring = false
			attack_hitbox.monitorable = false
			
		# 40% cơ hội bắn cầu tơ độc
		if randf() < 0.4:
			_shoot_toxic_web()
	else:
		# Phase 2: Càn quét kép 2 nhát liên hồi + có thể gọi nhện con
		if attack_hitbox:
			attack_hitbox.damage = attack_damage * 0.7
			attack_hitbox.is_unparryable = next_attack_unparryable
			attack_hitbox.monitoring = true
			attack_hitbox.monitorable = true
			
		await get_tree().create_timer(0.12).timeout
		
		if attack_hitbox:
			attack_hitbox.monitoring = false
			attack_hitbox.monitorable = false
			
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(self) and current_state != State.DEAD:
			if attack_hitbox:
				attack_hitbox.damage = attack_damage
				attack_hitbox.is_unparryable = true
				attack_hitbox.monitoring = true
				attack_hitbox.monitorable = true
				
			await get_tree().create_timer(0.18).timeout
			if attack_hitbox:
				attack_hitbox.monitoring = false
				attack_hitbox.monitorable = false
				
			# Nếu còn ít hơn 2 quái nhện con trên sân, đẻ thêm 1 nhện con
			if randf() < 0.3:
				_spawn_spider_minions(1)

	if current_state != State.DEAD:
		current_state = State.IDLE
		attack_timer = attack_cooldown

func _shoot_toxic_web() -> void:
	if not get_parent():
		return
	var web_hitbox = Hitbox.new()
	web_hitbox.damage = attack_damage * 0.6
	web_hitbox.is_unparryable = true
	
	var col = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = Vector2(28, 20)
	col.shape = box
	web_hitbox.add_child(col)
	
	web_hitbox.collision_layer = 8
	web_hitbox.collision_mask = 4
	web_hitbox.global_position = global_position + Vector2(facing_direction * 25, -16)
	get_parent().add_child(web_hitbox)
	
	var tween = get_tree().create_tween()
	var target_x = web_hitbox.global_position.x + facing_direction * 160.0
	tween.tween_property(web_hitbox, "global_position:x", target_x, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if is_instance_valid(web_hitbox):
			web_hitbox.queue_free()
	)

func _spawn_spider_minions(count: int) -> void:
	if not get_parent() or not SPIDER_MINION_SCENE:
		return
	for i in range(count):
		var spider = SPIDER_MINION_SCENE.instantiate()
		spider.global_position = global_position + Vector2(randf_range(-40, 40), 0)
		spider.stage_number = stage_number
		get_parent().call_deferred("add_child", spider)

func _die() -> void:
	boss_defeated.emit()
	super._die()
