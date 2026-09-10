class_name ArrowProjectile
extends Hitbox

## Đạn mũi tên bay của Cung Thủ (Watchtower Archer) kế thừa Hitbox
## Giúp tương thích hoàn hảo với Hurtbox của Player (gây sát thương, parry, trigger hiệu ứng)
@export var speed: float = 280.0
@export var max_lifetime: float = 3.5

var direction: Vector2 = Vector2.LEFT
var lifetime: float = 0.0
var is_stuck: bool = false
var archer_source: Node = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	super._ready()
	# Layer 8: Enemy Attack (Hitbox), Mask: 4 (Player Hurtbox) + 1 (World Environment)
	collision_layer = 8
	collision_mask = 5 # 4 + 1
	monitoring = true
	monitorable = true
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	rotation = direction.angle()

func setup(p_direction: Vector2, p_damage: float, p_unparryable: bool, p_source: Node = null) -> void:
	direction = p_direction.normalized()
	damage = p_damage
	is_unparryable = p_unparryable
	archer_source = p_source
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if is_stuck:
		return
		
	global_position += direction * speed * delta
	lifetime += delta
	if lifetime >= max_lifetime:
		_dissipate()

func _on_area_entered(area: Area2D) -> void:
	if is_stuck:
		return
	# Khi chạm Hurtbox của Player
	if area is Hurtbox:
		hit_landed.emit.call_deferred(area)
		_hit_target(area.global_position)

func _on_body_entered(body: Node2D) -> void:
	if is_stuck:
		return
	# Nếu chạm vào tường/sàn (World Environment)
	if not (body is Hurtbox):
		_stick_into_surface()

func _hit_target(_hit_pos: Vector2) -> void:
	is_stuck = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.tween_callback(queue_free)

func _stick_into_surface() -> void:
	is_stuck = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _dissipate() -> void:
	is_stuck = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
