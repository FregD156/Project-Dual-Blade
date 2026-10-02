class_name EnemyBase3D
extends CharacterBody3D

## Lớp cơ sở cho Quái Vật 3D trong Project Dual Blade (Khóa trục Z)
## Quản lý máu, giáp, hiệu ứng trúng đòn, knockback và rơi đồ

signal enemy_died(enemy: EnemyBase3D)
signal hp_changed(curr: float, max_v: float)

const DamageNumber3D = preload("res://src_3d/vfx/DamageNumber3D.gd")

@export_group("Stats")
@export var enemy_name: String = "Quái Vật"
@export var max_hp: float = 120.0
var current_hp: float = 120.0
@export var base_atk: float = 15.0
@export var move_speed: float = 3.2
@export var gravity: float = 28.0

var facing_direction: int = -1 # -1 = trái, 1 = phải
var is_dead: bool = false
var flash_timer: float = 0.0

@onready var visual_root: Node3D = $VisualRoot

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	
	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return
		
	_process_enemy_behavior(delta)
	
	_apply_gravity(delta)
	move_and_slide()
	
	velocity.z = 0.0
	global_position.z = 0.0
	_update_visual_facing()
	
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			_reset_flash()

func _process_enemy_behavior(_delta: float) -> void:
	# Ghi đè ở các lớp con
	pass

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0

func _update_visual_facing() -> void:
	if visual_root:
		var target_rot_y = deg_to_rad(90.0 if facing_direction > 0 else -90.0)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, 0.25)

func get_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		return players[0]
	return null

func take_hit(amount: float, attacker_pos: Vector3) -> void:
	if is_dead:
		return
		
	current_hp = max(0.0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	
	flash_timer = 0.12
	_flash_white()
	
	# Đẩy lùi theo trục X
	var dir_x = sign(global_position.x - attacker_pos.x)
	if dir_x == 0: dir_x = 1
	velocity.x = dir_x * 4.2
	velocity.y = 2.0
	
	# Hiện số sát thương 3D
	if get_parent():
		var num = DamageNumber3D.new()
		get_parent().add_child(num)
		var is_crit = (randf() < 0.2)
		var dmg = amount * (1.5 if is_crit else 1.0)
		num.setup(dmg, global_position + Vector3(0, 1.4, 0), is_crit, false)
		
	if current_hp <= 0.0:
		die()

func _flash_white() -> void:
	for m in find_children("*", "MeshInstance3D"):
		if m is MeshInstance3D and m.material_override:
			if m.material_override is ShaderMaterial:
				m.material_override.set_shader_parameter("emission_color", Color(1.5, 0.4, 0.4))
				m.material_override.set_shader_parameter("emission_energy", 3.0)

func _reset_flash() -> void:
	for m in find_children("*", "MeshInstance3D"):
		if m is MeshInstance3D and m.material_override:
			if m.material_override is ShaderMaterial:
				m.material_override.set_shader_parameter("emission_energy", 0.0)

const DROP_ITEM_SCENE = preload("res://scenes_3d/DropItem3D.tscn")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	enemy_died.emit(self)
	_spawn_loot()
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.0, 0.0, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _spawn_loot() -> void:
	if not DROP_ITEM_SCENE or not get_parent():
		return
	var player = get_player()
	var player_low_hp = false
	if player and "current_hp" in player and "max_hp" in player:
		player_low_hp = (player.current_hp / player.max_hp) < 0.35
		
	var roll = randf()
	if roll < (0.60 if player_low_hp else 0.35):
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(0, 0.4, 0)
		item.setup(0, 0, "Hạt Sinh Mệnh")
	elif roll < 0.55:
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(0, 0.4, 0)
		var r = 1 if randf() < 0.3 else 0
		var w_name = "Song Đao Thép Thô" if r == 1 else "Song Đao Rỉ Sét"
		item.setup(3, r, w_name)
