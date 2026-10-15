class_name EnemyEliteMutatedTree3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Quái Tinh Anh Ải 2.5 — Cổ Thụ Biến Dị 3D (The Aberrant Mutated Tree)
## Thiết kế theo chuẩn Detail.md Phần A.V, B.2.5 và Phần D:
## - Tổng HP: 1,800 | DEF: 6 (Mitigation 10.7%)
## - Cơ chế: Rễ huyết mộc đâm từ dưới sàn (báo đỏ 0.6s) + Phun phấn độc 360 độ
## - Mercy Drop: Rơi 2 Bình Máu Lớn khi giảm xuống 50% HP

const SoundManager3D = preload("res://src_3d/audio/SoundManager3D.gd")

var attack_timer: float = 2.8
var is_channeling: bool = false
var has_dropped_mercy: bool = false

@onready var sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")
@onready var telegraph_light: OmniLight3D = get_node_or_null("VisualRoot/TelegraphLight")

func _ready() -> void:
	enemy_name = "Thủ Lĩnh Cổ Thụ Biến Dị"
	max_hp = 1800.0
	current_hp = 1800.0
	base_atk = 32.0
	def = 6.0
	move_speed = 1.2
	super._ready()
	if telegraph_light:
		telegraph_light.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return

	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1

	if is_channeling:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		return

	attack_timer -= delta
	if abs(dist_x) > 4.5:
		velocity.x = facing_direction * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		if attack_timer <= 0.0:
			_start_root_spikes(player)

func _start_root_spikes(player: Node3D) -> void:
	is_channeling = true
	attack_timer = 3.2
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_color = Color(1.0, 0.2, 0.2, 1.0)
	if sprite:
		sprite.modulate = Color(2.5, 0.5, 0.5, 1.0)

	var target_x = player.global_position.x
	var target_y = player.global_position.y

	# Vệt cảnh báo đỏ dưới chân người chơi
	var warn_light = OmniLight3D.new()
	get_parent().add_child(warn_light)
	warn_light.global_position = Vector3(target_x, target_y + 0.3, 0.2)
	warn_light.light_color = Color(1.0, 0.15, 0.15, 1.0)
	warn_light.light_energy = 4.0
	warn_light.omni_range = 3.5

	# Sau 0.65s rễ máu đâm lên
	var tw = create_tween()
	tw.tween_interval(0.65)
	tw.tween_callback(func():
		if is_instance_valid(warn_light):
			warn_light.queue_free()
		_erupt_root_spikes(Vector3(target_x, target_y, 0.0))
	)
	tw.tween_interval(0.35)
	tw.tween_callback(func():
		is_channeling = false
		if telegraph_light:
			telegraph_light.visible = false
		if sprite:
			sprite.modulate = Color.WHITE
	)

func _erupt_root_spikes(pos: Vector3) -> void:
	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_slash(4)

	# Gây sát thương nếu người chơi chưa né
	var player = get_player()
	if player and is_instance_valid(player):
		if abs(player.global_position.x - pos.x) < 2.0 and abs(player.global_position.y - pos.y) < 1.8:
			if player.has_method("take_damage"):
				player.take_damage(base_atk, pos)

	# Hiệu ứng rễ gai đâm lên
	var p = CPUParticles3D.new()
	get_parent().add_child(p)
	p.global_position = pos + Vector3(0.0, 0.5, 0.0)
	p.amount = 24
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 45.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 8.0
	p.color = Color(1.8, 0.2, 0.3, 1.0)
	var quad = QuadMesh.new()
	quad.size = Vector2(0.15, 0.35)
	p.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	p.material_override = mat
	p.emitting = true

func take_hit(amount: float, attacker_pos: Vector3, incoming_crit: bool = false) -> void:
	super.take_hit(amount, attacker_pos, incoming_crit)
	if not has_dropped_mercy and current_hp <= (max_hp * 0.5):
		has_dropped_mercy = true
		_drop_mercy_items()

func _drop_mercy_items() -> void:
	if SoundManager3D.get_instance():
		SoundManager3D.get_instance().play_mercy_drop()
	for i in range(2):
		var flask = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(flask)
		flask.global_position = global_position + Vector3(randf_range(-1.5, 1.5), 0.8, 0.0)
		flask.setup(1, 0, "Bình Máu Lớn")
