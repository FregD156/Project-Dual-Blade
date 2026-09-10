class_name VFXManager
extends Node

## VFXManager quản lý spawn hiệu ứng chiến đấu toàn cục:
## - Số sát thương nảy lên (Damage Numbers)
## - Tia lửa vệt chém (Slash Impact Sparks)
## - Vệt máu văng (Blood Splatter)
## - Rung chấn màn hình (Screen Shake)

static func spawn_combat_impact(parent: Node, pos: Vector2, dir: Vector2, dmg: float, is_crit: bool = false, is_player_hit: bool = false) -> void:
	if not parent:
		return
		
	# 1. Spawn Damage Number
	var dmg_num = DamageNumber.new()
	dmg_num.global_position = pos + Vector2(0, -18)
	var num_color = Color(1.0, 0.3, 0.3) if is_player_hit else Color.WHITE
	parent.add_child(dmg_num)
	dmg_num.setup(dmg, is_crit, num_color)
	
	# 2. Spawn Slash Sparks
	var sparks = SlashSparks.new()
	sparks.global_position = pos
	parent.add_child(sparks)
	sparks.setup(dir, is_crit)
	
	# 3. Spawn Blood Splatter
	var blood = BloodSplatter.new()
	blood.global_position = pos
	parent.add_child(blood)
	blood.setup(dir)

static func screen_shake(camera: Camera2D, intensity: float = 4.0, duration: float = 0.15) -> void:
	if not camera:
		return
	var orig_offset = camera.offset
	var tween = camera.create_tween()
	var steps = int(duration / 0.03)
	for i in range(steps):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tween.tween_property(camera, "offset", orig_offset + offset, 0.03)
	tween.tween_property(camera, "offset", orig_offset, 0.03)
