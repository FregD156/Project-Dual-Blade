class_name WeaponOptionGenerator
extends RefCounted

## Bể dòng Option (Option Pool) theo detail.md Phần A.III.2
## D/C: Chỉ số nền
## B/A: Tối ưu giao tranh (Huyết khát, Nạp khí, Xuyên giáp, Hư ảnh bước)
## R/SR: Biến đổi chiêu thức (Lôi kích liêm, Huyết nhẫn, Phản kích tử thần, Vũ điệu phân thân)
## SSR: Lõi thức tỉnh (Luân hồi hư không, Diệt thế thần khí)

const OPTIONS = {
	"tier_d": [
		{"id": "d_blunt", "name": "Cùn Nhẹ", "desc": "+5% Sát thương vật lý", "atk_pct": 0.05},
		{"id": "d_light", "name": "Nhẹ Tay", "desc": "+4% Tốc độ chạy", "speed_pct": 0.04}
	],
	"tier_c": [
		{"id": "c_sharp", "name": "Mài Sắc", "desc": "+6% Tỷ lệ chí mạng", "crit_pct": 0.06},
		{"id": "c_balance", "name": "Cân Bằng", "desc": "+8% Giảm thời gian khựng", "rec_pct": 0.08}
	],
	"tier_b": [
		{"id": "b_lifesteal", "name": "Huyết Khát Nhỏ", "desc": "Hồi 1% HP khi diệt địch", "vamp_pct": 0.01},
		{"id": "b_flow", "name": "Nạp Khí", "desc": "+15% Tốc độ tích lũy Flow", "flow_pct": 0.15}
	],
	"tier_a": [
		{"id": "a_armor_pen", "name": "Xuyên Giáp", "desc": "Bỏ qua 20% giáp kẻ địch", "armor_pen": 0.20},
		{"id": "a_shadow_step", "name": "Hư Ảnh Bước", "desc": "+0.04s bất tử (i-frame) cho Dash", "dash_iframe": 0.04}
	],
	"tier_r": [
		{"id": "r_lightning", "name": "Lôi Kích Liêm", "desc": "Đòn thứ 4 giật sét sang mục tiêu lân cận", "lightning": true},
		{"id": "r_bleed", "name": "Huyết Nhẫn", "desc": "Đòn đánh gây Chảy Máu tích 5 tầng nổ 10% HP", "bleed": true}
	],
	"tier_sr": [
		{"id": "sr_death_counter", "name": "Phản Kích Tử Thần", "desc": "Parry chuẩn xác chém chí mạng 250% và hồi 5% HP", "counter_heal": 0.05},
		{"id": "sr_shadow_dance", "name": "Vũ Điệu Phân Thân", "desc": "Ở Full Flow, mỗi đòn đánh kèm dư ảnh gây 35% sát thương", "ghost_strike": 0.35}
	],
	"tier_ssr": [
		{"id": "ssr_time_dilation", "name": "Luân Hồi Hư Không", "desc": "Just-dodge làm chậm thời gian toàn map 50% trong 1.5s", "bullet_time": true},
		{"id": "ssr_infinite_slash", "name": "Diệt Thế Thần Khí", "desc": "Tất sát bão kiếm 12 nhát toàn màn hình", "infinite_slash": true}
	]
}

static func generate_options(tier: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match tier:
		"tier_d":
			# 0 dòng option
			pass
		"tier_c":
			# 1 dòng D
			result.append(_pick_random("tier_d"))
		"tier_b":
			# 1 dòng C + 1 dòng D
			result.append(_pick_random("tier_c"))
			result.append(_pick_random("tier_d"))
		"tier_a":
			# 2 dòng B
			result.append(_pick_random("tier_b"))
			result.append(_pick_random("tier_b"))
		"tier_r":
			# 2 dòng A + 1 dòng R
			result.append(_pick_random("tier_a"))
			result.append(_pick_random("tier_a"))
			result.append(_pick_random("tier_r"))
		"tier_sr":
			# 3 dòng R + 1 Nội tại SR
			result.append(_pick_random("tier_r"))
			result.append(_pick_random("tier_r"))
			result.append(_pick_random("tier_r"))
			result.append(_pick_random("tier_sr"))
		"tier_ssr":
			# 3 dòng SR + 1 Lõi Thức Tỉnh SSR
			result.append(_pick_random("tier_sr"))
			result.append(_pick_random("tier_sr"))
			result.append(_pick_random("tier_sr"))
			result.append(_pick_random("tier_ssr"))
	return result

static func _pick_random(tier_pool: String) -> Dictionary:
	if not OPTIONS.has(tier_pool):
		return {}
	var list = OPTIONS[tier_pool]
	return list[randi() % list.size()].duplicate(true)
