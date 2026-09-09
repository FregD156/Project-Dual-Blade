class_name ScreenShake
extends RefCounted

## Polish VFX: Rung màn hình khi Parry hoặc tung đòn Crit (P7 Polish)
static func shake(camera: Camera2D, intensity: float = 8.0, duration: float = 0.15) -> void:
	if not camera:
		return
	var tree := camera.get_tree()
	if not tree:
		return
		
	var orig_offset := camera.offset
	var elapsed := 0.0
	while elapsed < duration:
		var factor := 1.0 - (elapsed / duration)
		camera.offset = orig_offset + Vector2(
			randf_range(-intensity, intensity) * factor,
			randf_range(-intensity, intensity) * factor
		)
		await tree.process_frame
		elapsed += tree.root.get_process_delta_time()
		
	camera.offset = orig_offset
