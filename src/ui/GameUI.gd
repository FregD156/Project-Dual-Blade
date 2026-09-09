class_name GameUI
extends CanvasLayer

## Giao diện HUD chuẩn Pixel-Art 16-bit
## Thiết kế khung viền bevel giả 8-bit sắc nét, không bo góc mềm
## Ghim cố định ở góc trên trái, không đè lên gameplay area

@onready var hp_fill: ColorRect = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/Background/Fill
@onready var hp_label: Label = $TopContainer/MarginContainer/HBoxContainer/HPPanel/Border/HPText
@onready var flow_label: Label = $TopContainer/MarginContainer/HBoxContainer/FlowPanel/Border/FlowText

const HP_BAR_MAX_WIDTH: float = 120.0

func connect_player(player: Player) -> void:
	if not player:
		return
	player.hp_changed.connect(_on_hp_changed)
	player.flow_changed.connect(_on_flow_changed)
	
	_on_hp_changed(player.current_hp, player.max_hp)
	_on_flow_changed(player.current_flow, false)

func _on_hp_changed(current: float, maximum: float) -> void:
	var ratio := clampf(current / max(1.0, maximum), 0.0, 1.0)
	if hp_fill:
		hp_fill.custom_minimum_size.x = HP_BAR_MAX_WIDTH * ratio
		hp_fill.size.x = HP_BAR_MAX_WIDTH * ratio
		# Màu máu: Đỏ tươi khi > 30%, Đỏ thẫm nhấp nháy khi < 30%
		if ratio < 0.3:
			hp_fill.color = Color(0.9, 0.15, 0.15)
		else:
			hp_fill.color = Color(0.85, 0.25, 0.25)
	if hp_label:
		hp_label.text = "%d / %d" % [round(current), round(maximum)]

func _on_flow_changed(stacks: int, is_full: bool) -> void:
	if flow_label:
		var bar := ""
		for i in range(5):
			bar += "■ " if i < stacks else "□ "
		flow_label.text = "FLOW  %s" % bar
		if is_full:
			flow_label.text += " [XUẤT QUỶ]"
			flow_label.modulate = Color(1.0, 0.45, 0.1)
		else:
			flow_label.modulate = Color(0.3, 0.85, 1.0)
