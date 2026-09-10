class_name GameUI
extends CanvasLayer

## Giao diện HUD chuẩn Dark Fantasy Pixel-Art (Ergonomic HUD)
## Tính năng:
## 1. Thanh máu Huyết Nguyệt 2 lớp: Viền hợp kim đen bóng, Lớp máu đỏ thẫm ruby, Lớp Catch-up vàng kim
## 2. Text HP: "HP: 75/100" sắc nét
## 3. Cụm FLOW 5 ô vuông Neon Cyan (#00e5ff) với hiệu ứng Pulse bừng sáng khi đầy 5 vạch (Xuất Quỷ)
## 4. Bảng trang bị vũ khí + Hiển thị số lượng Bình Máu & Tinh thể Nâng cấp
## 5. Nút mở nhanh Túi Đồ [B]
## 6. Boss HP Bar hoành tráng phong cách Souls-like (Boss 1.10 Thống Lĩnh Thiết Vệ)

@onready var hp_catchup: ColorRect = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/Background/CatchupFill
@onready var hp_fill: ColorRect = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/Background/Fill
@onready var hp_label: Label = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/HPText

# Armor Panel Nodes (Thanh Giáp cạnh HP)
@onready var armor_panel: Control = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/ArmorPanel")
@onready var armor_catchup: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/ArmorPanel/Border/Background/CatchupFill")
@onready var armor_fill: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/ArmorPanel/Border/Background/Fill")
@onready var armor_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/ArmorPanel/Border/ArmorText")

const ARMOR_BAR_MAX_WIDTH: float = 76.0
var armor_catchup_tween: Tween = null

@onready var flow_cells: Array[ColorRect] = [
	$TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/Background/FlowContainer/Cell1,
	$TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/Background/FlowContainer/Cell2,
	$TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/Background/FlowContainer/Cell3,
	$TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/Background/FlowContainer/Cell4,
	$TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/Background/FlowContainer/Cell5
]
@onready var flow_title: Label = $TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/FlowTitle

@onready var weapon_icon: TextureRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/WeaponPanel/WeaponIcon")
@onready var weapon_tier_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/WeaponPanel/WeaponTierLabel")
@onready var flask_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/FlaskPanel/FlaskLabel")
@onready var crystal_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/FlaskPanel/CrystalLabel")
@onready var bag_btn: Button = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/BagBtn")

# Boss Bar Nodes
@onready var boss_bar_container: Control = get_node_or_null("BossBarContainer")
@onready var boss_name_label: Label = get_node_or_null("BossBarContainer/VBox/BossName")
@onready var boss_hp_fill: ColorRect = get_node_or_null("BossBarContainer/VBox/BarBorder/Background/Fill")
@onready var boss_hp_catchup: ColorRect = get_node_or_null("BossBarContainer/VBox/BarBorder/Background/Catchup")

const HP_BAR_MAX_WIDTH: float = 106.0
const BOSS_BAR_MAX_WIDTH: float = 236.0

var catchup_tween: Tween = null
var pulse_tween: Tween = null
var boss_catchup_tween: Tween = null

const WEAPON_TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/sliced/weapon_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/sliced/weapon_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/sliced/weapon_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/sliced/weapon_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/sliced/weapon_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/sliced/weapon_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")
}

func _ready() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false

func connect_player(player: Player) -> void:
	if not player:
		return
	player.hp_changed.connect(_on_hp_changed)
	player.flow_changed.connect(_on_flow_changed)
	if player.has_signal("flasks_changed"):
		player.flasks_changed.connect(_on_flasks_changed)
	if player.has_signal("weapon_equipped"):
		player.weapon_equipped.connect(_on_weapon_equipped)
	if player.has_signal("crystals_changed"):
		player.crystals_changed.connect(_on_crystals_changed)
	if player.has_signal("armor_changed"):
		player.armor_changed.connect(_on_armor_changed)
	
	_on_hp_changed(player.current_hp, player.max_hp)
	_on_armor_changed(player.current_armor, player.max_armor)
	_on_flow_changed(player.current_flow, false)
	_on_flasks_changed(player.life_flasks, player.max_flasks)
	_on_weapon_equipped(player.current_weapon_tier, player.base_atk, player.crit_rate)
	_on_crystals_changed(player.upgrade_crystals)
	
	if bag_btn:
		bag_btn.pressed.connect(func():
			var inv = get_parent().get_node_or_null("UI_Layer/InventoryUI")
			if not inv:
				inv = get_tree().root.find_child("InventoryUI", true, false)
			if inv and inv.has_method("toggle_inventory"):
				inv.toggle_inventory()
		)

func bind_boss(boss: EnemyBossCommander) -> void:
	if not boss:
		return
	if boss_bar_container:
		boss_bar_container.visible = true
	boss.boss_hp_updated.connect(_on_boss_hp_updated)
	boss.boss_defeated.connect(_on_boss_defeated)
	_on_boss_hp_updated(boss.current_hp, boss.max_hp, boss.enemy_name)

