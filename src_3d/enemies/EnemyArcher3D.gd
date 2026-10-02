class_name EnemyArcher3D
extends "res://src_3d/enemies/EnemyBase3D.gd"

## Cung Thủ Tháp Canh 3D: Đứng trên bục bắn tên theo đường thẳng

const ARROW_SCENE = preload("res://scenes_3d/ArrowProjectile3D.tscn")

var shoot_cooldown: float = 3.2
var shoot_timer: float = 1.5
var is_aiming: bool = false

@onready var aim_light: OmniLight3D = $VisualRoot/AimLight

func _ready() -> void:
	max_hp = 70.0
	base_atk = 12.0
	move_speed = 0.0 # Thường đứng yên trên bục canh
	super._ready()
	if aim_light:
		aim_light.visible = false

func _process_enemy_behavior(delta: float) -> void:
	var player = get_player()
	if not player:
		return
		
	var dist_x = player.global_position.x - global_position.x
	facing_direction = 1 if dist_x > 0 else -1
	
	shoot_timer -= delta
	var sp = visual_root.get_node_or_null("Sprite3D") if visual_root else null
	if shoot_timer <= 0.8 and not is_aiming:
		is_aiming = true
		if sp: sp.frame = 2 # Rút cung ngắm bắn
		if aim_light:
			aim_light.visible = true
			
	if shoot_timer <= 0.0:
		if sp: sp.frame = 3 # Thả dây bắn tên
		_shoot_arrow()
		shoot_timer = shoot_cooldown
		is_aiming = false
		if aim_light:
			aim_light.visible = false
		var tw = create_tween()
		tw.tween_interval(0.2)
		tw.tween_callback(func():
			if sp and not is_aiming: sp.frame = 0
		)

func _shoot_arrow() -> void:
	if not ARROW_SCENE:
		return
	var player = get_player()
	var spawn_pos = global_position + Vector3(facing_direction * 0.7, 0.8, 0.0)
	var shoot_dir = Vector3(float(facing_direction), 0.0, 0.0)
	if player:
		shoot_dir = (player.global_position + Vector3(0, 0.8, 0) - spawn_pos).normalized()
		shoot_dir.z = 0.0
		
	var arrow = ARROW_SCENE.instantiate()
	get_parent().add_child(arrow)
	arrow.setup(spawn_pos, shoot_dir, base_atk)
