class_name DummyEnemy3D
extends CharacterBody3D

signal enemy_died()

@export var max_hp: float = 200.0
var current_hp: float = 200.0
@export var is_passive_dummy: bool = false

var gravity: float = 28.0
var flash_timer: float = 0.0
var attack_timer: float = 2.5
var is_telegraphing: bool = false

@onready var visual_mesh: MeshInstance3D = $VisualMesh
@onready var telegraph_light: OmniLight3D = get_node_or_null("TelegraphLight")
@onready var hurt_area: Area3D = get_node_or_null("HurtArea")

func _ready() -> void:
	current_hp = max_hp
	if telegraph_light:
		telegraph_light.visible = false

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
		
	velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
	move_and_slide()
	global_position.z = 0.0
	
	# Attack cycle for testing parry
	if not is_passive_dummy:
		_process_attack_pattern(delta)
		
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			_reset_material_color()

func _process_attack_pattern(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0.8 and not is_telegraphing:
		# Báo hiệu vệt đỏ 0.8s trước khi vung đòn (như trong detail.md)
		is_telegraphing = true
		if telegraph_light:
			telegraph_light.visible = true
			telegraph_light.light_color = Color(1.0, 0.1, 0.1)
			
	if attack_timer <= 0.0:
		_execute_attack()
		attack_timer = randf_range(2.8, 3.8)
		is_telegraphing = false
		if telegraph_light:
			telegraph_light.visible = false

func _execute_attack() -> void:
	# Đòn chém vào người chơi ở cự ly gần
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Node3D and is_instance_valid(p):
			var dist = global_position.distance_to(p.global_position)
			if dist < 2.2:
				if p.has_method("take_damage"):
					p.take_damage(18.0, global_position)

func take_hit(amount: float, attacker_pos: Vector3) -> void:
	current_hp -= amount
	flash_timer = 0.12
	_flash_material(Color(1.5, 0.3, 0.3))
	
	# Đẩy lùi (Knockback)
	var dir_x = sign(global_position.x - attacker_pos.x)
	if dir_x == 0: dir_x = 1
	velocity.x = dir_x * 4.5
	velocity.y = 2.0
	
	if current_hp <= 0.0:
		_die()

func _flash_material(col: Color) -> void:
	if visual_mesh:
		var mat = visual_mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("emission_color", col)
			mat.set_shader_parameter("emission_energy", 3.0)

func _reset_material_color() -> void:
	if visual_mesh:
		var mat = visual_mesh.get_active_material(0)
		if mat and mat is ShaderMaterial:
			mat.set_shader_parameter("emission_energy", 0.0)

func _die() -> void:
	enemy_died.emit()
	queue_free()
