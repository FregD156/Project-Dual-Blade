class_name InventoryUI
extends Control

## Giao diện Túi Đồ (Inventory Panel) chuẩn Pixel-Art
## Phím tắt mở/đóng: [B] hoặc [I]
## Hiển thị:
## - Vũ khí đang trang bị & chỉ số ATK, Crit, Dòng Option (Detail.md)
## - Bộ giáp 4 món: Mũ (Helmet), Áo Giáp (Chest), Tay (Arms), Chân (Legs) & Chỉ số Tổng Giáp
## - Lưới ô trang bị (Grid) chứa vũ khí & các mảnh giáp nhặt được
## - Bấm chuột TRÁI để Trang bị | Bấm chuột PHẢI để Phân rã (Salvage) lấy Tinh thể

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

@onready var count_flasks_lbl: Label = $CenterContainer/Panel/Margin/VBox/Footer/FlaskCountLabel
@onready var count_crystals_lbl: Label = $CenterContainer/Panel/Margin/VBox/Footer/CrystalCountLabel
@onready var close_btn: Button = $CenterContainer/Panel/Margin/VBox/Header/CloseBtn

var player_ref: Player = null

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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B or event.keycode == KEY_TAB:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif visible and event.keycode == KEY_ESCAPE:
			toggle_inventory()
			get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	visible = !visible
	if visible:
		refresh_ui()

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

	# 2. Update Armor Equipment Section (Helmet, Chest, Arms, Legs)
	if armor_total_lbl:
		armor_total_lbl.text = "Tổng Giáp: %d / %d (Hồi đầy mỗi round)" % [round(player_ref.current_armor), round(player_ref.max_armor)]

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

	if count_flasks_lbl:
		count_flasks_lbl.text = "Bình: %d/%d" % [player_ref.life_flasks, player_ref.max_flasks]

	if count_crystals_lbl:
		count_crystals_lbl.text = "Thạch: %d" % player_ref.upgrade_crystals

	# 3. Populate Grid Slots (Weapons & Armors in Inventory)
	if not grid_container:
		return

	for child in grid_container.get_children():
		child.queue_free()

	var items = player_ref.inventory
	var slot_count = max(12, ((items.size() + 3) / 4) * 4)

	for i in range(slot_count):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(24, 24)
		btn.focus_mode = Control.FOCUS_NONE

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
			btn.modulate = border_color
			
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
			btn.modulate = Color(0.25, 0.25, 0.25, 0.4)

		grid_container.add_child(btn)

func _equip_item_from_inventory(index: int) -> void:
	if not player_ref or index < 0 or index >= player_ref.inventory.size():
		return
	var item_data = player_ref.inventory[index]
	if item_data.get("type", "") == "armor":
		player_ref.equip_armor_piece(item_data)
	else:
		if player_ref.has_method("equip_weapon_dict"):
			player_ref.equip_weapon_dict(item_data)
		elif player_ref.has_method("equip_weapon_tier"):
			player_ref.equip_weapon_tier(item_data.get("tier", "tier_d"))
	refresh_ui()

func _salvage_item(index: int) -> void:
	if not player_ref:
		return
	player_ref.salvage_weapon(index)
	refresh_ui()
