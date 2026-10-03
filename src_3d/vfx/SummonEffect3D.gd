class_name SummonEffect3D
extends Node3D

## Hiệu ứng vòng tròn ma pháp triệu hồi & cột sáng thiên giới khi người chơi xuất hiện
## Thiết kế theo chuẩn Gothic Dark Fantasy:
## - Vòng tròn ma pháp runes xoay tròn trên mặt đất
## - Cột sáng linh năng bừng sáng từ trên trời rót xuống
## - Vầng hào quang ánh sáng (OmniLight3D) bùng nổ rồi lắng dịu
## - Tự động fade-out và giải phóng sau khi người chơi đã giáng trần hoàn tất

@onready var circle_sprite: Sprite3D = $CircleSprite
@onready var beam_sprite: Sprite3D = $BeamSprite
@onready var summon_light: OmniLight3D = $SummonLight

var elapsed: float = 0.0
const DURATION: float = 1.6

func _ready() -> void:
	if circle_sprite:
		circle_sprite.scale = Vector3(0.1, 0.1, 0.1)
		circle_sprite.modulate.a = 0.0
	if beam_sprite:
		beam_sprite.scale = Vector3(0.2, 0.05, 0.2)
		beam_sprite.modulate.a = 0.0
	if summon_light:
		summon_light.light_energy = 0.0

func _process(delta: float) -> void:
	elapsed += delta
	var progress = clamp(elapsed / DURATION, 0.0, 1.0)
	
	# Xoay vòng ma pháp rune
	if circle_sprite:
		circle_sprite.rotation.y += delta * 1.8
		if progress < 0.25:
			# Khai mở vòng ma thuật
			var t = progress / 0.25
			var s = lerp(0.1, 2.2, t)
			circle_sprite.scale = Vector3(s, s, s)
			circle_sprite.modulate.a = lerp(0.0, 1.0, t)
		elif progress < 0.75:
			circle_sprite.scale = Vector3(2.2, 2.2, 2.2)
			circle_sprite.modulate.a = 1.0
		else:
			# Dần dần mờ đi
			var t = (progress - 0.75) / 0.25
			circle_sprite.modulate.a = lerp(1.0, 0.0, t)
			circle_sprite.scale = Vector3(2.2 + t * 0.4, 2.2 + t * 0.4, 2.2 + t * 0.4)

	# Bùng nổ cột sáng triệu hồi
	if beam_sprite:
		if progress < 0.2:
			beam_sprite.modulate.a = 0.0
		elif progress < 0.45:
			var t = (progress - 0.2) / 0.25
			beam_sprite.scale = Vector3(lerp(0.3, 2.0, t), lerp(0.1, 2.8, t), 1.0)
			beam_sprite.modulate.a = lerp(0.0, 1.0, t)
		elif progress < 0.8:
			var t = (progress - 0.45) / 0.35
			beam_sprite.scale = Vector3(lerp(2.0, 1.6, t), 2.8, 1.0)
			beam_sprite.modulate.a = 1.0
		else:
			var t = (progress - 0.8) / 0.2
			beam_sprite.modulate.a = lerp(1.0, 0.0, t)
			beam_sprite.scale = Vector3(lerp(1.6, 0.1, t), 2.8, 1.0)

	# Ánh sáng tỏa ra
	if summon_light:
		if progress < 0.4:
			summon_light.light_energy = lerp(0.0, 6.0, progress / 0.4)
		else:
			summon_light.light_energy = lerp(6.0, 0.0, (progress - 0.4) / 0.6)

	if elapsed >= DURATION:
		queue_free()
