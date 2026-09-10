class_name EnemyArcher
extends EnemyBase

## Lớp điều khiển riêng cho quái Watchtower Archer (Cung Thủ Tháp Canh)
## Bắn mũi tên vật lý bay ra thay vì chỉ bật Hitbox tĩnh.

@export var arrow_scene: PackedScene = preload("res://scenes/projectiles/ArrowProjectile.tscn")
@export var projectile_speed: float = 280.0

func _execute_attack() -> void:
	current_state = State.ATTACK
	_hide_telegraph()
	
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	elif sprite:
		# Frame giương cung bắn
		var hf = sprite.hframes
		sprite.frame = 3 if hf >= 4 else (2 if hf == 3 else 0)

	# Bắn mũi tên ra
	_spawn_arrow()

	# Chờ cooldown hồi hoạt ảnh
	await get_tree().create_timer(0.35).timeout

	if current_state != State.DEAD:
		current_state = State.IDLE
		attack_timer = attack_cooldown

func _spawn_arrow() -> void:
	if not arrow_scene:
		return

	var arrow = arrow_scene.instantiate()
	var spawn_pos = global_position + Vector2(facing_direction * 12.0, -14.0)
	arrow.global_position = spawn_pos
	
	var dir = Vector2(facing_direction, 0.0)
	# Nếu có target_player, có thể bắn hơi chúc nhẹ theo độ cao player nếu cần
	if target_player and is_instance_valid(target_player):
		var to_player = (target_player.global_position + Vector2(0, -14.0)) - spawn_pos
		# Archer bắn ngang hoặc nghiêng nhẹ tối đa 15 độ
		dir = to_player.normalized()
		# Giới hạn góc bắn không chúc quá thẳng xuống đất
		dir.y = clamp(dir.y, -0.3, 0.3)
		dir = dir.normalized()

	arrow.setup(dir, attack_damage, next_attack_unparryable, self)
	arrow.speed = projectile_speed

	# Thêm mũi tên vào cùng cây cha (thường là StageManager hoặc Projectiles group)
	get_parent().add_child(arrow)
