class_name InventoryUI
extends Control

## Giao diện Túi Đồ (Inventory Panel) chuẩn Pixel-Art
## Phím tắt mở/đóng: [B] hoặc [I]
## Hiển thị:
## - Vũ khí đang trang bị & chỉ số ATK, Crit, Dòng Option (Detail.md)
## - Bộ giáp 4 món: Mũ (Helmet), Áo Giáp (Chest), Tay (Arms), Chân (Legs) & Chỉ số Tổng Giáp
## - Lưới ô trang bị (Grid) chứa vũ khí & các mảnh giáp nhặt được
## - Bấm chuột TRÁI để Trang bị | Bấm chuột PHẢI để Phân rã (Salvage) lấy Tinh thể

@onready var panel_container: PanelContainer = $CenterContainer/Panel
@onready var grid_container: GridContainer = $CenterContainer/Panel/Margin/VBox/Scroll/GridContainer
@onready var equipped_icon: TextureRect = $CenterContainer/Panel/Margin/VBox/EquippedSection/EquippedIcon
@onready var equipped_tier_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/TierLabel
@onready var equipped_atk_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/AtkLabel
@onready var equipped_crit_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/CritLabel
@onready var options_lbl: Label = get_node_or_null("CenterContainer/Panel/Margin/VBox/OptionsLabel")

# Armor section labels & icons
@onready var armor_total_lbl: Label = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/ArmorTotalLabel")
@onready var helmet_btn: TextureRect = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/HBox/HelmetSlot/Icon")
@onready var chest_btn: TextureRect = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/HBox/ChestSlot/Icon")
@onready var arms_btn: TextureRect = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/HBox/ArmsSlot/Icon")
@onready var legs_btn: TextureRect = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/HBox/LegsSlot/Icon")
@onready var shield_btn: TextureRect = get_node_or_null("CenterContainer/Panel/Margin/VBox/ArmorSection/HBox/ShieldSlot/Icon")

@onready var count_flasks_lbl: Label = $CenterContainer/Panel/Margin/VBox/Footer/FlaskCountLabel
@onready var count_crystals_lbl: Label = $CenterContainer/Panel/Margin/VBox/Footer/CrystalCountLabel
@onready var merge_btn: Button = get_node_or_null("CenterContainer/Panel/Margin/VBox/Footer/MergeBtn")
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/Header/CloseBtn

var player_ref: Player = null
var open_tween: Tween = null
const ITEM_SLOT_TEXTURE = preload("res://assets/sprites/ui/item_slot_frame.png")

const WEAPON_TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/sliced/weapon_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/sliced/weapon_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/sliced/weapon_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/sliced/weapon_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/sliced/weapon_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/sliced/weapon_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/sliced/weapon_tier_ssr.png")
}

const ARMOR_TEXTURES = {
	"helmet": preload("res://assets/sprites/armor/armor_helmet.png"),
	"chest": preload("res://assets/sprites/armor/armor_chest.png"),
	"arms": preload("res://assets/sprites/armor/armor_arms.png"),
	"legs": preload("res://assets/sprites/armor/armor_legs.png")
}

const SHIELD_TEXTURES = {
	"tier_d": preload("res://assets/sprites/items/shield/shield_tier_d.png"),
	"tier_c": preload("res://assets/sprites/items/shield/shield_tier_c.png"),
	"tier_b": preload("res://assets/sprites/items/shield/shield_tier_b.png"),
	"tier_a": preload("res://assets/sprites/items/shield/shield_tier_a.png"),
	"tier_r": preload("res://assets/sprites/items/shield/shield_tier_r.png"),
	"tier_sr": preload("res://assets/sprites/items/shield/shield_tier_sr.png"),
	"tier_ssr": preload("res://assets/sprites/items/shield/shield_tier_ssr.png")
}

const TIER_COLORS = {
	"tier_d": Color(0.7, 0.7, 0.7),
	"tier_c": Color(1.0, 1.0, 1.0),
	"tier_b": Color(0.2, 1.0, 0.3),
	"tier_a": Color(0.2, 0.6, 1.0),
	"tier_r": Color(0.8, 0.3, 1.0),
	"tier_sr": Color(1.0, 0.85, 0.2),
	"tier_ssr": Color(1.0, 0.3, 0.8)
}

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_btn:
		close_btn.pressed.connect(toggle_inventory)
	if merge_btn:
		merge_btn.pressed.connect(_on_merge_pressed)

