class_name EnemySporeShambler3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Quái Bào Tử Nhảy 3D (Toxic Spore Shambler — World 2)
## Di chuyển chậm chạp, khi tiếp cận mục tiêu sẽ tích tụ độc tố phồng to và nổ phát tán bào tử độc.

var explode_timer: float = 0.0
var is_priming: bool = false
const PRIME_DURATION: float = 0.75
const EXPLOSION_RADIUS: float = 3.2
const EXPLOSION_DAMAGE: float = 24.0

@onready var telegraph_light: OmniLight3D = get_node_or_null("VisualRoot/TelegraphLight")
@onready var sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")

func _ready() -> void:
	enemy_name = "Bào Tử Nhảy"
	max_hp = 135.0
	base_atk = 16.0
	move_speed = 2.4
	def = 2.0
	super._ready()
	if telegraph_light:
		telegraph_light.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return

	var dist_x = player.global_position.x - global_position.x
	var dist_y = abs(player.global_position.y - global_position.y)
	facing_direction = 1 if dist_x > 0 else -1

	if is_priming:
		explode_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		# Hiệu ứng phồng to nhấp nháy
		if sprite:
			var pulse = 1.0 + (sin((PRIME_DURATION - explode_timer) * 18.0) * 0.25)
			sprite.scale = Vector3(pulse, pulse, pulse)
		if explode_timer <= 0.0:
			_detonate_spores()
		return

	# Nếu cách tầng quá xa, chờ
	if dist_y > 2.2:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return

	if abs(dist_x) > 2.0:
		velocity.x = facing_direction * move_speed
	else:
		_start_spore_priming()

func _start_spore_priming() -> void:
	is_priming = true
	explode_timer = PRIME_DURATION
	if telegraph_light:
		telegraph_light.visible = true
		telegraph_light.light_color = Color(0.3, 0.95, 0.35, 1.0)
	if sprite:
		sprite.modulate = Color(1.8, 2.5, 1.2, 1.0)

func _detonate_spores() -> void:
	is_priming = false
	if telegraph_light:
		telegraph_light.visible = false

	# Gây sát thương nổ độc cho người chơi nếu đứng trong bán kính
	var player = get_player()
	if player and is_instance_valid(player):
		var d = global_position.distance_to(player.global_position)
		if d <= EXPLOSION_RADIUS:
			if player.has_method("take_damage"):
				player.take_damage(EXPLOSION_DAMAGE, global_position)

	# Hiệu ứng nổ bào tử xanh lá
	var p = CPUParticles3D.new()
	get_parent().add_child(p)
	p.global_position = global_position + Vector3(0.0, 0.8, 0.0)
	p.amount = 32
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.5
	p.color = Color(0.25, 0.95, 0.35, 0.9)
	
	var quad = QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	p.mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	p.emitting = true

	# Tự hủy sau khi phát nổ
	die("spore_detonation")
