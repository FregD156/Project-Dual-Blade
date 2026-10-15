class_name EnemyAcidSpitter3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Quái Bọ Phun Axit 3D (Acid Spitter — World 2)
## Đứng từ xa hoặc trên các mỏm đá/rễ cây, phun cầu axit độc hình parabol về phía người chơi.

const ACID_GLOB_SCENE = preload("res://scenes_3d/AcidGlobProjectile3D.tscn")

var shoot_cooldown: float = 3.0
var shoot_timer: float = 1.2
var is_aiming: bool = false

@onready var aim_light: OmniLight3D = get_node_or_null("VisualRoot/AimLight")
@onready var sprite: Sprite3D = get_node_or_null("VisualRoot/Sprite3D")

func _ready() -> void:
	enemy_name = "Bọ Phun Axit"
	max_hp = 85.0
	base_atk = 16.0
	move_speed = 1.6
	def = 1.0
	super._ready()
	if aim_light:
		aim_light.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		velocity.x = move_toward(velocity.x, 0.0, 6.0 * delta)
		return

	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1

	shoot_timer -= delta
	if shoot_timer <= 0.7 and not is_aiming:
		is_aiming = true
		if aim_light:
			aim_light.visible = true
		if sprite:
			sprite.modulate = Color(1.5, 2.5, 1.2)

	if shoot_timer <= 0.0:
		_spit_acid()
		shoot_timer = shoot_cooldown
		is_aiming = false
		if aim_light:
			aim_light.visible = false
		if sprite:
			sprite.modulate = Color.WHITE

func _spit_acid() -> void:
	if not ACID_GLOB_SCENE:
		return
	var player = get_player()
	var spawn_pos = global_position + Vector3(facing_direction * 0.6, 0.7, 0.0)
	var shoot_dir = Vector3(float(facing_direction), 0.2, 0.0)
	if player:
		shoot_dir = (player.global_position - spawn_pos).normalized()
		shoot_dir.z = 0.0

	var glob = ACID_GLOB_SCENE.instantiate()
	get_parent().add_child(glob)
	glob.setup(spawn_pos, shoot_dir, base_atk)
