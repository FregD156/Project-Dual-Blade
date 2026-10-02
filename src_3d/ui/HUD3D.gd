class_name HUD3D
extends CanvasLayer

## HUD 3D Gothic Vitals & Flow Meter
## Tích hợp Khung Gothic hoàng gia (vitals_hud_frame, flow_hud_frame, ruby_gem, bag & map icons)
## Hiển thị HP Bar, Armor Bar (Giáp bảo vệ), 5 Nấc Ngọc Ruby Flow và Quản lý Phím Mở Túi Đồ [B] / Bản Đồ [M]

@onready var hp_bar: ProgressBar = get_node_or_null("VitalsPanel/VBoxBars/HPBar")
@onready var armor_bar: ProgressBar = get_node_or_null("VitalsPanel/VBoxBars/ArmorBar")
@onready var hp_label: Label = get_node_or_null("VitalsPanel/VBoxBars/HPBar/HPLabel")
@onready var armor_label: Label = get_node_or_null("VitalsPanel/VBoxBars/ArmorBar/ArmorLabel")

@onready var gems_container: HBoxContainer = get_node_or_null("FlowPanel/RubyGemsContainer")
@onready var state_label: Label = get_node_or_null("FlowPanel/StateLabel")
@onready var bag_btn: Button = get_node_or_null("TopRightButtons/BagButton")
@onready var map_btn: Button = get_node_or_null("TopRightButtons/MapButton")

const RUBY_GEM_TEXTURE = preload("res://assets/sprites/ui/ruby_gem.png")

var player_cached: Node = null

func _ready() -> void:
	if bag_btn:
		bag_btn.pressed.connect(_on_bag_pressed)
	if map_btn:
		map_btn.pressed.connect(_on_map_pressed)
		
	call_deferred("_connect_player")

func _connect_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		player_cached = p
		if p.has_signal("hp_changed"):
			p.hp_changed.connect(_on_hp_changed)
			_on_hp_changed(p.current_hp, p.max_hp)
		if p.has_signal("armor_changed"):
			p.armor_changed.connect(_on_armor_changed)
			_on_armor_changed(p.current_armor, p.max_armor)
		if p.has_signal("flow_changed"):
			p.flow_changed.connect(_on_flow_changed)
			_on_flow_changed(p.current_flow, p.max_flow, p.is_overdrive)
		if p.has_signal("parry_success"):
			p.parry_success.connect(_on_parry_success)
			
		# Kết nối Túi Đồ
		var inv = get_node_or_null("../InventoryUI")
		if inv and inv.has_method("connect_player"):
			inv.connect_player(p)

func _on_hp_changed(curr: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = curr
	if hp_label:
		hp_label.text = "%d / %d" % [int(curr), int(max_v)]

func _on_armor_changed(curr: float, max_v: float) -> void:
	if armor_bar:
		armor_bar.max_value = max(1.0, max_v)
		armor_bar.value = curr
	if armor_label:
		if max_v > 0.0:
			armor_label.text = "GIÁP: %d / %d" % [int(curr), int(max_v)]
		else:
			armor_label.text = "GIÁP: 0"

func _on_flow_changed(curr: int, _max_v: int, is_overdrive: bool) -> void:
	if gems_container:
		var gems = gems_container.get_children()
		for i in range(gems.size()):
			if gems[i] is TextureRect:
				if i < curr:
					gems[i].modulate = Color(2.5, 0.4, 0.6) if is_overdrive else Color(1.0, 1.0, 1.0)
					gems[i].scale = Vector2(1.2, 1.2) if is_overdrive else Vector2(1.0, 1.0)
				else:
					gems[i].modulate = Color(0.2, 0.2, 0.25, 0.4)
					gems[i].scale = Vector2(1.0, 1.0)
					
	if state_label:
		if is_overdrive:
			state_label.text = "⚡ XUẤT QUỶ (OVERDRIVE) ⚡"
			state_label.modulate = Color(1.0, 0.35, 0.5)
		else:
			state_label.text = "FLOW METER (%d/5)" % curr
			state_label.modulate = Color(0.85, 0.9, 1.0)

func _on_parry_success() -> void:
	if state_label:
		state_label.text = "⚔️ CROSS-PARRY HOÀN HẢO! ⚔️"
		state_label.modulate = Color(1.0, 0.95, 0.3)
		var tw = create_tween()
		tw.tween_interval(1.2)
		tw.tween_callback(func():
			if player_cached and "current_flow" in player_cached:
				_on_flow_changed(player_cached.current_flow, player_cached.max_flow, player_cached.is_overdrive)
		)

func _on_bag_pressed() -> void:
	var inv = get_node_or_null("../InventoryUI")
	if inv and inv.has_method("toggle_inventory"):
		inv.toggle_inventory()

func _on_map_pressed() -> void:
	var map_ui = get_node_or_null("../FastTravelMapUI")
	if map_ui and map_ui.has_method("open_map"):
		map_ui.open_map()

func show_boss_bar(b_name: String, b_max_hp: float) -> void:
	var boss_con = get_node_or_null("BossContainer")
	if boss_con:
		boss_con.visible = true
		var name_lbl = boss_con.get_node_or_null("BossNameLabel")
		if name_lbl: name_lbl.text = "👑 " + b_name
		var bar = boss_con.get_node_or_null("BossBar")
		if bar:
			bar.max_value = b_max_hp
			bar.value = b_max_hp

func update_boss_bar(curr: float) -> void:
	var boss_con = get_node_or_null("BossContainer")
	if boss_con:
		var bar = boss_con.get_node_or_null("BossBar")
		if bar:
			bar.value = curr
		if curr <= 0:
			var tw = create_tween()
			tw.tween_interval(1.0)
			tw.tween_property(boss_con, "modulate:a", 0.0, 0.5)
			tw.tween_callback(func(): boss_con.visible = false)

func show_stage_banner(text: String) -> void:
	var banner = get_node_or_null("StageBanner")
	if not banner:
		banner = PanelContainer.new()
		banner.name = "StageBanner"
		banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
		banner.offset_left = -180.0
		banner.offset_right = 180.0
		banner.offset_top = 40.0
		banner.offset_bottom = 75.0
		banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var lbl = Label.new()
		lbl.name = "BannerLabel"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		banner.add_child(lbl)
		add_child(banner)

	var label_node = banner.get_node_or_null("BannerLabel")
	if label_node:
		label_node.text = text
		
	banner.visible = true
	banner.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.2)
	tw.tween_property(banner, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func(): banner.visible = false)

