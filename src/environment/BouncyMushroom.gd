class_name BouncyMushroom
extends Area2D

## Búp Nấm Nảy (Bouncy Trampoline Mushroom - detail.md V.2)
## - Khi Player nhảy trúng hoặc đâm bổ nhào từ trên xuống, nảy ngược lên cao (-360.0 velocity)
## - Cho phép tiếp cận bục cao hoặc né vũng axit

@export var bounce_power: float = -380.0

@onready var sprite: Sprite2D = $Sprite2D
var is_bouncing: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player CharacterBody2D
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		bounce_entity(body)

func bounce_entity(player: Player) -> void:
	if is_bouncing:
		return
	is_bouncing = true

	# Bật nảy nhân vật lên cao
	player.velocity.y = bounce_power
	player.can_double_jump = true # Reset lượt double jump khi đạp nấm

	# Hoạt họa nấm co giãn cao su đàn hồi (Squash & Stretch)
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(0.12, 0.04), 0.08) # Co dẹp xuống
		tw.tween_property(sprite, "scale", Vector2(0.06, 0.12), 0.12) # Bật kéo giãn cao
		tw.tween_property(sprite, "scale", Vector2(0.08, 0.08), 0.15) # Về trạng thái chuẩn
		tw.tween_callback(func(): is_bouncing = false)
	else:
		is_bouncing = false
