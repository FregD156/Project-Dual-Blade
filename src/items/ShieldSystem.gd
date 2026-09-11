class_name ShieldSystem
extends RefCounted

## ShieldSystem: Hệ thống Khiên Hộ Thân (Shield Item System)
## Tính năng theo yêu cầu người chơi:
## - Là một loại item riêng biệt có thể nhặt, trang bị trong Túi Đồ [B]
## - Phẩm cấp phân tầng chuẩn: D -> C -> B -> A -> R -> SR -> SSR
## - Tỉ lệ rơi ngẫu nhiên từ quái vật / Boss tương tự như vũ khí
## - Chỉ số nội tại:
##   1. Tăng Máu Tối Đa (+HP Flat & +HP %)
##   2. Tăng Lớp Giáp/Chắn (+Block Armor & Tỉ lệ chặn hoàn toàn đòn đánh Block Chance)
##   3. Phản chấn / Khiên chắn hào quang khi bị tấn công

const SHIELD_TIERS = {
	"tier_d": {
		"name": "Khiên Gỗ Rỉ",
		"bonus_hp": 15.0,
		"bonus_armor": 12.0,
		"block_chance": 0.10, # 10% cơ hội chặn đứng hoàn toàn đòn đánh
		"damage_reduction": 0.15
	},
	"tier_c": {
		"name": "Khiên Sắt Tân Binh",
		"bonus_hp": 30.0,
		"bonus_armor": 25.0,
		"block_chance": 0.14,
		"damage_reduction": 0.20
	},
	"tier_b": {
		"name": "Khiên Thép Quân Tiên Phong",
		"bonus_hp": 55.0,
		"bonus_armor": 45.0,
		"block_chance": 0.18,
		"damage_reduction": 0.25
	},
	"tier_a": {
		"name": "Khiên Lam Ngọc Hộ Vệ",
		"bonus_hp": 90.0,
		"bonus_armor": 75.0,
		"block_chance": 0.24,
		"damage_reduction": 0.32
	},
	"tier_r": {
		"name": "Khiên Hư Không Tử Tinh",
		"bonus_hp": 140.0,
		"bonus_armor": 120.0,
		"block_chance": 0.30,
		"damage_reduction": 0.40
	},
	"tier_sr": {
		"name": "Khiên Thái Dương Hoàng Kim",
		"bonus_hp": 210.0,
		"bonus_armor": 180.0,
		"block_chance": 0.38,
		"damage_reduction": 0.50
	},
	"tier_ssr": {
		"name": "Khiên Thần Bất Diệt Aegis",
		"bonus_hp": 320.0,
		"bonus_armor": 280.0,
		"block_chance": 0.50, # 50% chặn hoàn toàn mọi đòn tấn công
		"damage_reduction": 0.65
	}
}

const TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/shield/shield_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/shield/shield_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/shield/shield_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/shield/shield_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/shield/shield_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/shield/shield_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/shield/shield_tier_ssr.png")
}

static func create_shield_item(tier: String) -> Dictionary:
	var data = SHIELD_TIERS.get(tier, SHIELD_TIERS["tier_d"])
	var tier_display = tier.replace("tier_", "").to_upper()
	
	return {
		"type": "shield",
		"tier": tier,
		"name": "%s [%s]" % [data["name"], tier_display],
		"bonus_hp": data["bonus_hp"],
		"bonus_armor": data["bonus_armor"],
		"block_chance": data["block_chance"],
		"damage_reduction": data["damage_reduction"],
		"options": _generate_shield_options(tier),
		"time": Time.get_ticks_msec()
	}

static func _generate_shield_options(tier: String) -> Array[Dictionary]:
	var opts: Array[Dictionary] = []
	match tier:
		"tier_c":
			opts.append({"desc": "+5% Tỉ Lệ Chặn Đòn", "bonus_block": 0.05})
		"tier_b":
			opts.append({"desc": "+10% Máu Tối Đa", "hp_pct": 0.10})
			opts.append({"desc": "+5% Tỉ Lệ Chặn Đòn", "bonus_block": 0.05})
		"tier_a":
			opts.append({"desc": "+15% Máu Tối Đa", "hp_pct": 0.15})
			opts.append({"desc": "Phản đòn: Chặn đòn thành công gây choáng kẻ địch 0.3s", "block_stun": true})
		"tier_r":
			opts.append({"desc": "+20% Máu Tối Đa", "hp_pct": 0.20})
			opts.append({"desc": "+10% Tỉ Lệ Chặn Đòn", "bonus_block": 0.10})
			opts.append({"desc": "Hồi 5% Giáp khi chặn đòn thành công", "block_heal_armor": 0.05})
		"tier_sr":
			opts.append({"desc": "+30% Máu Tối Đa", "hp_pct": 0.30})
			opts.append({"desc": "+15% Tỉ Lệ Chặn Đòn", "bonus_block": 0.15})
			opts.append({"desc": "Khiên Bão Nộ: Chặn đòn tự động tích 1 điểm FLOW", "block_flow": 1})
		"tier_ssr":
			opts.append({"desc": "+50% Máu Tối Đa", "hp_pct": 0.50})
			opts.append({"desc": "+20% Tỉ Lệ Chặn Đòn (Lên tới 70%)", "bonus_block": 0.20})
			opts.append({"desc": "Thần Hộ Mệnh: Bất tử chặn 100% đòn đánh khi Máu dưới 25%", "immortal_threshold": 0.25})
	return opts
