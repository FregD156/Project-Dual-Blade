class_name SpikeTrap3D
extends Area3D

## Bẫy chông gai đá Gothic theo detail.md World 1
## Gây sát thương và hất văng nhẹ khi người chơi giẫm phải

@export var damage: float = 16.0
var cooldown_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

func _on_body_entered(body: Node3D) -> void:
	if cooldown_timer <= 0.0 and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
			cooldown_timer = 0.8
