class_name BlacksmithManager
extends RefCounted

## Thợ Rèn (Vulcan Tàn Diệt) - Xử lý Salvage (Tái Chế) & Re-roll (Tẩy Dòng)
## Tham chiếu: Detail.md Phần A.III.3 & agent.md Mục 5.4

static func salvage_weapons(weapons: Array) -> Dictionary:
	if weapons.size() != 3:
		return { "success": false, "error": "Cần đúng 3 vũ khí cùng bậc để tái chế!" }
		
	var tier: String = weapons[0].get("tier", "D")
	for w in weapons:
		if w.get("tier") != tier:
			return { "success": false, "error": "Toàn bộ 3 vũ khí phải có cùng phẩm cấp!" }
			
	# Thăng bậc kế tiếp nếu có thể
	var tier_ladder := ["D", "C", "B", "A", "R", "SR", "SSR"]
	var current_idx := tier_ladder.find(tier)
	
	if current_idx >= 0 and current_idx < tier_ladder.size() - 1:
		var next_tier := tier_ladder[current_idx + 1]
		var upgraded_weapon := LootManager.generate_weapon(next_tier)
		return {
			"success": true,
			"reward_type": "upgraded_weapon",
			"weapon": upgraded_weapon,
			"message": "Nấu chảy thành công! Tạo ra 1 vũ khí bậc [%s]!" % next_tier
		}
	else:
		return {
			"success": true,
			"reward_type": "divine_materials",
			"materials_count": 50,
			"message": "Phân rã SSR thành công! Nhận 50 Tinh thể Tối thượng!"
		}

static func reroll_option(weapon: Dictionary, option_index: int, available_pool: Array) -> Dictionary:
	var tier: String = weapon.get("tier", "D")
	var tier_ladder := ["D", "C", "B", "A", "R", "SR", "SSR"]
	var tier_idx := tier_ladder.find(tier)
	
	# Chỉ áp dụng tẩy dòng từ bậc R trở lên (theo Detail.md Phần A.III.3)
	if tier_idx < 4: # R là index 4
		return { "success": false, "error": "Chỉ có thể tẩy dòng trên vũ khí từ bậc R trở lên!" }
		
	var options: Array = weapon.get("sub_options", [])
	if option_index < 0 or option_index >= options.size():
		return { "success": false, "error": "Vị trí dòng tẩy không hợp lệ!" }
		
	# Chọn option mới ngẫu nhiên từ pool
	if available_pool.size() > 0:
		var new_opt = available_pool.pick_random()
		options[option_index] = new_opt
		weapon["sub_options"] = options
		return {
			"success": true,
			"new_option": new_opt,
			"message": "Tẩy dòng thành công! Nhận được: %s" % new_opt.get("name", "")
		}
		
	return { "success": false, "error": "Bể option trống!" }
