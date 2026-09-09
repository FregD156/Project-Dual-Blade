class_name LootManager
extends RefCounted

## LootManager - Quản lý tỷ lệ rơi đồ, phẩm chất D -> SSR và tạo vũ khí ngẫu nhiên
## Tuân thủ nghiêm ngặt bảng Phần A.III và Phần D Detail.md

const RARITY_WEIGHTS: Dictionary = {
	"D": 500,
	"C": 300,
	"B": 130,
	"A": 55,
	"R": 13,
	"SR": 1.9,
	"SSR": 0.1
}

static func roll_rarity() -> String:
	var total_weight: float = 0.0
	for w in RARITY_WEIGHTS.values():
		total_weight += w
		
	var roll: float = randf() * total_weight
	var current: float = 0.0
	for tier in RARITY_WEIGHTS.keys():
		current += RARITY_WEIGHTS[tier]
		if roll <= current:
			return tier
	return "D"

static func generate_weapon(tier_override: String = "") -> Dictionary:
	var tier: String = tier_override if tier_override != "" else roll_rarity()
	
	# Load configs
	var file := FileAccess.open("res://data/balance/combat_balance.json", FileAccess.READ)
	if not file:
		return {}
	var balance_data: Dictionary = JSON.parse_string(file.get_as_text())
	var tier_info: Dictionary = balance_data.get("rarity_tiers", {}).get(tier, {})
	
	return {
		"tier": tier,
		"atk": tier_info.get("atk_base", 12),
		"crit_rate": tier_info.get("crit_rate", 0.05),
		"color_hex": tier_info.get("color_hex", "#888888"),
		"sub_options": []
	}
