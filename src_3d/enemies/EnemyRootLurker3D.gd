class_name EnemyRootLurker3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Quái Ấu Trùng Rễ Máu 3D (Crimson Spider Crawler / Root Lurker — World 2)
## Di chuyển cực nhanh, bò sát mặt đất và thực hiện các cú phóng vồ (Pounce) chớp nhoáng.

var pounce_cooldown: float = 2.2
var pounce_timer: float = 0.5
var is_pouncing: bool = false

@onready var sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")

func _ready() -> void:
	enemy_name = "Ấu Trùng Rễ Máu"
	max_hp = 80.0
	base_atk = 14.0
	move_speed = 6.8
	def = 1.0
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
	var dist_y = abs(player.global_position.y - global_position.y)
	if dist_y > 1.8:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		return

	if abs(dist_x) > 3.5:
		velocity.x = facing_direction * move_speed
	else:
		if pounce_timer <= 0.0:
			_execute_pounce(player)

func _execute_pounce(_player: Node3D) -> void:
	is_pouncing = true
	pounce_timer = pounce_cooldown
	velocity.x = facing_direction * 10.5
	velocity.y = 7.5

	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.15)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.3)

	var attack_tw = create_tween()
	attack_tw.tween_interval(0.25)
	attack_tw.tween_callback(func():
		var p = get_player()
		if p and is_instance_valid(p) and global_position.distance_to(p.global_position) < 2.2:
			if p.has_method("take_damage"):
				p.take_damage(base_atk, global_position)
	)