func _on_merge_pressed() -> void:
	if not player_ref:
		return
	if player_ref.has_method("check_and_merge_inventory"):
		var merged = player_ref.check_and_merge_inventory()
		refresh_ui()
		# Nút nhấp nháy phản hồi
		if merge_btn:
			var tw = create_tween()
			if merged.size() > 0:
				merge_btn.text = "THÀNH CÔNG!"
				tw.tween_property(merge_btn, "modulate", Color(0.2, 1.0, 0.4), 0.15)
				tw.tween_interval(0.6)
				tw.tween_property(merge_btn, "modulate", Color.WHITE, 0.2)
				tw.tween_callback(func(): if merge_btn: merge_btn.text = "GHÉP (5x)")
			else:
				merge_btn.text = "KHÔNG ĐỦ 5"
				tw.tween_property(merge_btn, "modulate", Color(1.0, 0.4, 0.4), 0.15)
				tw.tween_interval(0.6)
				tw.tween_property(merge_btn, "modulate", Color.WHITE, 0.2)
				tw.tween_callback(func(): if merge_btn: merge_btn.text = "GHÉP (5x)")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B or event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			toggle_inventory()
			get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	if not visible:
		visible = true
		refresh_ui()
		if panel_container:
			panel_container.pivot_offset = panel_container.size * 0.5
			panel_container.scale = Vector2(0.85, 0.85)
			if open_tween:
				open_tween.kill()
			open_tween = create_tween()
			open_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		if panel_container:
			if open_tween:
				open_tween.kill()
			open_tween = create_tween()
			open_tween.tween_property(panel_container, "scale", Vector2(0.88, 0.88), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			open_tween.tween_callback(func():
				visible = false
				if panel_container:
					panel_container.scale = Vector2.ONE
			)
		else:
			visible = false

func connect_player(player: Player) -> void:
	player_ref = player
	if not player_ref:
		return
	if player_ref.has_signal("inventory_changed"):
		player_ref.inventory_changed.connect(_on_inventory_changed)
	if player_ref.has_signal("weapon_equipped"):
		player_ref.weapon_equipped.connect(_on_weapon_equipped)
	if player_ref.has_signal("flasks_changed"):
		player_ref.flasks_changed.connect(_on_flasks_changed)
	if player_ref.has_signal("crystals_changed"):
		player_ref.crystals_changed.connect(_on_crystals_changed)
	if player_ref.has_signal("armor_changed"):
		player_ref.armor_changed.connect(_on_armor_changed)
	if player_ref.has_signal("armor_equipped"):
		player_ref.armor_equipped.connect(_on_armor_equipped)
	if player_ref.has_signal("shield_equipped"):
		player_ref.shield_equipped.connect(_on_shield_equipped)
	refresh_ui()

func _on_shield_equipped(_shield: Dictionary) -> void:
	if visible:
		refresh_ui()

func _on_inventory_changed(_items: Array[Dictionary]) -> void:
	if visible:
		refresh_ui()

func _on_weapon_equipped(_tier: String, _atk: float, _crit: float) -> void:
	if visible:
		refresh_ui()

func _on_armor_changed(_cur: float, _max_val: float) -> void:
	if visible:
		refresh_ui()

func _on_armor_equipped(_equipped: Dictionary) -> void:
	if visible:
		refresh_ui()

func _on_flasks_changed(current: int, maximum: int) -> void:
	if count_flasks_lbl:
		count_flasks_lbl.text = "Bình: %d/%d" % [current, maximum]

func _on_crystals_changed(count: int) -> void:
	if count_crystals_lbl:
		count_crystals_lbl.text = "Thạch: %d" % count

func refresh_ui() -> void:
	if not player_ref or not is_instance_valid(player_ref):
		return
		
	# 1. Update Equipped Weapon Section
	var current_tier = player_ref.current_weapon_tier
	if WEAPON_TEXTURES.has(current_tier) and equipped_icon:
		equipped_icon.texture = WEAPON_TEXTURES[current_tier]
	
	if equipped_tier_lbl:
		var tier_str = current_tier.replace("tier_", "").to_upper()
		equipped_tier_lbl.text = "Song Đao [Bậc %s]" % tier_str
		equipped_tier_lbl.modulate = TIER_COLORS.get(current_tier, Color.WHITE)
		
	if equipped_atk_lbl:
		equipped_atk_lbl.text = "Sát Thương: %d" % round(player_ref.base_atk)
		
	if equipped_crit_lbl:
		equipped_crit_lbl.text = "Chí Mạng: %d%%" % round(player_ref.crit_rate * 100.0)

	if options_lbl:
		if player_ref.weapon_options.size() == 0:
			options_lbl.text = "Option Vũ Khí: (Chưa có dòng phụ)"
		else:
			var opt_texts = []
			for opt in player_ref.weapon_options:
				opt_texts.append("• " + opt.get("desc", ""))
			options_lbl.text = "Option: " + " | ".join(opt_texts)

	# 2. Update Armor & Shield Equipment Section
	if armor_total_lbl:
		var shield_txt = ""
		if not player_ref.equipped_shield.is_empty():
			shield_txt = " | Khiên: %d%% Chặn" % round(player_ref.block_chance * 100.0)
		armor_total_lbl.text = "Tổng Giáp: %d/%d%s (Hồi đầy mỗi round)" % [round(player_ref.current_armor), round(player_ref.max_armor), shield_txt]

	var armor_slots = {
		"helmet": helmet_btn,
		"chest": chest_btn,
		"arms": arms_btn,
		"legs": legs_btn
	}

	for part in armor_slots.keys():
		var icon_rect = armor_slots[part]
		if not icon_rect:
			continue
		var item = player_ref.equipped_armor.get(part, {})
		if not item.is_empty():
			var tier = item.get("tier", "tier_d")
			icon_rect.texture = ARMOR_TEXTURES.get(part, null)
			icon_rect.modulate = TIER_COLORS.get(tier, Color.WHITE)
			var tooltip = "%s [Bậc %s]\nGiáp: +%d" % [item.get("name", ""), tier.replace("tier_", "").to_upper(), item.get("armor_value", 0)]
			for opt in item.get("options", []):
				tooltip += "\n+ " + opt.get("desc", "")
			icon_rect.tooltip_text = tooltip
		else:
			icon_rect.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Hiển thị Khiên Hộ Thân đang trang bị
	if shield_btn:
		var s_item = player_ref.equipped_shield
		if not s_item.is_empty():
			var s_tier = s_item.get("tier", "tier_d")
			shield_btn.texture = SHIELD_TEXTURES.get(s_tier, null)
			shield_btn.modulate = TIER_COLORS.get(s_tier, Color.WHITE)
			var s_tooltip = "%s\nMáu: +%d | Giáp: +%d | Chặn đòn: %d%%" % [
				s_item.get("name", "Khiên"),
				s_item.get("bonus_hp", 0),
				s_item.get("bonus_armor", 0),
				round(player_ref.block_chance * 100.0)
			]
			for opt in s_item.get("options", []):
				s_tooltip += "\n+ " + opt.get("desc", "")
			shield_btn.tooltip_text = s_tooltip
		else:
			shield_btn.modulate = Color(0.3, 0.3, 0.3, 0.5)

	if count_flasks_lbl:
		count_flasks_lbl.text = "Bình: %d/%d" % [player_ref.life_flasks, player_ref.max_flasks]

	if count_crystals_lbl:
		count_crystals_lbl.text = "Thạch: %d" % player_ref.upgrade_crystals

	# 3. Populate Grid Slots (Weapons, Armors, Shields in Inventory)
	if not grid_container:
		return

	for child in grid_container.get_children():
		child.queue_free()

	var items = player_ref.inventory
	var slot_count = max(12, ((items.size() + 3) / 4) * 4)

	for i in range(slot_count):
		var slot_panel = PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(26, 26)
		slot_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Khung viền Gothic cho từng ô item
		var frame_rect = TextureRect.new()
		frame_rect.texture = ITEM_SLOT_TEXTURE
		frame_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		slot_panel.add_child(frame_rect)

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(26, 26)
		btn.focus_mode = Control.FOCUS_NONE
		btn.flat = true

		if i < items.size():
			var item_data = items[i]
			var item_type = item_data.get("type", "weapon")
			var tier = item_data.get("tier", "tier_d")
			var item_name = item_data.get("name", "Trang Bị")
			var item_idx = i
			
			if item_type == "armor":
				var part = item_data.get("part", "chest")
				if ARMOR_TEXTURES.has(part):
					btn.icon = ARMOR_TEXTURES[part]
					btn.expand_icon = true
				var tooltip_lines = [item_name, "Giáp: +%d" % item_data.get("armor_value", 0)]
				for opt in item_data.get("options", []):
					tooltip_lines.append("+ " + opt.get("desc", ""))
				tooltip_lines.append("[Trái]: Mặc Giáp  |  [Phải]: Phân rã (+2 Thạch)")
				btn.tooltip_text = "\n".join(tooltip_lines)
			elif item_type == "shield":
				if SHIELD_TEXTURES.has(tier):
					btn.icon = SHIELD_TEXTURES[tier]
					btn.expand_icon = true
				var tooltip_lines = [
					item_name,
					"Máu: +%d | Giáp: +%d | Chặn: %d%%" % [
						item_data.get("bonus_hp", 0),
						item_data.get("bonus_armor", 0),
						round(item_data.get("block_chance", 0.0) * 100.0)
					]
				]
				for opt in item_data.get("options", []):
					tooltip_lines.append("+ " + opt.get("desc", ""))
				tooltip_lines.append("[Trái]: Cầm Khiên  |  [Phải]: Phân rã (+2 Thạch)")
				btn.tooltip_text = "\n".join(tooltip_lines)
			else:
				if WEAPON_TEXTURES.has(tier):
					btn.icon = WEAPON_TEXTURES[tier]
					btn.expand_icon = true
					var tooltip_lines = [item_name]
					for opt in item_data.get("options", []):
						tooltip_lines.append("+ " + opt.get("desc", ""))
					tooltip_lines.append("[Trái]: Trang bị  |  [Phải]: Phân rã (+2 Thạch)")
					btn.tooltip_text = "\n".join(tooltip_lines)
			
			var border_color = TIER_COLORS.get(tier, Color.WHITE)
			frame_rect.modulate = border_color
			
			# Hiệu ứng phóng to nhẹ khi rê chuột vào (Hover Zoom Animation)
			btn.mouse_entered.connect(func():
				var tw = create_tween()
				tw.tween_property(slot_panel, "scale", Vector2(1.12, 1.12), 0.08)
				tw.tween_property(frame_rect, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.08)
			)
			btn.mouse_exited.connect(func():
				var tw = create_tween()
				tw.tween_property(slot_panel, "scale", Vector2.ONE, 0.08)
				tw.tween_property(frame_rect, "modulate", border_color, 0.08)
			)
			
			# Input handling for Left Click (Equip) and Right Click (Salvage)
			btn.gui_input.connect(func(event: InputEvent):
				if event is InputEventMouseButton and event.pressed:
					if event.button_index == MOUSE_BUTTON_LEFT:
						_equip_item_from_inventory(item_idx)
					elif event.button_index == MOUSE_BUTTON_RIGHT:
						_salvage_item(item_idx)
			)
		else:
			btn.disabled = true
			frame_rect.modulate = Color(0.25, 0.25, 0.25, 0.35)

		slot_panel.pivot_offset = Vector2(13, 13)
		slot_panel.add_child(btn)
		grid_container.add_child(slot_panel)

func _equip_item_from_inventory(index: int) -> void:
	if not player_ref or index < 0 or index >= player_ref.inventory.size():
		return
	var item_data = player_ref.inventory[index]
	var item_type = item_data.get("type", "")
	if item_type == "armor":
		player_ref.equip_armor_piece(item_data)
	elif item_type == "shield":
		player_ref.equip_shield(item_data)
	else:
		if player_ref.has_method("equip_weapon_dict"):
			player_ref.equip_weapon_dict(item_data)
		elif player_ref.has_method("equip_weapon_tier"):
			player_ref.equip_weapon_tier(item_data.get("tier", "tier_d"))
	
	# Hiệu ứng lóe sáng khi trang bị thành công (Equip Pulse)
	if equipped_icon:
		var tw = create_tween()
		tw.tween_property(equipped_icon, "scale", Vector2(1.35, 1.35), 0.08)
		tw.tween_property(equipped_icon, "scale", Vector2.ONE, 0.12)
	refresh_ui()

func _salvage_item(index: int) -> void:
	if not player_ref:
		return
	player_ref.salvage_weapon(index)
	# Hiệu ứng nảy số thạch tím
	if count_crystals_lbl:
		var tw = create_tween()
		tw.tween_property(count_crystals_lbl, "modulate", Color(2.2, 0.6, 2.5, 1.0), 0.08)
		tw.tween_property(count_crystals_lbl, "modulate", Color.WHITE, 0.15)
	refresh_ui()
