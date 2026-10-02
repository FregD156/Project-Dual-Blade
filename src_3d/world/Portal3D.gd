class_name Portal3D
extends Area3D

signal portal_entered()

@export var is_active: bool = false
@export var branch_type: int = 0 # 0: Combat, 1: Sustain

@onready var vortex_mesh: MeshInstance3D = $VortexMesh
@onready var portal_light: OmniLight3D = $PortalLight
@onready var prompt_label: Label3D = $PromptLabel

var pulse_time: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	set_active(is_active)

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
		portal_entered.emit()
		# Teleport effect
		if body.has_method("take_damage"):
			var tw = create_tween()
			tw.tween_property(body, "scale", Vector3(0.1, 2.5, 0.1), 0.35)
			tw.parallel().tween_property(body, "modulate:a" if "modulate" in body else "scale", Vector3.ZERO, 0.35)
