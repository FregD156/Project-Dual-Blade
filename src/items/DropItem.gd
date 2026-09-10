class_name DropItem
extends Area2D

## DropItem đại diện cho vật phẩm rơi rớt dọc đường theo detail.md
## - Hạt Sinh Mệnh Nhỏ (life_shard): tự động hút trong 2m (40px), hồi 8% HP
## - Bình Máu Lớn (life_flask): tăng số bình máu dự trữ, bấm Q để dùng
## - Trái Tim Huyết Tế (heart_core): hồi 50% HP + buff 10% ATK trong 20s
## - Tinh Thể Nâng Cấp (upgrade_crystal): nguyên liệu rèn / tẩy dòng
## - Vũ Khí (tier_d -> tier_ssr): trang bị song đao mới

@export var item_type: String = "life_shard"

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var velocity: Vector2 = Vector2.ZERO
var target_player: Player = null
var is_collected: bool = false

const TEXTURES = {
	"life_shard": preload("res://assets/sprites/items/sliced/life_shard.png"),
	"life_flask": preload("res://assets/sprites/items/sliced/life_flask.png"),
	"heart_core": preload("res://assets/sprites/items/sliced/heart_core.png"),
	"upgrade_crystal": preload("res://assets/sprites/items/sliced/upgrade_crystal.png"),
	"echo_shard": preload("res://assets/sprites/items/sliced/echo_shard.png"),
	"tier_d": preload("res://assets/sprites/items/sliced/weapon_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/sliced/weapon_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/sliced/weapon_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/sliced/weapon_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/sliced/weapon_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/sliced/weapon_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")
}

func _ready() -> void:
	collision_layer = 128
	collision_mask = 2 # Detect player
	body_entered.connect(_on_body_entered)
	
	if TEXTURES.has(item_type) and sprite:
		sprite.texture = TEXTURES[item_type]
		
	# Spawn pop upwards
	velocity = Vector2(randf_range(-30, 30), -80)

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	# Fall to ground with simple gravity
	if velocity.y < 120.0:
		velocity.y += 200.0 * delta
	velocity.x = move_toward(velocity.x, 0.0, 100.0 * delta)
	position += velocity * delta

	# Life Shard magnet effect within 60px
	if item_type == "life_shard" or item_type == "upgrade_crystal":
		if not target_player or not is_instance_valid(target_player):
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				target_player = players[0]
		
		if target_player:
			var dist = global_position.distance_to(target_player.global_position)
			if dist < 65.0:
				var dir = (target_player.global_position - global_position).normalized()
				global_position += dir * 180.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is Player:
		is_collected = true
		_apply_pickup(body)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 15.0, 0.15)
		tween.tween_property(self, "modulate:a", 0.0, 0.15)
		tween.chain().tween_callback(queue_free)

func _apply_pickup(player: Player) -> void:
	match item_type:
		"life_shard":
			var heal = player.max_hp * 0.08
			player.current_hp = min(player.max_hp, player.current_hp + heal)
			player.emit_signal("hp_changed", player.current_hp, player.max_hp)
		"life_flask":
			if player.has_method("add_flask"):
				player.add_flask(1)
		"heart_core":
			player.current_hp = min(player.max_hp, player.current_hp + player.max_hp * 0.5)
			player.emit_signal("hp_changed", player.current_hp, player.max_hp)
		"upgrade_crystal":
			if player.has_method("add_crystals"):
				player.add_crystals(1)
		_:
			if item_type.begins_with("tier_"):
				if player.has_method("equip_weapon_tier"):
					player.equip_weapon_tier(item_type)
