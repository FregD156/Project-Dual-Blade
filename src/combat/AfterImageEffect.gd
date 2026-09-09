class_name AfterImageEffect
extends RefCounted

## Polish VFX: Dư ảnh bóng ma (After-image) khi Full Flow (5 nấc) hoặc Shadow Dash
static func spawn_after_image(node: Node2D, texture: Texture2D, flip_h: bool) -> void:
	if not node or not node.get_parent():
		return
		
	var ghost := Sprite2D.new()
	ghost.texture = texture
	ghost.scale = node.scale
	ghost.global_position = node.global_position
	ghost.flip_h = flip_h
	ghost.modulate = Color(0.2, 0.7, 1.0, 0.6) # Xanh băng hư ảnh
	
	node.get_parent().add_child(ghost)
	
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)
