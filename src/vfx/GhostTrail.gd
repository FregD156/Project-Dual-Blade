class_name GhostTrail
extends Sprite2D

## Hiệu ứng Dư ảnh bóng ma (After-image / Ghost Trail)
## Xuất hiện khi Dash hoặc khi Player kích hoạt Flow Meter (Xuất Quỷ)
## Tạo ảo ảnh bóng mờ neon trôi chậm và mờ dần trong 0.25s

var fade_speed: float = 4.0

func setup(source_sprite: Sprite2D, ghost_color: Color = Color(0.0, 0.9, 1.0, 0.7)) -> void:
	if not source_sprite:
		queue_free()
		return
		
	texture = source_sprite.texture
	hframes = source_sprite.hframes
	vframes = source_sprite.vframes
	frame = source_sprite.frame
	flip_h = source_sprite.flip_h
	flip_v = source_sprite.flip_v
	scale = source_sprite.global_scale
	global_position = source_sprite.global_position
	offset = source_sprite.offset
	modulate = ghost_color
	z_index = source_sprite.z_index - 1

func _process(delta: float) -> void:
	modulate.a -= fade_speed * delta
	if modulate.a <= 0.0:
		queue_free()
