class_name HitStopManager
extends Node

## Hệ thống Freeze Frame / Hit-Stop toàn cục
## Làm chậm hoặc đóng băng thời gian trong khoảnh khắc ngắn (0.05s - 0.08s) 
## để tạo cảm giác chém trúng đanh thép và uy lực.

static func freeze(tree: SceneTree, duration: float = 0.06, time_scale: float = 0.05) -> void:
	if not tree:
		return
	Engine.time_scale = time_scale
	await tree.create_timer(duration * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0
