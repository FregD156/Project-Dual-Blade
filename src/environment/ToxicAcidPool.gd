class_name ToxicAcidPool
extends Area2D

## Vũng Axit Ăn Mòn (Toxic Acid Pool - detail.md V.2)
## - Rút máu định kỳ của thực thể đứng trong vũng (Dot Damage: 6 sát thương / 0.5s)
## - Bọt khí axit xanh lá sủi bọt

@export var tick_damage: float = 6.0
@export var tick_interval: float = 0.5

@onready var acid_visual: ColorRect = $AcidVisual
@onready var acid_bubbles: ColorRect = $AcidVisual/AcidBubbles

var tick_timer: float = 0.0
var targets_in_acid: Array[Node2D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player CharacterBody2D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	# Hoạt họa axit nhấp nhô & sủi bọt
	if acid_bubbles:
		var wave = sin(Time.get_ticks_msec() * 0.008) * 2.0
		acid_bubbles.position.x = wave

	if targets_in_acid.size() > 0:
		tick_timer -= delta
		if tick_timer <= 0.0:
			tick_timer = tick_interval
			_apply_acid_damage()

func _on_body_entered(body: Node2D) -> void:
	if body is Player and not (body in targets_in_acid):
		targets_in_acid.append(body)
		tick_timer = 0.1 # Kích hoạt giật sát thương nhanh

func _on_body_exited(body: Node2D) -> void:
	if body in targets_in_acid:
		targets_in_acid.erase(body)

func _apply_acid_damage() -> void:
	for target in targets_in_acid:
		if is_instance_valid(target) and target.has_method("_take_damage"):
			target._take_damage(tick_damage)
			# Hiệu ứng đổi màu xanh lá ăn mòn trên người nhân vật
			if "sprite" in target and target.sprite:
				var tw = create_tween()
				tw.tween_property(target.sprite, "modulate", Color(0.4, 1.5, 0.4, 1.0), 0.08)
				tw.tween_property(target.sprite, "modulate", Color.WHITE, 0.15)
