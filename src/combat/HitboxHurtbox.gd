class_name Hitbox
extends Area2D

## Hitbox đại diện cho vùng gây sát thương
@export var damage: float = 10.0
@export var skill_mult: float = 1.0
@export var is_crit: bool = false
@export var is_unparryable: bool = false # Đòn báo đỏ, không thể parry (Thủ Lĩnh Đao Phủ)
@export var knockback_force: Vector2 = Vector2.ZERO

signal hit_landed(target_hurtbox: Area2D)

func _ready() -> void:
	monitoring = true
	monitorable = true
