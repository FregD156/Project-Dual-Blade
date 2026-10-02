class_name DropItem3D
extends Area3D

## Vật Phẩm Rơi 3D theo detail.md III.1 & VII.1
## Hỗ trợ: Hạt Sinh Mệnh (hút nam châm), Bình Máu Lớn, Trái Tim Huyết Tế và Vũ Khí D->SSR có tia sáng

enum ItemType { LIFE_SHARD, LIFE_FLASK, HEART_CORE, WEAPON }
enum Rarity { D, C, B, A, R, SR, SSR }

@export var item_type: ItemType = ItemType.LIFE_SHARD
@export var rarity: Rarity = Rarity.D
@export var item_name: String = "Hạt Sinh Mệnh"

var is_collected: bool = false
var float_offset: float = 0.0
var base_y: float = 0.0
var magnet_speed: float = 0.0

const TEX_LIFE_SHARD = preload("res://assets/sprites/items/sliced/life_shard.png")
const TEX_LIFE_FLASK = preload("res://assets/sprites/items/sliced/life_flask.png")
const TEX_HEART_CORE = preload("res://assets/sprites/items/sliced/heart_core.png")
const TEX_WEAPON_D = preload("res://assets/sprites/items/sliced/weapon_tier_d.png")
const TEX_WEAPON_C = preload("res://assets/sprites/items/sliced/weapon_tier_c.png")
const TEX_WEAPON_B = preload("res://assets/sprites/items/sliced/weapon_tier_b.png")
const TEX_WEAPON_A = preload("res://assets/sprites/items/sliced/weapon_tier_a.png")
const TEX_WEAPON_R = preload("res://assets/sprites/items/sliced/weapon_tier_r.png")
const TEX_WEAPON_SR = preload("res://assets/sprites/items/sliced/weapon_tier_sr.png")
const TEX_WEAPON_SSR = preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")

@onready var item_sprite: Sprite3D = get_node_or_null("ItemSprite")
@onready var visual_mesh: MeshInstance3D = get_node_or_null("VisualMesh")
@onready var item_light: OmniLight3D = $ItemLight
@onready var beam_mesh: MeshInstance3D = get_node_or_null("BeamMesh")
@onready var label: Label3D = get_node_or_null("Label3D")

func setup(p_type: ItemType, p_rarity: Rarity = Rarity.D, p_name: String = "") -> void:
	item_type = p_type
	rarity = p_rarity
	item_name = p_name
	
	_apply_visual_style()

func _ready() -> void:
	base_y = global_position.y
	float_offset = randf_range(0.0, 6.28)
	body_entered.connect(_on_body_entered)
	_apply_visual_style()

func _process(delta: float) -> void:
	if is_collected:
		return
		
	# Xoay tròn và nhấp nhô
	float_offset += delta * 3.0
	if visual_mesh:
		visual_mesh.rotation.y += delta * 2.5
		visual_mesh.position.y = 0.5 + sin(float_offset) * 0.15
		
	# Cơ chế hút nam châm (Magnetic suction) cho Hạt Sinh Mệnh
	if item_type == ItemType.LIFE_SHARD:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var p = players[0]
			var dist = global_position.distance_to(p.global_position)
			if dist < 4.5:
				magnet_speed = move_toward(magnet_speed, 14.0, delta * 25.0)
				var dir = (p.global_position + Vector3(0, 0.8, 0) - global_position).normalized()
				dir.z = 0.0
				global_position += dir * magnet_speed * delta

