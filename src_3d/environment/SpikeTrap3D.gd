class_name SpikeTrap3D
extends Area3D

## Bẫy chông gai đá Gothic 3D (Spike Trap 3D HD)
## Tự động kích hoạt khi người chơi giẫm vào: bật chông hắc diện thạch, gây sát thương, sau đó thu hồi.

@export var damage: float = 16.0
@export var retracted_texture: Texture2D = preload("res://assets/sprites/environment/props/gothic_spike_retracted_hd.png")
@export var extended_texture: Texture2D = preload("res://assets/sprites/environment/props/gothic_spike_extended_hd.png")

@onready var sprite: Sprite3D = $Sprite3D
var cooldown_timer: float = 0.0
var is_extended: bool = false
var retract_delay: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite and retracted_texture:
		sprite.texture = retracted_texture

func _physics_process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	
	if is_extended:
		retract_delay -= delta
		if retract_delay <= 0.0:
			retract_spikes()

func _on_body_entered(body: Node3D) -> void:
	if cooldown_timer <= 0.0 and body.is_in_group("player"):
		trigger_spikes(body)

func trigger_spikes(player: Node3D) -> void:
	is_extended = true
	retract_delay = 0.55
	cooldown_timer = 0.85
	
	if sprite and extended_texture:
		sprite.texture = extended_texture
		# Hiệu ứng nảy gai lên
		var orig_y: float = 0.45
		var tw: Tween = create_tween()
		tw.tween_property(sprite, "position:y", orig_y + 0.1, 0.05)
		tw.tween_property(sprite, "position:y", orig_y, 0.08)
	
	if player.has_method("take_damage"):
		player.take_damage(damage, global_position)

func retract_spikes() -> void:
	is_extended = false
	if sprite and retracted_texture:
		sprite.texture = retracted_texture
