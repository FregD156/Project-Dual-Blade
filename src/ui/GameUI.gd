class_name GameUI
extends CanvasLayer

## Giao diện HUD chuẩn Dark Fantasy Pixel-Art (Ergonomic HUD - Luxury VFX Edition)
## Tính năng nâng cấp:
## 1. Khung HUD Gothic Hoa Văn Hợp Kim & Ngọc Ruby (Vitals Ornate Gothic Frame)
## 2. Thanh Máu Ruby Huyết Nguyệt:
##    - Lớp ánh sáng quét dọc theo thời gian (Gleam Shimmer)
##    - Hiệu ứng Tim Đập Nhịp Nhàng (Heartbeat Pulse) khi máu < 30%
##    - Lớp Catch-up vàng cam giật trễ mượt mà khi nhận đòn
##    - Rung lắc nhẹ khung HUD (HUD Shake) khi mất máu lớn
## 3. Thanh Giáp Lam Thạch (Cobalt Shield):
##    - Hiệu ứng tia năng lượng điện quang chạy quanh viền
##    - Hiệu ứng vỡ nát / lóe sáng khi giáp chạm mốc 0
## 4. Khung FLOW Ma Thuật Cổ Xưa (5 Rune Cells):
##    - Hiệu ứng Nạp Khí: Mỗi khi tích thêm 1 stack, ô ngọc nở bung & phát sáng cực đại
##    - Khi đầy 5 stacks: Khung FLOW bừng sáng rực rỡ, các ô ngọc đổi màu liên tục, tiêu đề nhảy múa
## 5. Boss Bar Souls-like hoành tráng phong cách Dark Souls / Elden Ring

@onready var vital_panel: Control = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel")
@onready var vitals_frame: TextureRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/GothicFrame")
@onready var hp_catchup: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/HPBar/Background/CatchupFill")
@onready var hp_fill: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/HPBar/Background/Fill")
@onready var hp_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/HPBar/HPText")
@onready var hp_shimmer: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/HPBar/Background/Shimmer")
@onready var ruby_gem: TextureRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/RubyGem")

@onready var armor_catchup: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/ArmorBar/Background/CatchupFill")
@onready var armor_fill: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/ArmorBar/Background/Fill")
@onready var armor_label: Label = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/ArmorBar/ArmorText")
@onready var armor_shimmer: ColorRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/VitalPanel/Border/Background/VBox/ArmorBar/Background/Shimmer")

@onready var flow_panel: Control = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/FlowPanel")
@onready var flow_frame: TextureRect = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/FlowPanel/GothicFrame")
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
@onready var map_btn: Button = get_node_or_null("TopContainer/MarginContainer/HBoxContainer/MapBtn")

# Boss Bar Nodes
@onready var boss_bar_container: Control = get_node_or_null("BossBarContainer")
@onready var boss_name_label: Label = get_node_or_null("BossBarContainer/VBox/BossName")
@onready var boss_hp_fill: ColorRect = get_node_or_null("BossBarContainer/VBox/BarBorder/Background/Fill")
@onready var boss_hp_catchup: ColorRect = get_node_or_null("BossBarContainer/VBox/BarBorder/Background/Catchup")

const HP_BAR_MAX_WIDTH: float = 102.0
const ARMOR_BAR_MAX_WIDTH: float = 102.0
const BOSS_BAR_MAX_WIDTH: float = 236.0

var catchup_tween: Tween = null
var armor_catchup_tween: Tween = null
var pulse_tween: Tween = null
var flow_frame_tween: Tween = null
var vitals_frame_tween: Tween = null
var boss_catchup_tween: Tween = null
var vital_shake_tween: Tween = null

var previous_hp: float = 100.0
var previous_armor: float = 27.0
var previous_flow: int = 0

const WEAPON_TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/sliced/weapon_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/sliced/weapon_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/sliced/weapon_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/sliced/weapon_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/sliced/weapon_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/sliced/weapon_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")
}

const ICON_BAG = preload("res://assets/sprites/ui/icon_bag.png")
const ICON_MAP = preload("res://assets/sprites/ui/icon_map.png")

var notify_panel: PanelContainer = null
var notify_label: Label = null
var notify_tween: Tween = null
var bag_btn_glow_tween: Tween = null

