class_name DebugCombatOverlay
extends CanvasLayer

## Debug Overlay theo P0 & P1
## Hiển thị: Flow Meter (5 nấc), Parry Window, i-frame status, Frame counter, Player State

@onready var flow_label: Label = $FlowLabel
@onready var parry_label: Label = $ParryLabel
@onready var state_label: Label = $StateLabel
@onready var instruction_label: Label = $InstructionLabel

var player: PlayerController = null

func setup(target_player: PlayerController) -> void:
	player = target_player
	if player and player.flow_meter:
		player.flow_meter.flow_changed.connect(_on_flow_changed)

func _process(_delta: float) -> void:
	if not player:
		return
		
	var state_name: String = str(PlayerController.State.keys()[player.current_state])
	state_label.text = "Player State: %s | Facing: %s | i-frame: %s" % [
		state_name,
		"RIGHT" if player.facing_direction > 0 else "LEFT",
		str(player.is_iframe)
	]
	
	if player.parry_handler:
		if player.parry_handler.is_parrying:
			parry_label.text = "PARRY ACTIVE! (Window: %.2fs)" % player.parry_handler.current_parry_timer
			parry_label.modulate = Color(0.2, 1.0, 0.2)
		else:
			parry_label.text = "Parry: Ready (K)"
			parry_label.modulate = Color(1.0, 1.0, 1.0)

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	var bar := ""
	for i in range(5):
		bar += "[■]" if i < stacks else "[ ]"
	flow_label.text = "FLOW METER: %s (%d/5)%s" % [bar, stacks, " [FULL FLOW: +20% SPD/DMG!]" if is_full else ""]
	flow_label.modulate = Color(1.0, 0.4, 0.2) if is_full else Color(0.4, 0.8, 1.0)
