class_name GameUI
extends CanvasLayer

## Giao diện HUD chuẩn Pixel-Art 16-bit Công thái học (Ergonomic HUD)
## Tính năng:
## 1. Thanh máu 2 lớp: Lớp đỏ chính + Lớp vàng/trắng Catch-up Bar (trượt chậm thể hiện sát thương)
## 2. Text HP: "HP: 75/100" căn chính giữa thanh máu, font pixel sắc nét
## 3. Cụm FLOW 5 ô vuông Neon Cyan phát sáng (#00e5ff) với hiệu ứng Pulse bừng sáng khi đầy 5 vạch

@onready var hp_catchup: ColorRect = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/Background/CatchupFill
@onready var hp_fill: ColorRect = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/Background/Fill
@onready var hp_label: Label = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/HPText

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

const HP_BAR_MAX_WIDTH: float = 126.0

var catchup_tween: Tween = null
var pulse_tween: Tween = null

const WEAPON_TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/sliced/weapon_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/sliced/weapon_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/sliced/weapon_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/sliced/weapon_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/sliced/weapon_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/sliced/weapon_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")
}

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
	
	_on_hp_changed(player.current_hp, player.max_hp)
	_on_flow_changed(player.current_flow, false)
	_on_flasks_changed(player.life_flasks, player.max_flasks)
	_on_weapon_equipped(player.current_weapon_tier, player.base_atk, player.crit_rate)
	_on_crystals_changed(player.upgrade_crystals)
	
	if bag_btn:
		bag_btn.pressed.connect(func():
			var inv = get_parent().get_node_or_null("InventoryUI")
			if not inv:
				inv = get_tree().root.find_child("InventoryUI", true, false)
			if inv and inv.has_method("toggle_inventory"):
				inv.toggle_inventory()
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
		# Color based on rarity
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
		# Đổi màu cảnh báo máu thấp
		if ratio < 0.3:
			hp_fill.color = Color(0.95, 0.15, 0.15)
		else:
			hp_fill.color = Color(0.85, 0.22, 0.22)
			
	# Thanh vàng Catch-up trượt chậm dần sau 0.25s
	if hp_catchup:
		if catchup_tween:
			catchup_tween.kill()
		catchup_tween = create_tween()
		catchup_tween.tween_interval(0.25)
		catchup_tween.tween_property(hp_catchup, "size:x", target_width, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if hp_label:
		hp_label.text = "HP: %d / %d" % [round(current), round(maximum)]

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	# Cập nhật 5 ô vuông neon
	for i in range(5):
		if i < flow_cells.size():
			var cell = flow_cells[i]
			if i < stacks:
				# Ô đã tích lũy: Sáng bừng Cyan Neon (#00e5ff)
				cell.color = Color(0.0, 0.9, 1.0, 1.0)
			else:
				# Ô trống: Tối viền mờ
				cell.color = Color(0.12, 0.18, 0.25, 0.5)

	# Hiệu ứng Pulse nhấp nháy toàn cụm khi đạt trạng thái Full Flow
	if is_full:
		if flow_title:
			flow_title.text = "FLOW [XUẤT QUỶ]"
			flow_title.modulate = Color(1.0, 0.85, 0.2)
		if not pulse_tween or not pulse_tween.is_valid():
			pulse_tween = create_tween().set_loops()
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.25)
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)
	else:
		if pulse_tween:
			pulse_tween.kill()
		for cell in flow_cells:
			cell.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if flow_title:
			flow_title.text = "FLOW"
			flow_title.modulate = Color(0.0, 0.9, 1.0, 1.0)
