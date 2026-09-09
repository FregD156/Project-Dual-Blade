class_name FlowMeter
extends RefCounted

## FlowMeter: Thanh Cuồng Bạo (5 nấc)
## +1 nấc / đòn trúng, reset về 0 nếu không đánh hoặc dính đòn sau decay_time (2.5s)
## Full Flow (5 nấc): +20% move speed, +20% dmg, after-image VFX + bonus dmg (35%)

signal flow_changed(current_flow: int, is_full: bool)
signal full_flow_entered
signal full_flow_exited

var max_flow: int = 5
var current_flow: int = 0
var decay_timer: float = 0.0
var decay_duration: float = 2.5
var flow_preserve_on_parry: bool = true

func update(delta: float) -> void:
	if current_flow > 0:
		decay_timer -= delta
		if decay_timer <= 0.0:
			reset_flow()

func add_flow(amount: int = 1) -> void:
	var was_full: bool = is_full_flow()
	current_flow = clampi(current_flow + amount, 0, max_flow)
	decay_timer = decay_duration # reset timer 2.5s
	flow_changed.emit(current_flow, is_full_flow())
	
	if not was_full and is_full_flow():
		full_flow_entered.emit()

func on_hit_taken() -> void:
	# Nếu dính đòn (mà không phải parry thành công), mất sạch Flow
	reset_flow()

func on_parry_success() -> void:
	# Config option theo Phần D.VI: giữ flow khi parry thành công
	if flow_preserve_on_parry:
		decay_timer = decay_duration # refresh timer thay vì mất flow

func reset_flow() -> void:
	var was_full: bool = is_full_flow()
	if current_flow != 0:
		current_flow = 0
		decay_timer = 0.0
		flow_changed.emit(current_flow, false)
		if was_full:
			full_flow_exited.emit()

func is_full_flow() -> bool:
	return current_flow >= max_flow

func get_damage_multiplier() -> float:
	return 1.20 if is_full_flow() else 1.0

func get_speed_multiplier() -> float:
	return 1.20 if is_full_flow() else 1.0
