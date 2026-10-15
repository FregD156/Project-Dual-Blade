class_name AcidGlobProjectile3D
extends Area3D

## Cầu Axit Phun Độc 3D: Bay theo quỹ đạo vòng cung, chạm người chơi gây sát thương ăn mòn
@export var speed: float = 11.0
@export var damage: float = 16.0
@export var gravity_effect: float = 8.5
var velocity: Vector3 = Vector3.ZERO

func setup(pos: Vector3, dir: Vector3, dmg: float = 16.0) -> void:
	global_position = pos
	damage = dmg
	velocity = dir.normalized() * speed + Vector3(0.0, 3.5, 0.0)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	velocity.y -= gravity_effect * delta
	global_position += velocity * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		_spawn_splash()
		queue_free()
	elif body is StaticBody3D:
		_spawn_splash()
		queue_free()

func _spawn_splash() -> void:
	var p = CPUParticles3D.new()
	get_parent().add_child(p)
	p.global_position = global_position
	p.amount = 12
	p.lifetime = 0.5
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 120.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.color = Color(0.2, 0.95, 0.3, 0.9)
	var quad = QuadMesh.new()
	quad.size = Vector2(0.08, 0.08)
	p.mesh = quad
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.emitting = true
