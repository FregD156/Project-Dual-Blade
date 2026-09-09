class_name TestHarnessController
extends Node2D

@onready var player: PlayerController = $Player
@onready var dummy: DummyEnemy = $DummyEnemy
@onready var overlay: DebugCombatOverlay = $DebugOverlay

func _ready() -> void:
	if overlay and player:
		overlay.setup(player)
		
	# Kết nối sự kiện chém trúng dummy để tăng Flow Meter
	if player and player.hitbox:
		player.hitbox.hit_landed.connect(func(_target):
			player.flow_meter.add_flow(1)
		)
		
	# Kết nối đòn đánh của Dummy tới Player
	if dummy and dummy.attack_hitbox and player:
		dummy.attack_hitbox.hit_landed.connect(func(_target):
			# Kiểm tra xem player có đang trong trạng thái Parry không
			var hitbox_info = {
				"is_unparryable": dummy.attack_hitbox.is_unparryable,
				"damage": dummy.attack_hitbox.damage
			}
			if player.parry_handler.try_parry_incoming_attack(hitbox_info, dummy):
				print("[COMBAT LOG] >>> CROSS-PARRY THÀNH CÔNG! Hit-stop kích hoạt! Dịch chuyển sau lưng!")
			elif not player.is_iframe:
				print("[COMBAT LOG] >>> PLAYER DÍNH ĐÒN! Mất Flow Meter!")
				player.flow_meter.on_hit_taken()
			else:
				print("[COMBAT LOG] >>> JUST-DODGE THÀNH CÔNG! (Né trong i-frame)")
		)
