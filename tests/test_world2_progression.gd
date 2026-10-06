extends SceneTree

func _init() -> void:
	print("--- TEST WORLD 2 STAGE PROGRESSION (2.1 -> 2.10) ---")
	var root_scn = load("res://scenes_3d/World2_Crimson_Catacombs_3D.tscn").instantiate()
	root.add_child(root_scn)
	
	await process_frame
	await process_frame
	
	var stage_mgr: StageManager3D = root_scn.get_node_or_null("StageManager3D")
	var player = root_scn.get_node_or_null("Player3D")
	
	for s in range(1, 11):
		print("\n--- Testing Stage 2.%d ---" % s)
		print("Current stage: 2.", stage_mgr.current_stage)
		print("Active enemies: ", stage_mgr.active_enemies.size())
		
		# If enemies exist, defeat them
		if stage_mgr.active_enemies.size() > 0:
			var enemies = stage_mgr.active_enemies.duplicate()
			for e in enemies:
				e.die()
			await process_frame
			await process_frame
		
		# Check portals
		print("Active portals: ", stage_mgr.active_portals.size())
		for p in stage_mgr.active_portals:
			print(" - Portal: type=", p.branch_type, " pos=", p.global_position)
			
		assert(stage_mgr.active_portals.size() > 0, "No portal spawned in stage 2.%d!" % s)
		
		# Step into first portal
		var p0 = stage_mgr.active_portals[0]
		p0._on_body_entered(player)
		await process_frame
		await process_frame
	
	print("\n=== SUCCESS: All World 2 stages 2.1 -> 2.10 portals and transitions work perfectly! ===")
	quit()
