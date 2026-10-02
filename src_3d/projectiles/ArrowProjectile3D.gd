class_name ArrowProjectile3D
extends Area3D

@export var speed: float = 14.0
@export var damage: float = 12.0
var direction_x: float = 1.0

func setup(pos: Vector3, dir_x: float, dmg: float = 12.0) -> void:
	global_position = pos
	direction_x = dir_x
	damage = dmg
	rotation.y = deg_to_rad(90.0 if dir_x > 0 else -90.0)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position.x += direction_x * speed * delta
	global_position.z = 0.0

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
	elif body is StaticBody3D:
		queue_free()
