class_name EnemyRustyGuard3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Lính Gác Rỉ Sét 3D: Cận chiến, vung đao nặng, có báo hiệu đỏ tập parry

var attack_cooldown: float = 2.4
var attack_timer: float = 0.0
var is_attacking: bool = false
var is_telegraphing: bool = false

@onready var telegraph_light: OmniLight3D = $VisualRoot/TelegraphLight
@onready var attack_area: Area3D = $AttackArea

func _ready() -> void:
	max_hp = 110.0
	base_atk = 14.0
	move_speed = 3.0
	super._ready()
	if telegraph_light:
		telegraph_light.visible = false
	if attack_area:
		attack_area.monitoring = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		return
		
	var dist_x = player.global_position.x - global_position.x
	var dist_y = abs(player.global_position.y - global_position.y)
	facing_direction = 1 if dist_x > 0 else -1
	
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		return
		
	attack_timer -= delta
	
	# Nếu người chơi ở tầng khác (quá cao hoặc quá thấp), lính gác giữ vị trí cảnh giác
	if dist_y > 2.0:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		return
	
	if abs(dist_x) > 1.8:
		# Tiếp cận người chơi
		velocity.x = facing_direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		if attack_timer <= 0.0:
			_start_attack_cycle()

func _start_attack_cycle() -> void:
	is_attacking = true
	is_telegraphing = true
	if telegraph_light:
		telegraph_light.visible = true
		
	# Báo hiệu đỏ 0.65s trước khi chém (cửa sổ chuẩn bị cho người chơi parry)
	var tw = create_tween()
	tw.tween_interval(0.65)
	tw.tween_callback(_strike)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		is_attacking = false
		attack_timer = attack_cooldown
	)

func _strike() -> void:
	is_telegraphing = false
	if telegraph_light:
		telegraph_light.visible = false
		
	var player = get_player()
	if player and global_position.distance_to(player.global_position) < 2.3:
		if player.has_method("take_damage"):
			player.take_damage(base_atk, global_position)
