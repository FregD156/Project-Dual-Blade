class_name PortalChoiceTrigger
extends Area2D

## Cổng dịch chuyển phân nhánh (Portal Choice)
@export var portal_type: PortalChoiceManager.PortalType = PortalChoiceManager.PortalType.COMBAT
@export var portal_name: String = "Cổng Đao Kiếm"

signal portal_entered(type: PortalChoiceManager.PortalType)

@onready var visual: ColorRect = $Visual
@onready var label: Label = $Label

func setup(type: PortalChoiceManager.PortalType, p_name: String, color: Color) -> void:
	portal_type = type
	portal_name = p_name
	if visual:
		visual.color = color
	if label:
		label.text = portal_name

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		print("[PORTAL] Người chơi đã bước vào: %s!" % portal_name)
		portal_entered.emit(portal_type)