func _ready() -> void:
	if boss_bar_container:
		boss_bar_container.visible = false
	if bag_btn:
		bag_btn.icon = ICON_BAG
		bag_btn.expand_icon = true
	if map_btn:
		map_btn.icon = ICON_MAP
		map_btn.expand_icon = true

func _process(delta: float) -> void:
	var t = Time.get_ticks_msec() * 0.001
	
	# 1. Shimmer quét qua thanh máu & giáp tạo hiệu ứng phản quang lấp lánh
	if hp_shimmer and hp_fill and hp_fill.size.x > 0:
		var cycle = fmod(t * 1.6, 2.4)
		if cycle < 1.0:
			hp_shimmer.position.x = cycle * hp_fill.size.x
			hp_shimmer.modulate.a = 0.55 * sin(cycle * PI)
		else:
			hp_shimmer.modulate.a = 0.0

	if armor_shimmer and armor_fill and armor_fill.size.x > 0:
		var cycle_a = fmod(t * 1.9 + 0.6, 2.0)
		if cycle_a < 1.0:
			armor_shimmer.position.x = cycle_a * armor_fill.size.x
			armor_shimmer.modulate.a = 0.65 * sin(cycle_a * PI)
		else:
			armor_shimmer.modulate.a = 0.0

	# 2. Hiệu ứng ngọc Ruby phát sáng xung nhịp theo nhịp tim sinh mệnh (Heartbeat)
	if ruby_gem:
		var hp_ratio: float = clampf(previous_hp / 100.0, 0.0, 1.0)
		# Máu càng thấp thì nhịp tim đập càng gấp gáp và cường độ rung giật càng mạnh
		var pulse_freq = 3.2 if hp_ratio >= 0.3 else 8.0
		var pulse_intensity = 0.08 if hp_ratio >= 0.3 else 0.22
		var gem_pulse = 1.0 + pulse_intensity * sin(t * pulse_freq)
		ruby_gem.scale = Vector2(gem_pulse, gem_pulse)
		if hp_ratio < 0.3:
			ruby_gem.modulate = Color(1.8, 0.4, 0.4, 1.0)
		else:
			ruby_gem.modulate = Color(1.0, 1.0, 1.0, 1.0)

func connect_player(player: Player) -> void:
	if not player:
		return
	player.hp_changed.connect(_on_hp_changed)
	player.armor_changed.connect(_on_armor_changed)
	player.flow_changed.connect(_on_flow_changed)
	player.flasks_changed.connect(_on_flasks_changed)
	player.crystals_changed.connect(_on_crystals_changed)
	player.weapon_equipped.connect(_on_weapon_equipped)
	
	_on_hp_changed(player.current_hp, player.max_hp)
	if "current_armor" in player:
		_on_armor_changed(player.current_armor, player.max_armor)
	_on_flow_changed(player.current_flow, player.is_full_flow())
	_on_flasks_changed(player.life_flasks, player.max_flasks)
	_on_crystals_changed(player.upgrade_crystals)
	
	if player.current_weapon_tier != "":
		_on_weapon_equipped(player.current_weapon_tier, player.base_atk, player.crit_rate)
		
	player.inventory_changed.connect(_on_inventory_changed_for_hints)
	if player.has_signal("merge_ready"):
		player.merge_ready.connect(_on_player_merge_ready)
	_on_inventory_changed_for_hints(player.inventory)
		
	if bag_btn:
		bag_btn.icon = ICON_BAG
		bag_btn.expand_icon = true
		bag_btn.pressed.connect(func():
			var inv = get_parent().get_node_or_null("UI_Layer/InventoryUI")
			if not inv:
				inv = get_tree().root.find_child("InventoryUI", true, false)
			if inv and inv.has_method("toggle_inventory"):
				inv.toggle_inventory()
		)
		
	if map_btn:
		map_btn.icon = ICON_MAP
		map_btn.expand_icon = true
		map_btn.pressed.connect(func():
			var map_ui = get_parent().get_node_or_null("UI_Layer/FastTravelMapUI")
			if not map_ui:
				map_ui = get_tree().root.find_child("FastTravelMapUI", true, false)
			if map_ui and map_ui.has_method("toggle_map"):
				map_ui.toggle_map()
		)

func bind_boss(boss: EnemyBase) -> void:
	if not boss:
		return
	if boss_bar_container:
		boss_bar_container.visible = true
	if boss.has_signal("boss_hp_updated"):
		boss.boss_hp_updated.connect(_on_boss_hp_updated)
	if boss.has_signal("boss_defeated"):
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
		flask_label.text = "[O] Bình: %d/%d" % [current, maximum]

