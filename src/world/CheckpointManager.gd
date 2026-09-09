class_name CheckpointManager
extends RefCounted

## Quản lý Checkpoint, Hồi sinh & Death Penalty (Phần A.VI Detail.md)
## Checkpoint tại X.1, X.5 (sau Elite), X.9 (Safe Haven)
## Giữ 100% trang bị, rơi 50% quặng dạng Bóng Ma Pixel (Echo Shard)

var current_world: int = 1
var current_checkpoint_stage: int = 1 # 1, 5, hoặc 9
var stored_echo_shard_ore: int = 0
var echo_shard_position: Vector2 = Vector2.ZERO
var has_active_echo_shard: bool = false

var player_ore: int = 100
var player_crystals: int = 10

func activate_checkpoint(world: int, stage: int) -> void:
	current_world = world
	current_checkpoint_stage = stage
	print("[CHECKPOINT] Đã lưu tiến trình tại World %d Stage %d!" % [world, stage])

func on_player_death(death_pos: Vector2) -> Dictionary:
	if has_active_echo_shard:
		# Chết lần 2 trước khi nhặt lại -> mất vĩnh viễn số tài nguyên cũ
		print("[DEATH PENALTY] Chết lần 2! Toàn bộ Quặng cũ tan biến vĩnh viễn!")
		stored_echo_shard_ore = 0
		has_active_echo_shard = false
		
	var dropped_ore: int = int(player_ore * 0.5)
	player_ore -= dropped_ore
	stored_echo_shard_ore = dropped_ore
	echo_shard_position = death_pos
	has_active_echo_shard = (dropped_ore > 0)
	
	return {
		"respawn_world": current_world,
		"respawn_stage": current_checkpoint_stage,
		"dropped_ore": dropped_ore,
		"echo_pos": echo_shard_position
	}

func recover_echo_shard() -> int:
	if not has_active_echo_shard:
		return 0
	var recovered := stored_echo_shard_ore
	player_ore += recovered
	stored_echo_shard_ore = 0
	has_active_echo_shard = false
	print("[ECHO RECOVERED] Đã nhặt lại Bóng Ma Pixel! Nhận lại: %d quặng!" % recovered)
	return recovered
