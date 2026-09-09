class_name World4Mechanics
extends RefCounted

## Module cơ chế riêng của World 4 (Đền Thờ Hư Vô) theo P6.3 Plan
## 1. Crumbling Platform: Bục đá tan biến sau 1 giây khi người chơi đứng lên
## 2. Gravity Zone: Trọng lực đảo ngược hoặc thay đổi cục bộ

static func create_crumbling_platform_timer(platform_node: Node2D, crumble_delay: float = 1.0, respawn_delay: float = 3.0) -> void:
	if not platform_node:
		return
	var tree := platform_node.get_tree()
	if not tree:
		return
		
	# Timer rung lắc và biến mất
	await tree.create_timer(crumble_delay).timeout
	platform_node.visible = false
	platform_node.set_physics_process(false)
	
	# Hồi phục bục đá sau respawn_delay
	await tree.create_timer(respawn_delay).timeout
	platform_node.visible = true
	platform_node.set_physics_process(true)