func _on_crystals_changed(count: int) -> void:
	if crystal_label:
		crystal_label.text = "Thạch: %d" % count

func _on_weapon_equipped(tier_name: String, atk: float, _crit: float) -> void:
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
	var is_taking_damage = current < previous_hp
	var is_healing = current > previous_hp
	previous_hp = current
	
	if hp_fill:
		# Hiệu ứng co giãn & đổi màu
		var tw = create_tween()
		tw.tween_property(hp_fill, "size:x", target_width, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		if is_healing:
			# Hiệu ứng hồi máu: Lóe sáng xanh ngọc bích
			var tw_heal = create_tween()
			tw_heal.tween_property(hp_fill, "modulate", Color(0.4, 2.2, 0.8, 1.0), 0.1)
			tw_heal.tween_property(hp_fill, "modulate", Color.WHITE, 0.25)
		elif ratio < 0.3:
			hp_fill.color = Color(1.0, 0.12, 0.12) # Báo động đỏ
		else:
			hp_fill.color = Color(0.92, 0.16, 0.26) # Ruby Huyết Nguyệt

	# Lớp Catch-up vàng kim giật chậm sau đòn đánh (White/Gold Impact Follower)
	if hp_catchup:
		if catchup_tween:
			catchup_tween.kill()
		if is_healing:
			hp_catchup.size.x = target_width
		else:
			catchup_tween = create_tween()
			catchup_tween.tween_interval(0.22)
			catchup_tween.tween_property(hp_catchup, "size:x", target_width, 0.38).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Hiệu ứng Rung lắc & lóe đỏ khung máu Gothic (HUD Impact Shake & Flash) khi trúng sát thương
	if is_taking_damage:
		if vital_panel:
			if vital_shake_tween:
				vital_shake_tween.kill()
			vital_shake_tween = create_tween()
			vital_shake_tween.tween_property(vital_panel, "position:y", 3.0, 0.03)
			vital_shake_tween.tween_property(vital_panel, "position:y", -2.5, 0.03)
			vital_shake_tween.tween_property(vital_panel, "position:y", 1.0, 0.03)
			vital_shake_tween.tween_property(vital_panel, "position:y", 0.0, 0.04)
		if vitals_frame:
			if vitals_frame_tween:
				vitals_frame_tween.kill()
			vitals_frame_tween = create_tween()
			vitals_frame_tween.tween_property(vitals_frame, "modulate", Color(2.0, 0.5, 0.5, 1.0), 0.05)
			vitals_frame_tween.tween_property(vitals_frame, "modulate", Color.WHITE, 0.25)
	elif is_healing and vitals_frame:
		if vitals_frame_tween:
			vitals_frame_tween.kill()
		vitals_frame_tween = create_tween()
		vitals_frame_tween.tween_property(vitals_frame, "modulate", Color(0.6, 2.0, 1.0, 1.0), 0.1)
		vitals_frame_tween.tween_property(vitals_frame, "modulate", Color.WHITE, 0.3)
		
	if hp_label:
		hp_label.text = "HP: %d/%d" % [round(current), round(maximum)]
		if is_taking_damage:
			hp_label.modulate = Color(2.0, 0.4, 0.4)
			var tw_lbl = create_tween()
			tw_lbl.tween_property(hp_label, "modulate", Color.WHITE, 0.2)

func _on_armor_changed(current: float, maximum: float) -> void:
	var ratio := clampf(current / max(1.0, maximum), 0.0, 1.0)
	var target_width := ARMOR_BAR_MAX_WIDTH * ratio
	var is_armor_damaged = current < previous_armor
	var is_armor_refilled = current > previous_armor
	previous_armor = current
	
	if armor_fill:
		var tw = create_tween()
		tw.tween_property(armor_fill, "size:x", target_width, 0.08)
		
		if is_armor_refilled:
			# Hiệu ứng nạp lại đầy giáp (Round Start): Lóe sáng điện quang Cyan rực rỡ
			var tw_recharge = create_tween()
			tw_recharge.tween_property(armor_fill, "modulate", Color(0.8, 2.5, 3.0, 1.0), 0.12)
			tw_recharge.tween_property(armor_fill, "modulate", Color.WHITE, 0.2)
			if vitals_frame:
				var tw_f = create_tween()
				tw_f.tween_property(vitals_frame, "modulate", Color(0.7, 1.8, 2.5, 1.0), 0.12)
				tw_f.tween_property(vitals_frame, "modulate", Color.WHITE, 0.3)
		elif ratio <= 0.0:
			armor_fill.color = Color(0.2, 0.25, 0.35, 0.3)
		elif ratio < 0.3:
			armor_fill.color = Color(1.0, 0.65, 0.2) # Cam cảnh báo giáp sắp vỡ
		else:
			armor_fill.color = Color(0.15, 0.85, 1.0) # Lam Ngọc Cyan phát quang
			
	if armor_catchup:
		if armor_catchup_tween:
			armor_catchup_tween.kill()
		if is_armor_refilled:
			armor_catchup.size.x = target_width
		else:
			armor_catchup_tween = create_tween()
			armor_catchup_tween.tween_interval(0.16)
			armor_catchup_tween.tween_property(armor_catchup, "size:x", target_width, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Hiệu ứng nổ tia xanh khi giáp bị vỡ về 0
	if is_armor_damaged and current <= 0.0:
		if armor_fill:
			var tw_break = create_tween()
			tw_break.tween_property(armor_fill, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.08)
			tw_break.tween_property(armor_fill, "modulate", Color.WHITE, 0.15)
		if vitals_frame:
			var tw_fb = create_tween()
			tw_fb.tween_property(vitals_frame, "modulate", Color(0.5, 1.8, 2.5, 1.0), 0.08)
			tw_fb.tween_property(vitals_frame, "modulate", Color.WHITE, 0.2)
		
	if armor_label:
		armor_label.text = "GIÁP: %d/%d" % [round(current), round(maximum)]

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	var gained_flow = stacks > previous_flow
	previous_flow = stacks

	for i in range(5):
		if i < flow_cells.size():
			var cell = flow_cells[i]
			if i < stacks:
				cell.color = Color(0.0, 0.95, 1.0, 1.0) # Cyan ngọc bích
				# Hiệu ứng nạp khí: Ô mới kích hoạt bừng sáng và nở nhẹ tự nhiên
				if gained_flow and i == stacks - 1:
					var tw_pop = create_tween()
					tw_pop.tween_property(cell, "scale", Vector2(1.12, 1.12), 0.08)
					tw_pop.tween_property(cell, "modulate", Color(2.5, 2.5, 3.0, 1.0), 0.08)
					tw_pop.tween_property(cell, "scale", Vector2.ONE, 0.14)
					tw_pop.tween_property(cell, "modulate", Color.WHITE, 0.14)
			else:
				cell.color = Color(0.08, 0.12, 0.18, 0.45)

	# Hiệu ứng lóe khung Flow khi nạp thêm stack
	if gained_flow and flow_frame and not is_full:
		var tw_ff = create_tween()
		tw_ff.tween_property(flow_frame, "modulate", Color(0.8, 2.0, 2.5, 1.0), 0.08)
		tw_ff.tween_property(flow_frame, "modulate", Color.WHITE, 0.18)

	if is_full:
		if not pulse_tween or not pulse_tween.is_valid():
			pulse_tween = create_tween().set_loops()
			# Hiệu ứng cầu vồng ma thuật xung nhịp toàn bộ 5 ô ngọc và khung Flow
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(2.5, 1.8, 0.5, 1.0), 0.18)
			if flow_frame:
				pulse_tween.parallel().tween_property(flow_frame, "modulate", Color(1.8, 1.5, 0.6, 1.0), 0.18)
			for cell in flow_cells:
				pulse_tween.parallel().tween_property(cell, "modulate", Color(0.3, 2.0, 2.5, 1.0), 0.18)
			if flow_frame:
				pulse_tween.parallel().tween_property(flow_frame, "modulate", Color(0.6, 1.8, 2.5, 1.0), 0.18)
	else:
		if pulse_tween:
			pulse_tween.kill()
		if flow_frame:
			flow_frame.modulate = Color.WHITE

func _setup_bottom_left_notify_box() -> void:
	if notify_panel and is_instance_valid(notify_panel):
		return
		
	notify_panel = PanelContainer.new()
	notify_panel.name = "BottomLeftNotifyPanel"
	notify_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Định vị dưới màn hình góc bên trái (Bottom Left Toast)
	# Màn hình chuẩn: 480x270. Đặt tại offset_left: 10, offset_bottom: -10
	notify_panel.anchors_preset = Control.PRESET_BOTTOM_LEFT
	notify_panel.anchor_left = 0.0
	notify_panel.anchor_right = 0.0
	notify_panel.anchor_top = 1.0
	notify_panel.anchor_bottom = 1.0
	notify_panel.offset_left = 10.0
	notify_panel.offset_top = -42.0
	notify_panel.offset_right = 175.0
	notify_panel.offset_bottom = -10.0
	notify_panel.custom_minimum_size = Vector2(165, 32)
	
	# Phong cách Dark Gothic: Nền thạch anh tối viền vàng đồng sang trọng
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.08, 0.09, 0.13, 0.92)
	style_box.border_color = Color(0.85, 0.72, 0.25, 0.95)
	style_box.set_border_width_all(1)
	style_box.corner_radius_top_left = 3
	style_box.corner_radius_top_right = 3
	style_box.corner_radius_bottom_left = 3
	style_box.corner_radius_bottom_right = 3
	style_box.content_margin_left = 6
	style_box.content_margin_right = 6
	style_box.content_margin_top = 4
	style_box.content_margin_bottom = 4
	notify_panel.add_theme_stylebox_override("panel", style_box)
	
	var hbox = HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)
	
	var icon_rect = TextureRect.new()
	icon_rect.texture = ICON_BAG
	icon_rect.custom_minimum_size = Vector2(16, 16)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_rect)
	
	notify_label = Label.new()
	var font = preload("res://assets/fonts/pixel_font.ttf")
	notify_label.add_theme_font_override("font", font)
	notify_label.add_theme_font_size_override("font_size", 6)
	notify_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	notify_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	notify_label.add_theme_constant_override("outline_size", 2)
	notify_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notify_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(notify_label)
	
	notify_panel.add_child(hbox)
	notify_panel.visible = false
	add_child(notify_panel)

