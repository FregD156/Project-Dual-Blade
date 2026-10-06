extends SceneTree

const SpawnPoint3D = preload("res://src_3d/world/SpawnPoint3D.gd")
const PlayerStart3D = preload("res://src_3d/world/PlayerStart3D.gd")
const StageManager3D = preload("res://src_3d/combat/StageManager3D.gd")
const EnemyBase3D = preload("res://src_3d/enemies/EnemyBase3D.gd")

func _init() -> void:
	print("==================================================")
	print("=== RUNNING MILESTONE 1 VERIFICATION TEST SUITE ==")
	print("==================================================")
	
	var root_scn = load("res://scenes_3d/World1_Bastion_3D.tscn").instantiate()
	root.add_child(root_scn)
	
	await process_frame
	await process_frame
	
	var stage_mgr = root_scn.get_node_or_null("StageManager3D")
	var player = root_scn.get_node_or_null("Player3D")
	assert(stage_mgr != null, "StageManager3D must exist in World1!")
	assert(player != null, "Player3D must exist in World1!")
	
	var space_state = root_scn.get_world_3d().direct_space_state
	
	# ==================================================
	# [Test 1] Mục G: Kiểm tra PlayerStart ở đầu Map
	# ==================================================
	print("\n[Test 1] Kiểm tra PlayerStart ở đầu Map (Mục G):")
	var p_starts = get_nodes_in_group("player_start")
	assert(p_starts.size() > 0, "Phải có node thuộc group 'player_start'!")
	var player_start = p_starts[0]
	assert(player_start is PlayerStart3D, "Node phải thuộc class PlayerStart3D!")
	assert(is_equal_approx(player_start.global_position.x, -10.0), "PlayerStart phải ở X = -10.0!")
	assert(is_equal_approx(player_start.global_position.z, 0.0), "PlayerStart phải khóa Z = 0.0!")
	
	var valid_spawn = player_start.get_valid_spawn_position(space_state)
	print(" - PlayerStart base: %s -> Valid on floor: %s" % [player_start.global_position, valid_spawn])
	assert(valid_spawn.y >= 0.0, "Điểm spawn của người chơi phải ở trên sàn!")
	assert(is_equal_approx(valid_spawn.z, 0.0), "Điểm spawn của người chơi phải khóa Z = 0.0!")
	assert(is_equal_approx(player.global_position.x, valid_spawn.x), "Player3D phải xuất hiện tại vị trí PlayerStart!")
	
	# ==================================================
	# [Test 2] Mục I: Kiểm tra Collider chân cầu thang (Dạng nêm liền mạch)
	# ==================================================
	print("\n[Test 2] Kiểm tra Collider cầu thang dạng nêm dốc liền mạch (Mục I):")
	var stage_geom = root_scn.get_node_or_null("StageGeometry")
	assert(stage_geom != null, "StageGeometry must exist!")
	
	var ramp_left = stage_geom.get_node_or_null("StairsRampLeft")
	var ramp_right = stage_geom.get_node_or_null("StairsRampRight")
	assert(ramp_left != null, "StairsRampLeft must exist!")
	assert(ramp_right != null, "StairsRampRight must exist!")
	
	var stairs_left_sp = stage_geom.get_node_or_null("StairsLeft")
	assert(stairs_left_sp != null, "StairsLeft sprite must exist!")
	assert(is_equal_approx(stairs_left_sp.transform.origin.z, 0.08), "StairsLeft Sprite3D phải ở Z = 0.08!")
	
	# Kiểm tra raycast dọc theo dốc cầu thang để xác nhận không có hố, không có bậc khựng
	var test_points_x = [-10.5, -9.5, -8.5, -7.5, -6.5, -6.0]
	var prev_hit_y = -1.0
	for tx in test_points_x:
		var ray_from = Vector3(tx, 5.0, 0.0)
		var ray_to = Vector3(tx, -2.0, 0.0)
		var ray_query = PhysicsRayQueryParameters3D.create(ray_from, ray_to, 1)
		var hit = space_state.intersect_ray(ray_query)
		assert(not hit.is_empty(), "Phải chạm sàn/dốc cầu thang tại X = %.1f!" % tx)
		print(" - Raycast bậc thang tại X = %.1f -> Y = %.2f" % [tx, hit.position.y])
		if prev_hit_y >= 0.0:
			assert(hit.position.y >= prev_hit_y - 0.05, "Độ cao cầu thang phải tăng dần liên tục, không được tụt hố!")
		prev_hit_y = hit.position.y
	print(" -> Cầu thang dạng nêm liền mạch đạt chuẩn: không hố sâu, không khựng bước!")

	# ==================================================
	# [Test 3] Mục D: Kiểm tra SpawnPoints theo tầng
	# ==================================================
	print("\n[Test 3] Kiểm tra SpawnPoints theo tầng (Mục D):")
	var sps = get_nodes_in_group("spawn_points")
	assert(sps.size() >= 10, "Phải có ít nhất 10 SpawnPoint3D!")
	for sp in sps:
		var val = sp.validate_location(space_state)
		assert(val["valid"], "SpawnPoint %s phải hợp lệ trên địa hình!" % sp.name)
		assert(is_equal_approx(sp.global_position.z, 0.0), "SpawnPoint %s phải khóa Z = 0!" % sp.name)
	print(" - Tất cả %d SpawnPoints đều hợp lệ trên sàn và khóa Z = 0." % sps.size())
	
	# ==================================================
	# [Test 4] Mục I: Kiểm tra Chống mất quái & Logging
	# ==================================================
	print("\n[Test 4] Kiểm tra Chống mất quái & Logging chẩn đoán (Mục I):")
	assert(stage_mgr.active_enemies.size() > 0, "Ải 1.1 phải có quái vật sinh ra!")
	var test_enemy: EnemyBase3D = stage_mgr.active_enemies[0]
	# Giả lập quái rơi qua sàn (Y = -4.5)
	test_enemy.global_position.y = -4.5
	stage_mgr._check_active_enemies_watchdog()
	print(" - Sau khi rơi Y=-4.5, vị trí hồi phục: ", test_enemy.global_position)
	assert(test_enemy.global_position.y >= -0.5, "Quái vật phải được phục hồi về sàn!")
	assert(test_enemy.is_dead == false, "Quái vật KHÔNG được xóa tùy tiện khi bị rơi/kẹt!")
	
	# ==================================================
	# [Test 5] Mục I.8: Kiểm tra Debug Overlay (F3)
	# ==================================================
	print("\n[Test 5] Kiểm tra Debug Overlay F3 (Mục I.8):")
	stage_mgr._toggle_spawn_debug(true)
	assert(stage_mgr._debug_hud_layer != null, "CanvasLayer debug HUD phải được tạo!")
	assert(stage_mgr._debug_hud_layer.visible == true, "Debug HUD phải hiển thị khi bật F3!")
	stage_mgr._toggle_spawn_debug(false)
	assert(stage_mgr._debug_hud_layer.visible == false, "Debug HUD phải ẩn khi tắt F3!")
	print(" - F3 Debug HUD hoạt động chính xác.")
	
	# ==================================================
	# [Test 6] Kiểm tra Vượt ải & Mở cổng
	# ==================================================
	print("\n[Test 6] Tiêu diệt quái và kiểm tra cổng qua ải:")
	for e in stage_mgr.active_enemies.duplicate():
		e.die("test_clear")
	await process_frame
	await process_frame
	assert(stage_mgr.active_portals.size() > 0, "Cổng phải mở sau khi diệt hết quái!")
	print(" - Cổng đã mở thành công, số lượng cổng: ", stage_mgr.active_portals.size())
	
	print("\n==================================================")
	print("=== MILESTONE 1 VERIFICATION 100% PASSED! ========")
	print("==================================================")
	quit()
