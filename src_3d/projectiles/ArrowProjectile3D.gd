class_name ArrowProjectile3D
extends Area3D

@export var speed: float = 14.0
@export var damage: float = 12.0
var move_dir: Vector3 = Vector3.RIGHT

func setup(pos: Vector3, dir: Variant, dmg: float = 12.0) -> void:
	global_position = pos
	damage = dmg
	if dir is Vector3:
		move_dir = Vector3(dir.x, dir.y, 0.0).normalized()
	elif dir is float or dir is int:
		move_dir = Vector3(float(dir), 0.0, 0.0).normalized()
		
	var angle_z = atan2(move_dir.y, move_dir.x)
	rotation = Vector3(0, 0, angle_z)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += move_dir * speed * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