func _on_player_merge_ready(grp_name: String, count: int) -> void:
	# Khung thông báo nhỏ gọn tinh tế ở mép dưới góc bên trái màn hình
	_setup_bottom_left_notify_box()
	if not notify_panel or not notify_label:
		return
		
	notify_label.text = "Đủ %d %s!\n[B] Túi để ghép" % [count, grp_name]
	notify_panel.visible = true
	
	if notify_tween and notify_tween.is_valid():
		notify_tween.kill()
		
	# Animation trượt nhẹ từ dưới lên và mờ dần biến mất
	notify_panel.modulate.a = 0.0
	notify_panel.position = Vector2(10.0, 270.0) # Vị trí ngay mép dưới
	
	notify_tween = create_tween()
	# Slide up nhẹ nhàng vào vị trí (y: 228 -> 270 - 42)
	notify_tween.parallel().tween_property(notify_panel, "position:y", 228.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	notify_tween.parallel().tween_property(notify_panel, "modulate:a", 1.0, 0.22)
	# Giữ lại hiển thị 3.2 giây cho người chơi kịp đọc
	notify_tween.tween_interval(3.2)
	# Fade out & slide down nhẹ
	notify_tween.parallel().tween_property(notify_panel, "modulate:a", 0.0, 0.35)
	notify_tween.parallel().tween_property(notify_panel, "position:y", 240.0, 0.35)
	notify_tween.tween_callback(func():
		if notify_panel:
			notify_panel.visible = false
	)

func _on_inventory_changed_for_hints(inventory: Array[Dictionary]) -> void:
	if not bag_btn:
		return
	var can_merge = MergeSystem.can_merge(inventory)
	if can_merge:
		bag_btn.text = "[B] Túi (!)"
		if not bag_btn_glow_tween or not bag_btn_glow_tween.is_valid():
			bag_btn_glow_tween = create_tween().set_loops()
			bag_btn_glow_tween.tween_property(bag_btn, "modulate", Color(1.8, 1.6, 0.3, 1.0), 0.4)
			bag_btn_glow_tween.tween_property(bag_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
	else:
		bag_btn.text = "[B] Túi"
		if bag_btn_glow_tween:
			bag_btn_glow_tween.kill()
			bag_btn_glow_tween = null
		bag_btn.modulate = Color.WHITE
