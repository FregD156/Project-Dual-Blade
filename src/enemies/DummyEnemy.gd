class_name DummyEnemy
extends CharacterBody2D

## Quái test phục vụ P1 (Core Combat Prototype)
## Có đòn đánh định kỳ để người chơi luyện Cross-Parry (vàng/trắng) hoặc né đòn không thể parry (đỏ)

signal attack_warning_started(is_unparryable: bool)

@export var max_hp: float = 200.0
var current_hp: float = 200.0
var def: float = 2.0 # Mitigation ~ 3.8% với K=50

@export var attack_interval: float = 3.0
var attack_timer: float = 2.0
var is_attacking: bool = false
var is_winding_up: bool = false
var windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.8 # 0.8s báo hiệu trước khi vung đòn (như Boss 1.10)

@onready var visual: Node2D = $Sprite2D if has_node("Sprite2D") else ($AnimSprite if has_node("AnimSprite") else null)
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hp_label: Label = $HPLabel
@onready var status_label: Label = $StatusLabel

var next_attack_unparryable: bool = false

func _ready() -> void:
	current_hp = max_hp
	hurtbox.hit_received.connect(_on_hit_received)
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	_update_labels()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += 900.0 * delta
		move_and_slide()

	if is_winding_up:
		windup_timer -= delta
		if windup_timer <= 0.0:
			_execute_attack()
	elif not is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_start_attack_windup()

func _start_attack_windup() -> void:
	is_winding_up = true
	windup_timer = WINDUP_DURATION
	# Luân phiên đòn thường (parryable) và đòn búa đỏ (unparryable) để test
	next_attack_unparryable = (randf() < 0.3)
	
	if next_attack_unparryable:
		visual.modulate = Color(1.0, 0.2, 0.2) # Báo đỏ: không thể parry!
		status_label.text = "BÁO ĐỎ! (Né Dash!)"
	else:
		visual.modulate = Color(1.0, 0.85, 0.2) # Báo vàng: Parry ngay khi vung!
		status_label.text = "Báo vàng! (Chuẩn bị Parry!)"
		
	attack_warning_started.emit(next_attack_unparryable)

func _execute_attack() -> void:
	is_winding_up = false
	is_attacking = true
	visual.modulate = Color(0.9, 0.1, 0.1) if next_attack_unparryable else Color(1.0, 1.0, 1.0)
	status_label.text = "ATTACKING!"
	
	attack_hitbox.damage = 25.0
	attack_hitbox.is_unparryable = next_attack_unparryable
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	
	# Đòn active trong 0.12s
	await get_tree().create_timer(0.12).timeout
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	is_attacking = false
	attack_timer = attack_interval
	visual.modulate = Color(0.8, 0.3, 0.3)
	status_label.text = "Idle"

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	var result = DamageCalculator.calculate_damage(
		incoming_hitbox.damage,
		incoming_hitbox.skill_mult,
		def,
		0.0,
		50.0,
		incoming_hitbox.is_crit
	)
	var dmg: float = result["damage"]
	current_hp = max(0.0, current_hp - dmg)
	_update_labels()
	
	# Flash trắng khi nhận sát thương
	var original_color = visual.modulate
	visual.modulate = Color(1.5, 1.5, 1.5)
	await get_tree().create_timer(0.05).timeout
	if visual:
		visual.modulate = original_color
	
	if current_hp <= 0:
		# Respawn sau 1s để tiếp tục test
		status_label.text = "Đã gục! Hồi sinh..."
		await get_tree().create_timer(1.0).timeout
		current_hp = max_hp
		_update_labels()

func _update_labels() -> void:
	if hp_label:
		hp_label.text = "HP: %d / %d" % [round(current_hp), round(max_hp)]
