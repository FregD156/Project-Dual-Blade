class_name CrossParryHandler
extends RefCounted

## Cross-Parry: Bắt chéo 2 lưỡi đao để đỡ đòn
## Cửa sổ thực hiện: ~0.15s (9-10 frames @ 60fps)
## Thành công: hit-stop 0.1s, lướt sau lưng đối thủ, phản đòn chí mạng

signal parry_started
signal parry_success(enemy: Node)
signal parry_failed

var parry_window: float = 0.15 # 9 frame @ 60fps
var current_parry_timer: float = 0.0
var is_parrying: bool = false
var consecutive_parries: int = 0

func start_parry() -> void:
	is_parrying = true
	current_parry_timer = parry_window
	parry_started.emit()

func update(delta: float) -> void:
	if is_parrying:
		current_parry_timer -= delta
		if current_parry_timer <= 0.0:
			is_parrying = false
			parry_failed.emit()

func try_parry_incoming_attack(incoming_hitbox: Dictionary, enemy_node: Node = null) -> bool:
	if not is_parrying:
		return false
		
	# Nếu đòn đánh có cờ không thể parry (ví dụ đòn búa đỏ của Thủ Lĩnh Đao Phủ)
	if incoming_hitbox.get("is_unparryable", false):
		return false
		
	# Parry thành công!
	is_parrying = false
	current_parry_timer = 0.0
	consecutive_parries += 1
	parry_success.emit(enemy_node)
	return true

func reset_combo() -> void:
	consecutive_parries = 0
