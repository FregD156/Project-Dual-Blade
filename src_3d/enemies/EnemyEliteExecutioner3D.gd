class_name EnemyEliteExecutioner3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Quái Tinh Anh 1.5: Thủ Lĩnh Đao Phủ Quỷ theo detail.md V
## - Máu dày (450 HP), giáp kiên cố
## - Đòn bổ búa chấn động mặt sàn không thể đỡ (Unparryable)
## - Hạ gục chắc chắn rớt Trái Tim Huyết Tế & Vũ khí Rank B / A

signal elite_hp_changed(curr: float, max_v: float)

var attack_cooldown: float = 3.6
var attack_timer: float = 2.0
var is_slamming: bool = false
var has_summoned_minions: bool = false

@onready var telegraph_light: OmniLight3D = $VisualRoot/TelegraphLight
@onready var shockwave_mesh: MeshInstance3D = get_node_or_null("VisualRoot/ShockwaveMesh")

func _ready() -> void:
	enemy_name = "Thủ Lĩnh Đao Phủ Quỷ"
	max_hp = 450.0
	current_hp = 450.0
	base_atk = 26.0
	move_speed = 2.2
	super._ready()
	if telegraph_light:
		telegraph_light.visible = false
	if shockwave_mesh:
		shockwave_mesh.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return
		
	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1
	
	# Gọi viện binh khi tụt dưới 60% máu
	if not has_summoned_minions and current_hp < (max_hp * 0.6):
		_summon_minions()
		
	if is_slamming:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		return
		
	attack_timer -= delta
	
	if abs(dist_x) > 2.6:
		velocity.x = facing_direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		if attack_timer <= 0.0:
			_start_heavy_slam()

func _start_heavy_slam() -> void:
	is_slamming = true
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_energy = 8.0
		telegraph_light.light_color = Color(1.0, 0.05, 0.05)
		
	# Báo hiệu đòn nặng 0.9s (Unparryable - bắt buộc Shadow Dash né)
	var tw = create_tween()
	tw.tween_interval(0.9)
	tw.tween_callback(_execute_shockwave_slam)
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		is_slamming = false
		attack_timer = attack_cooldown
	)

func _execute_shockwave_slam() -> void:
	if telegraph_light:
		telegraph_light.visible = false
		
	# Rung màn hình chấn động
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(0.35, 6.0)
		
	# Hiệu ứng sóng chấn động mặt sàn
	if shockwave_mesh:
		shockwave_mesh.visible = true
		shockwave_mesh.scale = Vector3(1.0, 1.0, 1.0)
		var sw_tw = create_tween()
		sw_tw.tween_property(shockwave_mesh, "scale", Vector3(3.5, 0.5, 3.5), 0.3)
		sw_tw.parallel().tween_property(shockwave_mesh, "modulate:a" if "modulate" in shockwave_mesh else "scale", Vector3(4.0, 0.1, 4.0), 0.3)
		sw_tw.chain().tween_callback(func(): shockwave_mesh.visible = false)
		
	# Gây sát thương diện rộng dọc mặt sàn
	var player = get_player()
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 4.2:
			# Đòn chấn động không thể parry (Unparryable)
			if player.has_method("take_damage"):
				player.take_damage(base_atk, global_position)

func _summon_minions() -> void:
	has_summoned_minions = true
	var hound_scene = load("res://scenes_3d/EnemyChainHound3D.tscn")
	if hound_scene and get_parent():
		var h1 = hound_scene.instantiate()
		get_parent().add_child(h1)
		h1.global_position = global_position + Vector3(-3.0, 0.5, 0.0)
		
		var h2 = hound_scene.instantiate()
		get_parent().add_child(h2)
		h2.global_position = global_position + Vector3(3.0, 0.5, 0.0)
		
		# Đăng ký với StageManager nếu có
		var sm = get_parent()
		if sm and sm.has_method("register_enemy"):
			sm.register_enemy(h1)
			sm.register_enemy(h2)

func _spawn_loot() -> void:
	if not DROP_ITEM_SCENE or not get_parent():
		return
		
	# 100% Rớt Trái Tim Huyết Tế (Heart Core) theo detail.md VII.1
	var heart = DROP_ITEM_SCENE.instantiate()
	get_parent().add_child(heart)
	heart.global_position = global_position + Vector3(0, 0.6, 0)
	heart.setup(2, 0, "Trái Tim Huyết Tế")
	
	# Chắc chắn rớt vũ khí Rank B hoặc A
	var weapon = DROP_ITEM_SCENE.instantiate()
	get_parent().add_child(weapon)
	weapon.global_position = global_position + Vector3(1.5, 0.6, 0)
	var is_rank_a = (randf() < 0.4)
	var r = 3 if is_rank_a else 2 # A (3) hoặc B (2)
	var w_name = "Song Đao Thép Tinh Chế" if is_rank_a else "Song Đao Thợ Rèn"
	weapon.setup(3, r, w_name)
