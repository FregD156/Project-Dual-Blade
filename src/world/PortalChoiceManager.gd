class_name PortalChoiceManager
extends RefCounted

## Cơ chế phân nhánh ải (Portal Choice) sau khi quét sạch quái (Phần A.IV.2 Detail.md)
## 1. Combat Portal (Cổng Đao Kiếm): Quái dày, rơi phôi rèn và quặng
## 2. Sustain Portal (Cổng Sinh Mệnh): Quái thưa, bẫy sàn, đảm bảo rơi Life Shard / Life Flask

enum PortalType {
	COMBAT,
	SUSTAIN
}

static func generate_portal_choices(current_stage: int) -> Dictionary:
	return {
		"stage_from": current_stage,
		"stage_to": current_stage + 1,
		"choices": [
			{
				"type": PortalType.COMBAT,
				"name": "Cổng Đao Kiếm",
				"color_hex": "#E74C3C",
				"description": "Mật độ quái dày hơn, rơi nhiều phôi rèn vũ khí & quặng nâng cấp."
			},
			{
				"type": PortalType.SUSTAIN,
				"name": "Cổng Sinh Mệnh",
				"color_hex": "#2ECC71",
				"description": "Quái thưa, nhiều bẫy gai, đảm bảo rơi Hạt Sinh Mệnh & Bình Máu Lớn."
			}
		]
	}
