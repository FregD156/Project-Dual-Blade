class_name GameUI
extends CanvasLayer

## Giao diện HUD chuẩn thương mại
## Tách biệt hoàn toàn khỏi World Camera, cố định ở mép Canvas

@onready var hp_bar: ProgressBar = $TopContainer/MarginContainer/HBoxContainer/HPContainer/HPProgressBar
@onready var hp_label: Label = $TopContainer/MarginContainer/HBoxContainer/HPContainer/HPLabel
@onready var flow_label: Label = $TopContainer/MarginContainer/HBoxContainer/FlowContainer/FlowLabel
@onready var state_label: Label = $BottomContainer/MarginContainer/VBoxContainer/StateLabel
@onready var guide_label: Label = $BottomContainer/MarginContainer/VBoxContainer/GuideLabel

func connect_player(player: Player) -> void:
	if not player:
		return
	player.hp_changed.connect(_on_hp_changed)
	player.flow_changed.connect(_on_flow_changed)
	player.state_changed.connect(_on_state_changed)
	
	_on_hp_changed(player.current_hp, player.max_hp)
	_on_flow_changed(player.current_flow, false)

func _on_hp_changed(current: float, maximum: float) -> void:
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current
	if hp_label:
		hp_label.text = "HP: %d/%d" % [round(current), round(maximum)]

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	if flow_label:
		var bar := ""
		for i in range(5):
			bar += "■ " if i < stacks else "□ "
		flow_label.text = "FLOW: %s(%d/5)" % [bar, stacks]
		if is_full:
			flow_label.text += " [XUẤT QUỶ: +20% SPD & DMG!]"
			flow_label.modulate = Color(1.0, 0.4, 0.1)
		else:
			flow_label.modulate = Color(0.3, 0.8, 1.0)

func _on_state_changed(s_name: String, is_iframe: bool) -> void:
	if state_label:
		state_label.text = "STATE: %s | I-FRAME: %s" % [s_name, "ON" if is_iframe else "OFF"]
