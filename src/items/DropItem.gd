class_name DropItem
extends Area2D

## DropItem đại diện cho vật phẩm rơi rớt dọc đường theo detail.md
## - Rơi tiếp đất chuẩn xác (Ground Snap tại y=192 hoặc trên platform)
## - Hiệu ứng bay bổng nhấp nhô (Float Bobbing) và tia sáng phẩm cấp
## - Hạt Sinh Mệnh (life_shard) & Tinh thể (upgrade_crystal) tự động hút khi lại gần
## - Vũ Khí (tier_d -> tier_ssr), Bình Máu (life_flask), Trái Tim (heart_core)

@export var item_type: String = "life_shard"

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

var velocity: Vector2 = Vector2.ZERO
var target_player: Player = null
var is_collected: bool = false
var is_grounded: bool = false
var ground_y: float = 192.0
var base_ground_pos_y: float = 192.0
var bob_timer: float = 0.0

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
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png"),
	"armor_helmet": preload("res://assets/sprites/armor/armor_helmet.png"),
	"armor_chest": preload("res://assets/sprites/armor/armor_chest.png"),
	"armor_arms": preload("res://assets/sprites/armor/armor_arms.png"),
	"armor_legs": preload("res://assets/sprites/armor/armor_legs.png")
}

const TIER_GLOW_COLORS = {
	"tier_d": Color(0.7, 0.7, 0.7),
	"tier_c": Color(1.0, 1.0, 1.0),
	"tier_b": Color(0.2, 1.0, 0.3),
	"tier_a": Color(0.2, 0.6, 1.0),
	"tier_r": Color(0.8, 0.3, 1.0),
	"tier_sr": Color(1.0, 0.85, 0.2),
	"tier_ssr": Color(1.0, 0.3, 0.8),
	"life_shard": Color(0.3, 1.0, 0.5),
	"life_flask": Color(1.0, 0.3, 0.3),
	"heart_core": Color(1.0, 0.1, 0.2),
	"upgrade_crystal": Color(0.7, 0.4, 1.0)
}

func _ready() -> void:
	collision_layer = 128
	collision_mask = 2 # Detect player
	body_entered.connect(_on_body_entered)
	
	if TEXTURES.has(item_type) and sprite:
		sprite.texture = TEXTURES[item_type]
	elif item_type.begins_with("armor_") and sprite:
		for key in ["armor_helmet", "armor_chest", "armor_arms", "armor_legs"]:
			if item_type.begins_with(key):
				sprite.texture = TEXTURES[key]
				break
		
	# Nảy văng lên ngẫu nhiên khi rớt ra từ quái
	velocity = Vector2(randf_range(-45, 45), randf_range(-90, -60))
	base_ground_pos_y = 192.0 # Mặt sàn chính chuẩn của map

func _physics_process(delta: float) -> void:
	if is_collected:
		return

	if not is_grounded:
		# Rơi tự do xuống sàn
		velocity.y += 350.0 * delta
		velocity.x = move_toward(velocity.x, 0.0, 80.0 * delta)
		position += velocity * delta
		
		# Chạm đất (ở độ cao sàn 192 hoặc trên bục platform)
		if position.y >= base_ground_pos_y:
			position.y = base_ground_pos_y
			is_grounded = true
			velocity = Vector2.ZERO
	else:
		# Khi đã tiếp đất: Nhấp nhô nhẹ nhàng bồng bềnh 2-3px để người chơi dễ thấy
		bob_timer += delta * 3.5
		if sprite:
			sprite.position.y = sin(bob_timer) * 2.5

	# Nam châm hút Hạt sinh mệnh và Tinh thể khi người chơi tiến lại gần 65px
	if item_type == "life_shard" or item_type == "upgrade_crystal":
		if not target_player or not is_instance_valid(target_player):
			var tree = get_tree()
			if tree:
				var players = tree.get_nodes_in_group("player")
				if players.size() > 0:
					target_player = players[0]
		
		if target_player:
			var dist = global_position.distance_to(target_player.global_position)
			if dist < 65.0:
				var dir = (target_player.global_position - global_position).normalized()
				global_position += dir * 200.0 * delta

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body is Player:
		is_collected = true
		_apply_pickup(body)
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "position:y", position.y - 16.0, 0.16)
		tween.tween_property(self, "modulate:a", 0.0, 0.16)
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
				var opts = WeaponOptionGenerator.generate_options(item_type)
				var item_data = {
					"type": "weapon",
					"tier": item_type,
					"name": "Song Đao " + item_type.replace("tier_", "").to_upper(),
					"options": opts,
					"time": Time.get_ticks_msec()
				}
				if player.has_method("add_to_inventory"):
					player.add_to_inventory(item_data)
				if player.has_method("equip_weapon_dict"):
					player.equip_weapon_dict(item_data)
				elif player.has_method("equip_weapon_tier"):
					player.equip_weapon_tier(item_type)
			elif item_type.begins_with("armor_"):
				# Format: "armor_<part>_<tier>" (vd: "armor_helmet_tier_b")
				var tokens = item_type.replace("armor_", "").split("_")
				if tokens.size() >= 2:
					var part = tokens[0]
					var tier = "tier_" + tokens[tokens.size() - 1]
					var armor_item = ArmorSystem.create_armor_item(part, tier)
					if player.has_method("add_to_inventory"):
						player.add_to_inventory(armor_item)
					if player.has_method("equip_armor_piece"):
						# Tự động trang bị nếu phẩm cấp tốt hơn hoặc chưa có
						player.equip_armor_piece(armor_item)
