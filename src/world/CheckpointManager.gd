class_name CheckpointManager
extends RefCounted

## Quản lý Checkpoint, Hồi sinh, Fast Travel & Chọn Map (Phần A.VI Detail.md)
## Checkpoint tại X.1, X.5 (sau Elite), X.9 (Safe Haven)
## Dịch chuyển nhanh (Fast Travel / Map Select) mở khóa các trạm Checkpoint đã đi qua hoặc sau khi hạ Boss
## Giữ 100% trang bị, rơi 50% quặng dạng Bóng Ma Pixel (Echo Shard)

static var instance: CheckpointManager = null

static func get_instance() -> CheckpointManager:
	if instance == null:
		instance = CheckpointManager.new()
	return instance

var current_world: int = 1
var current_checkpoint_stage: int = 1 # 1, 5, hoặc 9
var stored_echo_shard_ore: int = 0
var echo_shard_position: Vector2 = Vector2.ZERO
var has_active_echo_shard: bool = false

# Danh sách Checkpoint đã mở khóa: Array[Dictionary]
# Mỗi phần tử: {"world": int, "stage": int, "name": String}
var unlocked_checkpoints: Array[Dictionary] = [
	{"world": 1, "stage": 1, "name": "1.1 Cổ Thành Khởi Đầu"}
]

var player_ore: int = 100
var player_crystals: int = 10

func activate_checkpoint(world: int, stage: int) -> void:
	current_world = world
	current_checkpoint_stage = stage
	_register_checkpoint(world, stage)
	print("[CHECKPOINT] Đã kích hoạt & lưu mốc tại World %d Stage %d!" % [world, stage])

func _register_checkpoint(world: int, stage: int) -> void:
	for cp in unlocked_checkpoints:
		if cp["world"] == world and cp["stage"] == stage:
			return
	var name_str = "%d.%d %s" % [world, stage, get_checkpoint_name(world, stage)]
	unlocked_checkpoints.append({"world": world, "stage": stage, "name": name_str})

func unlock_all_checkpoints() -> void:
	for w in range(1, 5):
		for st in [1, 5, 9, 10]:
			_register_checkpoint(w, st)
	print("[CHECKPOINT] ĐÃ MỞ KHÓA TOÀN BỘ CÁC MỐC MAP & WORLD!")

func is_all_unlocked() -> bool:
	return unlocked_checkpoints.size() >= 16

func is_checkpoint_unlocked(world: int, stage: int) -> bool:
	for cp in unlocked_checkpoints:
		if cp["world"] == world and cp["stage"] == stage:
			return true
	return false

func get_checkpoint_name(world: int, stage: int) -> String:
	match world:
		1:
			match stage:
				1: return "Cổ Thành Khởi Đầu"
				5: return "Tháp Đao Phủ (Elite)"
				9: return "Trạm Nghỉ Safe Haven"
				10: return "Sàn Đấu Thống Lĩnh Thiết Vệ"
				_: return "Ải %d.%d" % [world, stage]
		2:
			match stage:
				1: return "Hầm Ngục Huyết Rễ"
				5: return "Cổ Thụ Biến Dị (Elite)"
				9: return "Trạm Nghỉ Thầy Lang Điên"
				10: return "Hang Ổ Mẫu Thể Ký Sinh"
				_: return "Ải %d.%d" % [world, stage]
		3:
			match stage:
				1: return "Tháp Đồng Hồ Cơ Giới"
				5: return "Cỗ Máy Hộ Vệ Lõi (Elite)"
				9: return "Trạm Nghỉ Kỹ Sư Sao Chép"
				10: return "Kẻ Hành Quyết Cơ Giới"
				_: return "Ải %d.%d" % [world, stage]
		4:
			match stage:
				1: return "Đền Thờ Hư Vô"
				5: return "Chiến Binh Ảo Ảnh (Elite)"
				9: return "Gương Phản Chiếu Bản Ngã"
				10: return "Kẻ Thao Túng Hư Không"
				_: return "Ải %d.%d" % [world, stage]
		_:
			return "Ải %d.%d" % [world, stage]

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
