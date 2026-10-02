class_name HUD3D
extends CanvasLayer

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPContainer/HPBar
@onready var flow_container: HBoxContainer = $MarginContainer/VBoxContainer/FlowContainer
@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if p.has_signal("hp_changed"):
			p.hp_changed.connect(_on_hp_changed)
		if p.has_signal("flow_changed"):
			p.flow_changed.connect(_on_flow_changed)
		if p.has_signal("parry_success"):
			p.parry_success.connect(_on_parry_success)

func _on_hp_changed(curr: float, max_v: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_v
		hp_bar.value = curr

func _on_flow_changed(curr: int, _max_v: int, is_overdrive: bool) -> void:
	if not flow_container:
		return
	var slots = flow_container.get_children()
	for i in range(slots.size()):
		if slots[i] is ColorRect:
			if i < curr:
				slots[i].color = Color(1.0, 0.2, 0.4) if is_overdrive else Color(0.2, 0.8, 1.0)
			else:
				slots[i].color = Color(0.2, 0.25, 0.35, 0.5)
				
	if state_label:
		if is_overdrive:
			state_label.text = "⚡ XUẤT QUỶ (OVERDRIVE) ⚡"
			state_label.modulate = Color(1.0, 0.3, 0.5)
		else:
			state_label.text = "FLOW: %d/5" % curr
			state_label.modulate = Color(0.7, 0.9, 1.0)

func _on_parry_success() -> void:
	if state_label:
		state_label.text = "⚔️ CROSS-PARRY THÀNH CÔNG! ⚔️"
		state_label.modulate = Color(1.0, 0.9, 0.2)
