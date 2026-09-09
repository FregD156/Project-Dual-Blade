class_name Hurtbox
extends Area2D

## Hurtbox đại diện cho vùng nhận sát thương
@export var is_invincible: bool = false # i-frame khi dash hoặc blade dance

signal hit_received(hitbox: Hitbox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(other_area: Area2D) -> void:
	if is_invincible:
		return
	if other_area is Hitbox:
		hit_received.emit(other_area)
		other_area.hit_landed.emit(self)
