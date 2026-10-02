class_name EnemyChainHound3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Chó Săn Xích Sắt 3D: Tốc độ cao, áp sát cực nhanh, nhảy vồ (Pounce)

var pounce_cooldown: float = 2.6
var pounce_timer: float = 0.8
var is_pouncing: bool = false

func _ready() -> void:
	max_hp = 65.0
	base_atk = 10.0
	move_speed = 6.2
	super._ready()

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		return
		
	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1
	
	if is_pouncing:
		if is_on_floor() and velocity.y <= 0:
			is_pouncing = false
		return
		
	pounce_timer -= delta
	var dist_y = player.global_position.y - global_position.y
	if dist_y > 2.5:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		return
	
	if abs(dist_x) > 3.8:
		# Chạy nhanh áp sát
		velocity.x = facing_direction * move_speed
	else:
		# Nhảy vồ
		if pounce_timer <= 0.0:
			_pounce(player)

func _pounce(_player: Node3D) -> void:
	is_pouncing = true
	pounce_timer = pounce_cooldown
	velocity.x = facing_direction * 9.5
	velocity.y = 8.5
	
	var tw = create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func():
		var p = get_player()
		if p and global_position.distance_to(p.global_position) < 2.0:
			if p.has_method("take_damage"):
				p.take_damage(base_atk, global_position)
	)
