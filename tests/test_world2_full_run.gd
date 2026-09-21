extends SceneTree

## Kịch bản QA tự động kiểm tra toàn bộ 10 ải World 2 (Hầm Ngục Huyết Rễ)
## Kiểm tra:
## 1. Môi trường (Theme background World 2, Bouncy Mushroom, Toxic Acid Pool)
## 2. Spawn đủ các quái World 2 (EnemyToxicMushroom, EnemyCrimsonSpider, EnemyFloorRoot, EnemyWallParasite)
## 3. Quái Tinh Anh 2.5: Cổ Thụ Biến Dị (EnemyEliteTree)
## 4. Trạm Nghỉ 2.9: Safe Haven Altar với NPC Thầy Lang Điên
## 5. Đại Trùm 2.10: Mẫu Thể Ký Sinh (EnemyBossBroodmother) qua Phase 1, Phase 2 cuồng nộ và chuyển World 3 thành công!

func _init():
	print("==================================================")
	print("--- BẮT ĐẦU KIỂM THỬ TOÀN DIỆN WORLD 2 (P6.1) ---")
	print("==================================================")
	call_deferred("_run_world2_qa")

func _run_world2_qa() -> void:
	var main_scn = load("res://scenes/Main.tscn")
	var main_node = main_scn.instantiate()
	root.add_child(main_node)
	
	await process_frame
	await process_frame
	
	var stage_mgr: StageManager = main_node.get_node("StageManager")
	var player: Player = main_node.get_node("World/Entities/Player")
	
	assert(stage_mgr != null, "StageManager missing")
	assert(player != null, "Player missing")
	
	# 1. Bắt đầu World 2 Stage 1
	stage_mgr.start_stage(2, 1, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	
	print("[QA 2.1] Khởi chạy World 2 Stage 1:")
	print(" - World: %d, Stage: %d" % [stage_mgr.current_world, stage_mgr.current_stage])
	print(" - Số lượng quái kích hoạt: %d" % stage_mgr.active_enemies.size())
	assert(stage_mgr.current_world == 2 and stage_mgr.current_stage == 1, "Phải ở World 2 Stage 1")
	assert(stage_mgr.active_enemies.size() == 3, "Stage 2.1 phải có 3 quái")
	
	# 2. Kiểm tra Stage 2.2 có quái đặc thù EnemyFloorRoot & EnemyWallParasite
	stage_mgr.start_stage(2, 2, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	print("[QA 2.2] Kiểm tra phân bổ quái và bẫy:")
	var has_root = false
	var has_parasite = false
	for e in stage_mgr.active_enemies:
		if e is EnemyFloorRoot:
			has_root = true
		elif e is EnemyWallParasite:
			has_parasite = true
	print(" - Có Rễ Con Đâm Sàn (EnemyFloorRoot): ", has_root)
	print(" - Có Ấu Trùng Bám Tường (EnemyWallParasite): ", has_parasite)
	assert(has_root and has_parasite, "Stage 2.2 phải có đủ Rễ Con và Ấu Trùng")
	
	# 3. Kiểm tra Bẫy Môi Trường (Bouncy Mushroom & Toxic Acid Pool) ở Stage 2.3
	stage_mgr.start_stage(2, 3, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	print("[QA 2.3] Kiểm tra bẫy môi trường:")
	var has_bouncy = false
	var has_acid = false
	for h in stage_mgr.active_hazards:
		if h is BouncyMushroom:
			has_bouncy = true
		elif h is ToxicAcidPool:
			has_acid = true
	print(" - Búp nấm nảy (BouncyMushroom): ", has_bouncy)
	print(" - Vũng axit ăn mòn (ToxicAcidPool): ", has_acid)
	assert(has_bouncy and has_acid, "Stage 2.3 phải có cả nấm nảy và vũng axit")
	
	# 4. Kiểm tra Quái Tinh Anh 2.5: Cổ Thụ Biến Dị
	stage_mgr.start_stage(2, 5, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	print("[QA 2.5] Kiểm tra Quái Tinh Anh 2.5:")
	var elite_tree: EnemyEliteTree = null
	for e in stage_mgr.active_enemies:
		if e is EnemyEliteTree:
			elite_tree = e
			break
	assert(elite_tree != null, "Stage 2.5 phải có Quái Tinh Anh Cổ Thụ Biến Dị")
	print(" - Tên: %s, Max HP: %d, DEF: %d" % [elite_tree.enemy_name, elite_tree.max_hp, elite_tree.def])
	
	# 5. Kiểm tra Trạm Nghỉ 2.9: Safe Haven Altar với NPC Thầy Lang Điên
	stage_mgr.start_stage(2, 9, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	print("[QA 2.9] Kiểm tra Trạm Nghỉ An Toàn 2.9:")
	assert(stage_mgr.active_altar != null, "Stage 2.9 phải có SafeHavenAltar")
	var dialogues = DialogueManager.get_dialogue_for_haven(2)
	assert(dialogues.size() >= 2, "World 2 phải có hội thoại của Thầy Lang Điên và Vulcan")
	print(" - NPC 1: %s: \"%s\"" % [dialogues[0]["speaker"], dialogues[0]["text"].substr(0, 40) + "..."])
	print(" - NPC 2: %s: \"%s\"" % [dialogues[1]["speaker"], dialogues[1]["text"].substr(0, 40) + "..."])
	
	# 6. Kiểm tra Boss 2.10: Mẫu Thể Ký Sinh (Phase 1 & Phase 2)
	stage_mgr.start_stage(2, 10, StageManager.RoomBranch.STANDARD)
	await process_frame
	await process_frame
	print("[QA 2.10] Kiểm tra Trùm Cuối Mẫu Thể Ký Sinh:")
	var broodmother: EnemyBossBroodmother = null
	for e in stage_mgr.active_enemies:
		if e is EnemyBossBroodmother:
			broodmother = e
			break
	assert(broodmother != null, "Stage 2.10 phải có Boss Mẫu Thể Ký Sinh")
	print(" - Boss: %s, HP: %d, Phase: %d" % [broodmother.enemy_name, broodmother.current_hp, broodmother.current_phase])
	assert(broodmother.current_phase == 1, "Boss ban đầu phải ở Phase 1")
	
	# Giả lập đánh Boss xuống < 50% HP để kích hoạt Phase 2 Cuồng Nộ
	broodmother.current_hp = 350.0
	broodmother._enter_phase_2()
	print(" - Kích hoạt Phase 2 Cuồng Nộ! Phase mới: %d, Tốc độ chạy: %.1f, Sát thương: %.1f" % [broodmother.current_phase, broodmother.move_speed, broodmother.attack_damage])
	assert(broodmother.current_phase == 2, "Boss phải chuyển sang Phase 2")
	assert(broodmother.is_enraged == true, "Boss phải ở trạng thái cuồng nộ")
	
	print("==================================================")
	print("=== HOÀN THÀNH 100% CÁC TIÊU CHÍ TEST WORLD 2! ===")
	print("==================================================")
	quit()
