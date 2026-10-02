class_name Portal3D
extends Area3D

## Portal 3D Hoàng Gia theo detail.md IV.2
## Hỗ trợ 3 loại cổng:
## - 0: Cổng Chuẩn (Standard Portal - X.4, X.8, X.9, X.10)
## - 1: Cổng Đao Kiếm (Combat Portal - Quái dày, rơi phôi rèn)
## - 2: Cổng Sinh Mệnh (Sustain Portal - Ít quái, chứa bình máu & hạt sinh mệnh)

signal portal_chosen(branch_type: int)

enum PortalType { STANDARD = 0, COMBAT = 1, SUSTAIN = 2 }

@export var is_active: bool = false
@export var branch_type: PortalType = PortalType.STANDARD

@onready var portal_light: OmniLight3D = $PortalLight
@onready var prompt_label: Label3D = $PromptLabel
@onready var vortex_node: Node = get_node_or_null("VortexSprite") if get_node_or_null("VortexSprite") else get_node_or_null("VortexMesh")

var pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	apply_branch_visual()
	set_active(is_active)

func setup(p_branch: PortalType) -> void:
	branch_type = p_branch
	apply_branch_visual()

func apply_branch_visual() -> void:
	if not is_node_ready():
		return
	match branch_type:
		PortalType.COMBAT:
			if portal_light:
				portal_light.light_color = Color(1.0, 0.25, 0.35)
			if prompt_label:
				prompt_label.text = "⚔️ CỔNG ĐAO KIẾM (Quái đông, Rơi nhiều Vũ Khí)"
				prompt_label.modulate = Color(1.0, 0.4, 0.5)
		PortalType.SUSTAIN:
			if portal_light:
				portal_light.light_color = Color(0.2, 1.0, 0.5)
			if prompt_label:
				prompt_label.text = "❤️ CỔNG SINH MỆNH (Bình Máu & Hạt Sinh Mệnh)"
				prompt_label.modulate = Color(0.3, 1.2, 0.6)
		PortalType.STANDARD:
			if portal_light:
				portal_light.light_color = Color(0.3, 0.8, 1.0)
			if prompt_label:
				prompt_label.text = "🌀 CỔNG DỊCH CHUYỂN HOÀNG GIA"
				prompt_label.modulate = Color(0.5, 0.9, 1.0)

func _process(delta: float) -> void:
	if not is_active:
		return
	pulse_time += delta * 3.0
	if portal_light:
		portal_light.light_energy = 2.5 + sin(pulse_time) * 0.8

func set_active(active: bool) -> void:
	is_active = active
	visible = active
	monitoring = active
	if prompt_label:
		prompt_label.visible = active

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body.is_in_group("player"):
		portal_chosen.emit(int(branch_type))
		if body.has_method("take_damage"):
			var tw = create_tween()
			tw.tween_property(body, "scale", Vector3(0.1, 2.5, 0.1), 0.25)
			tw.tween_property(body, "scale", Vector3.ONE, 0.15)
