class_name ArmorSystem
extends RefCounted

## ArmorSystem: Hệ thống Mũ (Helmet), Áo Giáp (Chest), Tay (Arms), Chân (Legs)
## Tính năng:
## - 4 Vị trí trang bị (Helmet, Chest, Arms, Legs)
## - Phẩm cấp phân tầng: Tier D -> C -> B -> A -> R -> SR -> SSR
## - Lớp Giáp Bảo Vệ (Shield/Armor Pool) hấp thụ sát thương trước khi trừ vào Máu (HP)
## - Cơ chế tự động hồi phục đầy 100% Giáp sau mỗi Round / khi chuyển ải mới
## - Icon Sprite pixel art riêng biệt cho từng bộ phận

const ARMOR_PARTS = ["helmet", "chest", "arms", "legs"]

const TIER_ARMOR_VALUES = {
	# Giá trị giáp cộng dồn theo từng món đồ
	"helmet": {
		"tier_d": 5.0,
		"tier_c": 10.0,
		"tier_b": 18.0,
		"tier_a": 30.0,
		"tier_r": 48.0,
		"tier_sr": 75.0,
		"tier_ssr": 110.0
	},
	"chest": {
		"tier_d": 12.0,
		"tier_c": 24.0,
		"tier_b": 42.0,
		"tier_a": 68.0,
		"tier_r": 105.0,
		"tier_sr": 160.0,
		"tier_ssr": 240.0
	},
	"arms": {
		"tier_d": 4.0,
		"tier_c": 8.0,
		"tier_b": 15.0,
		"tier_a": 25.0,
		"tier_r": 40.0,
		"tier_sr": 62.0,
		"tier_ssr": 95.0
	},
	"legs": {
		"tier_d": 6.0,
		"tier_c": 12.0,
		"tier_b": 22.0,
		"tier_a": 35.0,
		"tier_r": 55.0,
		"tier_sr": 85.0,
		"tier_ssr": 130.0
	}
}

const PART_NAMES = {
	"helmet": "Mũ Thiết Vệ",
	"chest": "Áo Giáp Huyết Nguyệt",
	"arms": "Hộ Thủ Gai Thép",
	"legs": "Chiến Ngoa Thiết Giáp"
}

const TEXTURES = {
	"helmet": preload("res://assets/sprites/armor/armor_helmet.png"),
	"chest": preload("res://assets/sprites/armor/armor_chest.png"),
	"arms": preload("res://assets/sprites/armor/armor_arms.png"),
	"legs": preload("res://assets/sprites/armor/armor_legs.png")
}

static func create_armor_item(part: String, tier: String) -> Dictionary:
	var armor_val = TIER_ARMOR_VALUES.get(part, {}).get(tier, 10.0)
	var part_display = PART_NAMES.get(part, "Trang Bị")
	var tier_display = tier.replace("tier_", "").to_upper()
	
	return {
		"type": "armor",
		"part": part, # helmet, chest, arms, legs
		"tier": tier,
		"name": "%s [%s]" % [part_display, tier_display],
		"armor_value": armor_val,
		"options": _generate_armor_options(tier)
	}

static func _generate_armor_options(tier: String) -> Array[Dictionary]:
	var opts: Array[Dictionary] = []
	match tier:
		"tier_c":
			opts.append({"desc": "+5% Giáp Tối Đa", "armor_pct": 0.05})
		"tier_b":
			opts.append({"desc": "+8% Giáp Tối Đa", "armor_pct": 0.08})
			opts.append({"desc": "+2 Giáp Cố Định", "flat_armor": 2.0})
		"tier_a":
			opts.append({"desc": "+12% Giáp Tối Đa", "armor_pct": 0.12})
			opts.append({"desc": "Giảm 5% Sát Thương Dính Đòn", "damage_reduce": 0.05})
		"tier_r":
			opts.append({"desc": "+18% Giáp Tối Đa", "armor_pct": 0.18})
			opts.append({"desc": "Tự Động Hồi 2 Giáp/giây khi không chiến đấu", "armor_regen": 2.0})
		"tier_sr":
			opts.append({"desc": "+25% Giáp Tối Đa", "armor_pct": 0.25})
			opts.append({"desc": "Giáp Vỡ: Kích nổ sóng đẩy lùi kẻ địch xung quanh", "on_break_shockwave": true})
		"tier_ssr":
			opts.append({"desc": "+35% Giáp Tối Đa", "armor_pct": 0.35})
			opts.append({"desc": "Kim Cang Hộ Thể: Chặn 1 đòn sát thương chí tử mỗi ải", "cheat_death": true})
	return opts
