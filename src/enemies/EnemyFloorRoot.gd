class_name EnemyFloorRoot
extends EnemyBase

## Quái Đặc Thù World 2: Rễ Con Đâm Sàn (The Floor Root - detail.md Phần C World 2)
## - Dạng "trap sống" ngụy trang ẩn dưới sàn đá / bùn huyết rễ
## - Bất động, khi người chơi tiến vào phạm vi (detection_range), trồi gai nhọn lên đâm
## - Đòn đâm có 50% tỉ lệ unparryable (báo đỏ)

var is_burrowed: bool = true
var eruption_height: float = 0.0

func _ready() -> void:
	enemy_name = "Rễ Con Đâm Sàn"
	max_hp = 110.0
	current_hp = 110.0
	def = 5.0
	move_speed = 0.0 # Bất động
	attack_damage = 22.0
	attack_range = 45.0
	detection_range = 75.0
	attack_cooldown = 2.0
	windup_time = 0.4
	unparryable_chance = 0.5
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	# Giữ vị trí trên sàn, không di chuyển ngang
	velocity.x = 0.0
	velocity.y += 850.0 * delta
	move_and_slide()
	
	_find_player()
	if not target_player:
		return
		
	var dist = global_position.distance_to(target_player.global_position)
	facing_direction = 1 if target_player.global_position.x > global_position.x else -1
	_update_facing()
	
	if current_state == State.IDLE:
		if attack_timer > 0.0:
			attack_timer -= delta
		elif dist <= detection_range:
			_start_windup()
	elif current_state == State.WINDUP:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_execute_attack()

func _start_windup() -> void:
	super._start_windup()
	# Rung lắc mặt đất báo hiệu gai sắp trồi lên
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "position:x", 1.5, 0.05)
		tw.tween_property(sprite, "position:x", -1.5, 0.05)
		tw.tween_property(sprite, "position:x", 0.0, 0.05)

func _execute_attack() -> void:
	current_state = State.ATTACK
	_hide_telegraph()
	
	# Trồi gai nhọn nhô vọt lên từ mặt đất
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale:y", 0.09, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	if attack_hitbox:
		attack_hitbox.damage = attack_damage
		attack_hitbox.is_unparryable = next_attack_unparryable
		attack_hitbox.monitoring = true
		attack_hitbox.monitorable = true
		
	await get_tree().create_timer(0.3).timeout
	
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
		
	# Rút gai lại về trạng thái chờ
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale:y", 0.05, 0.2)
		
	if current_state != State.DEAD:
		current_state = State.IDLE
		attack_timer = attack_cooldown
