extends SceneTree

func _init():
	print("--- TEST AUTO EQUIP & MERGE HINT START ---")
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scn = load("res://scenes/Main.tscn")
	var main_node = main_scn.instantiate()
	root.add_child(main_node)
	
	await process_frame
	
	var player: Player = main_node.get_node("World/Entities/Player")
	var inv_ui: InventoryUI = main_node.get_node("UI_Layer/InventoryUI")
	var game_ui: GameUI = main_node.get_node("UI_Layer")
	
	assert(player != null, "Player missing")
	assert(inv_ui != null, "InventoryUI missing")
	assert(game_ui != null, "GameUI missing")
	
	print("[1] Player khởi đầu tier vũ khí: ", player.current_weapon_tier)
	assert(player.current_weapon_tier == "tier_d", "Initial weapon should be tier_d")
	
	# TEST 1: Thêm 1 món vũ khí Tier B vào kho -> Player phải TỰ ĐỘNG trang bị Tier B vì cao hơn Tier D!
	print("[2] Thêm 1 vũ khí Tier B vào inventory...")
	var weapon_b = {
		"type": "weapon",
		"tier": "tier_b",
		"name": "Song Đao B",
		"options": []
	}
	player.add_to_inventory(weapon_b)
	print("Vũ khí player sau khi nhặt Tier B: ", player.current_weapon_tier)
	assert(player.current_weapon_tier == "tier_b", "Player should auto equip higher tier weapon (tier_b)")
	
	# Thêm 1 món vũ khí Tier C vào kho -> Player KHÔNG bị hạ cấp xuống Tier C mà vẫn giữ Tier B!
	print("[3] Thêm 1 vũ khí Tier C vào inventory (thấp hơn Tier B)...")
	var weapon_c = {
		"type": "weapon",
		"tier": "tier_c",
		"name": "Song Đao C",
		"options": []
	}
	player.add_to_inventory(weapon_c)
	print("Vũ khí player sau khi nhặt Tier C: ", player.current_weapon_tier)
	assert(player.current_weapon_tier == "tier_b", "Player should keep tier_b and not downgrade to tier_c")
	
	# TEST 2: Kiểm tra gợi ý khi gom đủ 5 món cùng loại, cùng tier
	# Thêm 4 món vũ khí Tier C nữa để tổng cộng có 5 món Tier C
	print("[4] Thêm 4 món Tier C nữa để kiểm tra Gợi Ý Ghép 5 món...")
	for i in range(4):
		player.inventory.append({
			"type": "weapon",
			"tier": "tier_c",
			"name": "Song Đao C",
			"options": []
		})
	
	# Gọi cập nhật UI
	inv_ui.refresh_ui()
	
	# Kiểm tra hệ thống nhận diện đủ 5 món
	var can_merge = MergeSystem.can_merge(player.inventory)
	print("Hệ thống phát hiện có thể ghép 5x: ", can_merge)
	assert(can_merge == true, "MergeSystem should detect 5x Tier C merge available")
	
	var ready_groups = MergeSystem.get_merge_ready_groups(player.inventory)
	print("Nhóm sẵn sàng ghép: ", ready_groups[0]["name"], " số lượng: ", ready_groups[0]["count"])
	assert(ready_groups.size() >= 1, "Should have at least 1 merge ready group")
	
	# Kiểm tra banner hiển thị trong InventoryUI
	assert(inv_ui.merge_hint_banner.visible == true, "Merge hint banner should be visible when 5x items ready")
	print("Nội dung banner gợi ý: ", inv_ui.hint_label.text)
	
	# TEST 3: Thực hiện Hợp Thành 5 món Tier C -> 1 món Tier B
	print("[5] Tiến hành bấm Ghép 5x...")
	inv_ui._on_merge_pressed()
	
	# Sau khi ghép, nhóm 5 món Tier C đã hợp thành 1 món Tier B
	assert(MergeSystem.can_merge(player.inventory) == false, "After merge, no 5x group should remain")
	assert(inv_ui.merge_hint_banner.visible == false, "Merge hint banner should hide after merge")
	
	# TEST 4: Ghép 5 món Tier B lên Tier A -> Player phải TỰ ĐỘNG lên Tier A!
	print("[6] Thêm các món Tier B để đủ 5 món Tier B và ghép lên Tier A...")
	for i in range(4):
		player.inventory.append({
			"type": "weapon",
			"tier": "tier_b",
			"name": "Song Đao B",
			"options": []
		})
	inv_ui.refresh_ui()
	assert(MergeSystem.can_merge(player.inventory) == true, "Should detect 5x Tier B ready")
	
	# Nhấn ghép 5x
	inv_ui._on_merge_pressed()
	print("Vũ khí player sau khi ghép lên Tier A: ", player.current_weapon_tier)
	assert(player.current_weapon_tier == "tier_a", "Player should auto-equip newly created higher tier weapon (tier_a)")
	
	# TEST 5: Tự động trang bị cho Mảnh Giáp & Khiên
	print("[7] Thử nghiệm tự động trang bị giáp cao hơn...")
	var armor_chest_r = ArmorSystem.create_armor_item("chest", "tier_r")
	player.add_to_inventory(armor_chest_r)
	print("Áo giáp đang mặc: ", player.equipped_armor["chest"]["tier"])
	assert(player.equipped_armor["chest"]["tier"] == "tier_r", "Player should auto equip Tier R chest armor")
	
	print("--- TẤT CẢ KIỂM THỬ ƯU TIÊN TRANG BỊ CAO NHẤT & GỢI Ý GHÉP ĐÃ VƯỢT QUA 100%! ---")
	quit()
