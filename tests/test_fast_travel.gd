extends SceneTree

func _init():
	print("--- TEST FAST TRAVEL START ---")
	call_deferred("_run_test")

func _run_test() -> void:
	var main_scn = load("res://scenes_3d/World1_Bastion_3D.tscn")
	var main_node = main_scn.instantiate()
	root.add_child(main_node)
	
	# Đợi 2 frames để các node con và _ready() hoàn tất
	await process_frame
	await process_frame
	
	var stage_mgr = main_node.get_node("StageManager3D")
	var map_ui = main_node.get_node("FastTravelMapUI")
	var player = main_node.get_node("Player3D")
	
	assert(stage_mgr != null, "StageManager3D missing")
	assert(map_ui != null, "FastTravelMapUI missing")
	assert(player != null, "Player3D missing")
	
	print("[1] Initial world: ", stage_mgr.current_world, " stage: ", stage_mgr.current_stage)
	
	# Open map
	map_ui.open_map()
	assert(map_ui.visible == true, "Map should be visible")
	print("[2] Map opened successfully!")
	
	# Unlock all checkpoints for test
	CheckpointManager.get_instance().unlock_all_checkpoints()
	assert(CheckpointManager.get_instance().is_checkpoint_unlocked(2, 1) == true, "World 2 Stage 1 should be unlocked")
	assert(CheckpointManager.get_instance().is_checkpoint_unlocked(3, 5) == true, "World 3 Stage 5 should be unlocked")
	assert(CheckpointManager.get_instance().is_checkpoint_unlocked(4, 10) == true, "World 4 Stage 10 should be unlocked")
	print("[3] Checkpoints unlocked!")
	
	# Fast travel to World 1 Stage 5 (Elite Boss)
	map_ui._on_checkpoint_clicked(1, 5)
	await process_frame
	print("[4] Fast traveled to World 1 Stage 5. Current world: ", stage_mgr.current_world, " stage: ", stage_mgr.current_stage)
	assert(stage_mgr.current_world == 1, "World should be 1")
	assert(stage_mgr.current_stage == 5, "Stage should be 5")
	
	# Fast travel to World 1 Stage 10 (Boss)
	map_ui._on_checkpoint_clicked(1, 10)
	await process_frame
	print("[5] Fast traveled to World 1 Stage 10. Current world: ", stage_mgr.current_world, " stage: ", stage_mgr.current_stage)
	assert(stage_mgr.current_world == 1, "World should be 1")
	assert(stage_mgr.current_stage == 10, "Stage should be 10")
	
	print("--- TEST FAST TRAVEL PASSED SUCCESSFULLY ---")
	quit()
