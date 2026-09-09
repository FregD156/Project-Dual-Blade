class_name PushArea
extends Area2D

## Cơ chế Soft Body Separation: Đẩy nhẹ các thực thể khi đứng chồng lên nhau
@export var push_force: float = 80.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(other_area: Area2D) -> void:
	pass

func get_push_vector() -> Vector2:
	var push_dir := Vector2.ZERO
	var overlapping := get_overlapping_areas()
	for area in overlapping:
		if area is PushArea and area != self:
			var diff := global_position - area.global_position
			if diff.length_squared() > 0.001:
				push_dir += diff.normalized()
			else:
				push_dir += Vector2(1.0 if randf() > 0.5 else -1.0, 0.0)
	return push_dir * push_force
