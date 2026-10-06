class_name BouncyMushroom3D
extends Area3D

## Nấm nảy bào tử 3D (Bouncy Spore Shroom 3D)
## Đẩy Player vọt lên cao khi giẫm vào, cho phép tiếp cận các tầng cao (Tier 2/3)

@export var bounce_velocity: float = 16.5
@onready var sprite: Sprite3D = $Sprite3D
var is_bouncing: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player CharacterBody3D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		bounce_entity(body)

func bounce_entity(player: Node3D) -> void:
	if is_bouncing:
		return
	is_bouncing = true

	# Bật nảy người chơi lên cao
	if "velocity" in player:
		player.velocity.y = bounce_velocity
	if "can_double_jump" in player:
		player.can_double_jump = true

	# Hoạt họa Squash & Stretch đàn hồi cao su cho Sprite3D
	if sprite:
		var orig_scale: Vector3 = sprite.scale
		var tw: Tween = create_tween()
		tw.tween_property(sprite, "scale", Vector3(orig_scale.x * 1.25, orig_scale.y * 0.55, orig_scale.z), 0.08)
		tw.tween_property(sprite, "scale", Vector3(orig_scale.x * 0.85, orig_scale.y * 1.35, orig_scale.z), 0.12)
		tw.tween_property(sprite, "scale", orig_scale, 0.15)
		tw.tween_callback(func(): is_bouncing = false)
	else:
		is_bouncing = false