func _on_boss_hp_updated(current: float, maximum: float, boss_name: String) -> void:
	if not boss_bar_container:
		return
	boss_bar_container.visible = true
	if boss_name_label:
		boss_name_label.text = boss_name
	var ratio = clampf(current / max(1.0, maximum), 0.0, 1.0)
	var target_width = BOSS_BAR_MAX_WIDTH * ratio
	if boss_hp_fill:
		boss_hp_fill.size.x = target_width
	if boss_hp_catchup:
		if boss_catchup_tween:
			boss_catchup_tween.kill()
		boss_catchup_tween = create_tween()
		boss_catchup_tween.tween_interval(0.2)
		boss_catchup_tween.tween_property(boss_hp_catchup, "size:x", target_width, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_boss_defeated() -> void:
	if boss_bar_container:
		var tween = create_tween()
		tween.tween_property(boss_bar_container, "modulate:a", 0.0, 1.5)
		tween.tween_callback(func():
			boss_bar_container.visible = false
			boss_bar_container.modulate.a = 1.0
		)

func _on_flasks_changed(current: int, maximum: int) -> void:
	if flask_label:
		flask_label.text = "[Q] Bình: %d/%d" % [current, maximum]

func _on_crystals_changed(count: int) -> void:
	if crystal_label:
		crystal_label.text = "Thạch: %d" % count

func _on_weapon_equipped(tier_name: String, atk: float, crit: float) -> void:
	if WEAPON_TEXTURES.has(tier_name) and weapon_icon:
		weapon_icon.texture = WEAPON_TEXTURES[tier_name]
	if weapon_tier_label:
		var display_tier = tier_name.replace("tier_", "").to_upper()
		weapon_tier_label.text = "%s (ATK:%d)" % [display_tier, round(atk)]
		match tier_name:
			"tier_d": weapon_tier_label.modulate = Color(0.7, 0.7, 0.7)
			"tier_c": weapon_tier_label.modulate = Color(1.0, 1.0, 1.0)
			"tier_b": weapon_tier_label.modulate = Color(0.2, 1.0, 0.3)
			"tier_a": weapon_tier_label.modulate = Color(0.2, 0.6, 1.0)
			"tier_r": weapon_tier_label.modulate = Color(0.8, 0.3, 1.0)
			"tier_sr": weapon_tier_label.modulate = Color(1.0, 0.85, 0.2)
			"tier_ssr": weapon_tier_label.modulate = Color(1.0, 0.3, 0.5)

func _on_hp_changed(current: float, maximum: float) -> void:
	var ratio := clampf(current / max(1.0, maximum), 0.0, 1.0)
	var target_width := HP_BAR_MAX_WIDTH * ratio
	
	if hp_fill:
		hp_fill.size.x = target_width
		# Đổi sắc thái thanh máu Ruby / Cảnh báo nguy kịch
		if ratio < 0.3:
			hp_fill.color = Color(1.0, 0.1, 0.1) # Đỏ rực nguy cấp
		else:
			hp_fill.color = Color(0.85, 0.15, 0.22) # Đỏ Ruby Dark Fantasy
			
	# Thanh vàng kim Catch-up trượt đuổi theo sau 0.2s
	if hp_catchup:
		if catchup_tween:
			catchup_tween.kill()
		catchup_tween = create_tween()
		catchup_tween.tween_interval(0.2)
		catchup_tween.tween_property(hp_catchup, "size:x", target_width, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if hp_label:
		hp_label.text = "HP: %d / %d" % [round(current), round(maximum)]

func _on_armor_changed(current: float, maximum: float) -> void:
	if not armor_panel:
		return
		
	var ratio := clampf(current / max(1.0, maximum), 0.0, 1.0)
	var target_width := ARMOR_BAR_MAX_WIDTH * ratio
	
	if armor_fill:
		armor_fill.size.x = target_width
		# Đổi màu cảnh báo khi giáp sắp vỡ
		if ratio <= 0.0:
			armor_fill.color = Color(0.2, 0.25, 0.35, 0.3)
		elif ratio < 0.3:
			armor_fill.color = Color(1.0, 0.6, 0.2) # Cam cảnh báo
		else:
			armor_fill.color = Color(0.2, 0.65, 0.95) # Lam thép sáng
			
	if armor_catchup:
		if armor_catchup_tween:
			armor_catchup_tween.kill()
		armor_catchup_tween = create_tween()
		armor_catchup_tween.tween_interval(0.18)
		armor_catchup_tween.tween_property(armor_catchup, "size:x", target_width, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if armor_label:
		armor_label.text = "GIÁP: %d / %d" % [round(current), round(maximum)]

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	for i in range(5):
		if i < flow_cells.size():
			var cell = flow_cells[i]
			if i < stacks:
				# Tích tụ năng lượng: Cyan phát quang
				cell.color = Color(0.0, 0.9, 1.0, 1.0)
			else:
				# Ô tối mờ
				cell.color = Color(0.1, 0.14, 0.2, 0.45)

	# Hiệu ứng bừng sáng khi đạt Max Flow (Xuất Quỷ)
	if is_full:
		if flow_title:
			flow_title.text = "FLOW [XUẤT QUỶ]"
			flow_title.modulate = Color(1.0, 0.85, 0.25)
		if not pulse_tween or not pulse_tween.is_valid():
			pulse_tween = create_tween().set_loops()
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(2.0, 2.0, 2.0, 1.0), 0.22)
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.22)
	else:
		if pulse_tween:
			pulse_tween.kill()
		for cell in flow_cells:
			cell.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if flow_title:
			flow_title.text = "FLOW"
			flow_title.modulate = Color(0.0, 0.9, 1.0, 1.0)
