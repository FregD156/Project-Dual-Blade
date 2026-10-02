class_name GhostTrail3D
extends Node3D

## Dư ảnh bóng ma 3D (After-image) theo detail.md II.1
## Tự động nhân bản mesh của nhân vật, mờ dần theo thời gian với hiệu ứng dạ quang

@export var ghost_color: Color = Color(0.2, 0.6, 1.0, 0.7)
@export var fade_duration: float = 0.35

func setup(source_node: Node3D, tint: Color = Color(0.2, 0.6, 1.0, 0.7), duration: float = 0.35) -> void:
	ghost_color = tint
	fade_duration = duration
	global_transform = source_node.global_transform
	
	# Duyệt qua các MeshInstance3D con và sao chép mesh
	for child in source_node.find_children("*", "MeshInstance3D"):
		if child is MeshInstance3D and child.visible and child.mesh:
			var ghost_mesh = MeshInstance3D.new()
			ghost_mesh.mesh = child.mesh
			ghost_mesh.transform = child.global_transform * source_node.global_transform.affine_inverse()
			
			var mat = StandardMaterial3D.new()
			mat.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color = ghost_color
			ghost_mesh.material_override = mat
			add_child(ghost_mesh)
			
	var tween = create_tween()
	tween.tween_method(func(alpha: float):
		for m in get_children():
			if m is MeshInstance3D and m.material_override:
				var c = ghost_color
				c.a = alpha * ghost_color.a
				m.material_override.albedo_color = c
	, 1.0, 0.0, fade_duration)
	tween.tween_callback(queue_free)