func _apply_visual_style() -> void:
	var color = Color(0.2, 0.8, 0.4)
	match item_type:
		ItemType.LIFE_SHARD:
			color = Color(0.2, 0.9, 0.4)
			if label: label.text = "💚 Hạt Sinh Mệnh"
			if item_sprite: item_sprite.texture = TEX_LIFE_SHARD
		ItemType.LIFE_FLASK:
			color = Color(1.0, 0.3, 0.3)
			if label: label.text = "🧪 Bình Máu Lớn"
			if item_sprite: item_sprite.texture = TEX_LIFE_FLASK
		ItemType.HEART_CORE:
			color = Color(1.0, 0.1, 0.35)
			if label: label.text = "❤️ Trái Tim Huyết Tế"
			if item_sprite: item_sprite.texture = TEX_HEART_CORE
		ItemType.WEAPON:
			color = _get_rarity_color(rarity)
			if label: label.text = "[%s] %s" % [_get_rarity_str(rarity), item_name]
			if item_sprite:
				match rarity:
					Rarity.D: item_sprite.texture = TEX_WEAPON_D
					Rarity.C: item_sprite.texture = TEX_WEAPON_C
					Rarity.B: item_sprite.texture = TEX_WEAPON_B
					Rarity.A: item_sprite.texture = TEX_WEAPON_A
					Rarity.R: item_sprite.texture = TEX_WEAPON_R
					Rarity.SR: item_sprite.texture = TEX_WEAPON_SR
					Rarity.SSR: item_sprite.texture = TEX_WEAPON_SSR
			
	if item_light:
		item_light.light_color = color
	if label:
		label.modulate = color
	if beam_mesh:
		beam_mesh.visible = (item_type == ItemType.WEAPON or item_type == ItemType.HEART_CORE)
		if beam_mesh.visible and beam_mesh.material_override:
			beam_mesh.material_override.albedo_color = Color(color.r, color.g, color.b, 0.45)

func _get_rarity_color(r: Rarity) -> Color:
	match r:
		Rarity.D: return Color(0.65, 0.65, 0.7)
		Rarity.C: return Color(0.9, 0.95, 1.0)
		Rarity.B: return Color(0.25, 0.85, 0.4)
		Rarity.A: return Color(0.2, 0.65, 1.0)
		Rarity.R: return Color(0.75, 0.3, 1.0)
		Rarity.SR: return Color(1.0, 0.85, 0.2)
		Rarity.SSR: return Color(1.0, 0.2, 0.35)
	return Color.WHITE

func _get_rarity_str(r: Rarity) -> String:
	match r:
		Rarity.D: return "D"
		Rarity.C: return "C"
		Rarity.B: return "B"
		Rarity.A: return "A"
		Rarity.R: return "R"
		Rarity.SR: return "SR"
		Rarity.SSR: return "SSR"
	return "D"

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		_collect(body)

func _collect(player: Node3D) -> void:
	match item_type:
		ItemType.LIFE_SHARD:
			if player.has_method("take_damage") and "current_hp" in player and "max_hp" in player:
				player.current_hp = min(player.max_hp, player.current_hp + (player.max_hp * 0.08))
				player.hp_changed.emit(player.current_hp, player.max_hp)
		ItemType.LIFE_FLASK:
			if player.has_method("add_flask"):
				player.add_flask(1)
			elif player.has_method("take_damage") and "current_hp" in player and "max_hp" in player:
				player.current_hp = min(player.max_hp, player.current_hp + (player.max_hp * 0.35))
				player.hp_changed.emit(player.current_hp, player.max_hp)
		ItemType.HEART_CORE:
			if player.has_method("take_damage") and "current_hp" in player and "max_hp" in player:
				player.current_hp = min(player.max_hp, player.current_hp + (player.max_hp * 0.50))
				player.hp_changed.emit(player.current_hp, player.max_hp)
				player.base_atk *= 1.10 # +10% ATK
		ItemType.WEAPON:
			var tier_str = "tier_" + _get_rarity_str(rarity).to_lower()
			var item_dict = {
				"type": "weapon",
				"tier": tier_str,
				"name": item_name,
				"options": WeaponOptionGenerator.generate_options(tier_str) if ClassDB.class_exists("WeaponOptionGenerator") or (WeaponOptionGenerator != null) else []
			}
			if player.has_method("add_to_inventory"):
				player.add_to_inventory(item_dict)
			elif "base_atk" in player:
				player.base_atk += (int(rarity) + 1) * 3.0
				
	# Pop effect
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.4, 1.4, 1.4), 0.1)
	tw.parallel().tween_property(self, "position:y", position.y + 0.6, 0.1)
	tw.chain().tween_property(self, "scale", Vector3.ZERO, 0.15)
	tw.tween_callback(queue_free)
