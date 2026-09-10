class_name InventoryUI
extends Control

## Giao diện Túi Đồ (Inventory Panel) chuẩn Pixel-Art
## Phím tắt mở/đóng: [B] hoặc [I]
## Hiển thị:
## - Vũ khí đang trang bị & chỉ số ATK, Crit, Dòng Option (Detail.md)
## - Lưới ô trang bị (Grid 4x3) chứa vũ khí & vật phẩm nhặt được
## - Bấm chuột TRÁI để Trang bị | Bấm chuột PHẢI để Phân rã (Salvage) lấy Tinh thể

@onready var grid_container: GridContainer = $CenterContainer/Panel/Margin/VBox/Scroll/GridContainer
@onready var equipped_icon: TextureRect = $CenterContainer/Panel/Margin/VBox/EquippedSection/EquippedIcon
@onready var equipped_tier_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/TierLabel
@onready var equipped_atk_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/AtkLabel
@onready var equipped_crit_lbl: Label = $CenterContainer/Panel/Margin/VBox/EquippedSection/VBoxStats/CritLabel
@onready var options_lbl: Label = get_node_or_null("CenterContainer/Panel/Margin/VBox/OptionsLabel")
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
		if event.keycode == KEY_B or event.keycode == KEY_I:
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
	refresh_ui()

func _on_inventory_changed(_items: Array[Dictionary]) -> void:
	if visible:
		refresh_ui()

func _on_weapon_equipped(_tier: String, _atk: float, _crit: float) -> void:
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
			options_lbl.text = "Option: (Chưa có dòng phụ)"
		else:
			var opt_texts = []
			for opt in player_ref.weapon_options:
				opt_texts.append("• " + opt.get("desc", ""))
			options_lbl.text = "Option: " + " | ".join(opt_texts)

	if count_flasks_lbl:
		count_flasks_lbl.text = "Bình: %d/%d" % [player_ref.life_flasks, player_ref.max_flasks]

	if count_crystals_lbl:
		count_crystals_lbl.text = "Thạch: %d" % player_ref.upgrade_crystals

	# 2. Populate Grid Slots
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
			var tier = item_data.get("tier", "tier_d")
			var item_name = item_data.get("name", "Vũ Khí")
			var item_idx = i
			
			if WEAPON_TEXTURES.has(tier):
				btn.icon = WEAPON_TEXTURES[tier]
				btn.expand_icon = true
				
				var tooltip_lines = [item_name]
				var opts = item_data.get("options", [])
				for opt in opts:
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
