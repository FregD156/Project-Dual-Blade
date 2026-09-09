class_name DamagePopup
extends Marker2D

## Popup hiển thị số sát thương nhảy lên khi đánh trúng (P2 Plan)
@export var float_speed: float = 60.0
@export var lifetime: float = 0.6
var timer: float = 0.0
var label: Label

func _ready() -> void:
	label = Label.new()
	add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func setup(damage_amount: float, is_crit: bool = false) -> void:
	if not label:
		label = Label.new()
		add_child(label)
	label.text = str(round(damage_amount))
	if is_crit:
		label.text += "!"
		label.modulate = Color(1.0, 0.85, 0.1) # Vàng rực chí mạng
		scale = Vector2(1.3, 1.3)
	else:
		label.modulate = Color(1.0, 1.0, 1.0)

func _process(delta: float) -> void:
	position.y -= float_speed * delta
	timer += delta
	modulate.a = 1.0 - (timer / lifetime)
	if timer >= lifetime:
		queue_free()
