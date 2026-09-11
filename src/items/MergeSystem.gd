class_name MergeSystem
extends RefCounted

## MergeSystem: Hệ thống Hợp Thành / Ghép 5-lên-1 cho Trang Bị
## Quy tắc theo yêu cầu người chơi:
## - Cứ 5 món CÙNG LOẠI, CÙNG BẬC sẽ tự động ghép thành 1 món BẬC KẾ TIẾP:
##   5 món Tier D  -> 1 món Tier C
##   5 món Tier C  -> 1 món Tier B
##   5 món Tier B  -> 1 món Tier A
##   5 món Tier A  -> 1 món Tier R
##   5 món Tier R  -> 1 món Tier SR
##   5 món Tier SR -> 1 món Tier SSR
## - Áp dụng đồng bộ cho cả:
##   1. Vũ Khí (Weapon)
##   2. Mảnh Giáp 4 bộ phận (Armor: Helmet, Chest, Arms, Legs)
##   3. Khiên Hộ Thân (Shield)

const TIER_ORDER: Array[String] = [
	"tier_d",
	"tier_c",
	"tier_b",
	"tier_a",
	"tier_r",
	"tier_sr",
	"tier_ssr"
]

## Trả về bậc kế tiếp, hoặc rỗng nếu đã đạt SSR (kịch trần)
static func get_next_tier(current_tier: String) -> String:
	var idx = TIER_ORDER.find(current_tier)
	if idx != -1 and idx < TIER_ORDER.size() - 1:
		return TIER_ORDER[idx + 1]
	return ""

## Tạo key gom nhóm duy nhất cho mỗi món đồ
static func get_merge_group_key(item: Dictionary) -> String:
	var item_type = item.get("type", "weapon")
	var tier = item.get("tier", "tier_d")
	
	if item_type == "armor":
		var part = item.get("part", "chest")
		return "armor_%s_%s" % [part, tier]
	elif item_type == "shield":
		return "shield_%s" % [tier]
	else:
		return "weapon_%s" % [tier]

## Tạo ra món đồ mới ở next_tier dựa theo thông tin nhóm
static func create_upgraded_item(item_type: String, part: String, next_tier: String) -> Dictionary:
	if item_type == "armor":
		return ArmorSystem.create_armor_item(part, next_tier)
	elif item_type == "shield":
		return ShieldSystem.create_shield_item(next_tier)
	else: # weapon
		var opts = WeaponOptionGenerator.generate_options(next_tier)
		return {
			"type": "weapon",
			"tier": next_tier,
			"name": "Song Đao " + next_tier.replace("tier_", "").to_upper(),
			"options": opts,
			"time": Time.get_ticks_msec()
		}

## Thực hiện quét và ghép toàn bộ kho đồ (lặp lại cho đến khi không còn nhóm nào >= 5)
## Trả về danh sách các món đồ mới vừa được tạo thành công
static func perform_merge(inventory: Array[Dictionary]) -> Array[Dictionary]:
	var created_items: Array[Dictionary] = []
	var merged_in_pass = true
	
	while merged_in_pass:
		merged_in_pass = false
		# 1. Gom nhóm chỉ số index của các item trong inventory
		var groups: Dictionary = {} # group_key -> Array[int] (chỉ số index)
		
		for i in range(inventory.size()):
			var item = inventory[i]
			var tier = item.get("tier", "tier_d")
			# Tier SSR không thể ghép lên tiếp
			if tier == "tier_ssr":
				continue
			var key = get_merge_group_key(item)
			if not groups.has(key):
				groups[key] = []
			groups[key].append(i)
			
		# 2. Tìm nhóm đầu tiên có >= 5 món
		for key in groups.keys():
			var indices: Array = groups[key]
			if indices.size() >= 5:
				merged_in_pass = true
				
				# Lấy 5 index đầu tiên (sắp xếp giảm dần để xóa an toàn)
				var to_remove = indices.slice(0, 5)
				to_remove.sort()
				to_remove.reverse()
				
				# Lấy thông tin mẫu từ 1 món để tạo món nâng cấp
				var sample_item = inventory[to_remove[0]]
				var item_type = sample_item.get("type", "weapon")
				var part = sample_item.get("part", "chest")
				var cur_tier = sample_item.get("tier", "tier_d")
				var next_tier = get_next_tier(cur_tier)
				
				# Xóa 5 món cũ khỏi kho
				for idx in to_remove:
					inventory.remove_at(idx)
					
				# Tạo món mới bậc kế tiếp và thêm vào kho
				var new_item = create_upgraded_item(item_type, part, next_tier)
				inventory.append(new_item)
				created_items.append(new_item)
				
				# Sau khi xóa và thêm, thoát vòng lặp for để cập nhật lại chỉ số ở lượt lặp while tiếp theo
				break
				
	return created_items
