class_name World1StageManager
extends Node2D

## World 1 Complete Progression Controller (Ải 1.1 -> 1.10)
## Nhịp ải: Khởi động (1.1-1.4) -> Elite 1.5 -> Khó tăng (1.6-1.8) -> Safe Haven 1.9 -> Boss 1.10

@export var current_stage: int = 1

signal stage_changed(stage_num: int)
signal stage_cleared(stage_num: int)

@onready var player: PlayerController = $Player
@onready var portal_combat: PortalChoiceTrigger = $PortalCombat
@onready var portal_sustain: PortalChoiceTrigger = $PortalSustain
@onready var boss_node: BossIroncladCommander = $BossIroncladCommander
@onready var dummy_enemy: DummyEnemy = $DummyEnemy
@onready var stage_label: Label = $StageUI/StageLabel

func _ready() -> void:
	if portal_combat:
		portal_combat.setup(PortalChoiceManager.PortalType.COMBAT, "Cổng Đao Kiếm", Color(0.9, 0.2, 0.2, 0.6))
		portal_combat.portal_entered.connect(_on_portal_entered)
		portal_combat.visible = false
		portal_combat.monitoring = false
		
	if portal_sustain:
		portal_sustain.setup(PortalChoiceManager.PortalType.SUSTAIN, "Cổng Sinh Mệnh", Color(0.2, 0.8, 0.3, 0.6))
		portal_sustain.portal_entered.connect(_on_portal_entered)
		portal_sustain.visible = false
		portal_sustain.monitoring = false
		
	if boss_node:
		boss_node.visible = false
		boss_node.process_mode = Node.PROCESS_MODE_DISABLED
		boss_node.boss_defeated.connect(_on_boss_cleared)
		
	_load_stage(1)

func _load_stage(stage_num: int) -> void:
	current_stage = stage_num
	stage_changed.emit(current_stage)
	
	if stage_label:
		stage_label.text = "=== WORLD 1: CỔ THÀNH HOANG TÀN — ẢI 1.%d ===" % current_stage
		
	# Ẩn portal khi bắt đầu ải mới
	_set_portals_active(false)
	
	match current_stage:
		1, 2, 3, 4:
			print("[STAGE] Ải 1.%d: Khởi động dọn quái thường!" % current_stage)
			if dummy_enemy:
				dummy_enemy.visible = true
				dummy_enemy.process_mode = Node.PROCESS_MODE_INHERIT
		5:
			print("[STAGE] Ải 1.5: QUÁI TINH ANH — Thủ Lĩnh Đao Phủ Quỷ!")
		6, 7, 8:
			print("[STAGE] Ải 1.%d: Tăng tốc độ khó & bẫy môi trường!" % current_stage)
		9:
			print("[STAGE] Ải 1.9: SAFE HAVEN — Trạm nghỉ an toàn & Lão Thợ Rèn!")
			if dummy_enemy:
				dummy_enemy.visible = false
				dummy_enemy.process_mode = Node.PROCESS_MODE_DISABLED
			_set_portals_active(true)
		10:
			print("[STAGE] Ải 1.10: ĐẠI TRÙM CUỐI — Thống Lĩnh Thiết Vệ!")
			if dummy_enemy:
				dummy_enemy.visible = false
				dummy_enemy.process_mode = Node.PROCESS_MODE_DISABLED
			if boss_node:
				boss_node.visible = true
				boss_node.process_mode = Node.PROCESS_MODE_INHERIT

func on_enemies_cleared() -> void:
	stage_cleared.emit(current_stage)
	if current_stage < 10:
		_set_portals_active(true)

func _set_portals_active(active: bool) -> void:
	if portal_combat:
		portal_combat.visible = active
		portal_combat.monitoring = active
	if portal_sustain:
		portal_sustain.visible = active
		portal_sustain.monitoring = active

func _on_portal_entered(portal_type: PortalChoiceManager.PortalType) -> void:
	print("[STAGE PROGRESSION] Đã chọn cổng dịch chuyển:", "Đao Kiếm" if portal_type == PortalChoiceManager.PortalType.COMBAT else "Sinh Mệnh")
	if current_stage < 10:
		_load_stage(current_stage + 1)

func _on_boss_cleared() -> void:
	if stage_label:
		stage_label.text = "CHIẾN THẮNG WORLD 1! ĐÃ HẠ GỤC THỐNG LĨNH THIẾT VỆ!"
