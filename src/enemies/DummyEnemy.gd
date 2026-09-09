class_name DummyEnemy
extends CharacterBody2D

## Quái test phục vụ P1 (Core Combat Prototype) & Boss Telegraphing System
## Tích hợp:
## 1. Icon Telegraph trực quan thay thế text thô (Báo Vàng Parry Star / Báo Đỏ Danger Eye)
## 2. Hit-flash shader / Modulate flash sắc nét
## 3. Knockback vật lý phản hồi khi bị chém
## 4. PushArea tự tách va chạm mềm (Soft Separation) chống đứng chồng đè

signal attack_warning_started(is_unparryable: bool)

@export var max_hp: float = 200.0
var current_hp: float = 200.0
var def: float = 2.0 # Mitigation ~ 3.8% với K=50

@export var attack_interval: float = 3.0
var attack_timer: float = 2.0
var is_attacking: bool = false
var is_winding_up: bool = false
var windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.8 # 0.8s báo hiệu trước khi vung đòn

@onready var visual: Node2D = $Sprite2D if has_node("Sprite2D") else ($AnimSprite if has_node("AnimSprite") else null)
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hp_label: Label = $FloatingUI/HPLabel if has_node("FloatingUI/HPLabel") else ($HPLabel if has_node("HPLabel") else null)
@onready var status_label: Label = $FloatingUI/StatusLabel if has_node("FloatingUI/StatusLabel") else ($StatusLabel if has_node("StatusLabel") else null)
@onready var hp_fill: ColorRect = $FloatingUI/HPBarBorder/HPBarFill if has_node("FloatingUI/HPBarBorder/HPBarFill") else null
@onready var telegraph_icon: Sprite2D = $FloatingUI/TelegraphIcon if has_node("FloatingUI/TelegraphIcon") else null
@onready var push_area: PushArea = $PushArea if has_node("PushArea") else null

var next_attack_unparryable: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

# Preload visual telegraph icons
const ICON_PARRY = preload("res://assets/sprites/vfx/telegraph_parry_star.png")
const ICON_DANGER = preload("res://assets/sprites/vfx/telegraph_danger_eye.png")

func _ready() -> void:
	current_hp = max_hp
	hurtbox.hit_received.connect(_on_hit_received)
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	if telegraph_icon:
		telegraph_icon.visible = false
	if status_label:
		status_label.text = "" # Bỏ hẳn text cảnh báo thô, chỉ dùng icon pixel art chuẩn
	_update_labels()

func _physics_process(delta: float) -> void:
	# Trọng lực sàn
	if not is_on_floor():
		velocity.y += 900.0 * delta

	# Giảm dần vận tốc knockback
	if knockback_velocity.length_squared() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity.x = knockback_velocity.x
	else:
		velocity.x = 0.0

	# Đẩy nhẹ (Soft Separation) khi nhân vật/quái đứng lồng vào nhau
	if push_area:
		var push_vec = push_area.get_push_vector()
		velocity += push_vec * delta

	move_and_slide()

	# Quản lý nhịp tấn công & chuẩn bị đòn (Windup)
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
	
	# Luân phiên đòn thường (có thể Parry) và đòn búa vung đỏ (không thể Parry - buộc phải Dash né)
	next_attack_unparryable = (randf() < 0.3)
	
	_show_telegraph_icon(next_attack_unparryable)
	attack_warning_started.emit(next_attack_unparryable)

func _show_telegraph_icon(unparryable: bool) -> void:
	if not telegraph_icon:
		return
		
	telegraph_icon.texture = ICON_DANGER if unparryable else ICON_PARRY
	telegraph_icon.visible = true
	telegraph_icon.scale = Vector2(0.3, 0.3)
	telegraph_icon.modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	# Tween hiệu ứng nảy icon và phát sáng mượt mà trên đỉnh đầu
	var tween = create_tween().set_parallel(true)
	tween.tween_property(telegraph_icon, "scale", Vector2(1.2, 1.2), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(telegraph_icon, "modulate:a", 1.0, 0.1)
	
	# Thu nhẹ về kích thước gốc 1:1 pixel
	var seq = create_tween()
	seq.tween_interval(0.15)
	seq.tween_property(telegraph_icon, "scale", Vector2(1.0, 1.0), 0.1)

func _hide_telegraph_icon() -> void:
	if not telegraph_icon:
		return
	var tween = create_tween()
	tween.tween_property(telegraph_icon, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): telegraph_icon.visible = false)

func _execute_attack() -> void:
	is_winding_up = false
	is_attacking = true
	_hide_telegraph_icon()
	
	attack_hitbox.damage = 25.0
	attack_hitbox.is_unparryable = next_attack_unparryable
	attack_hitbox.monitoring = true
	attack_hitbox.monitorable = true
	
	# Thời gian duy trì hitbox tấn công
	await get_tree().create_timer(0.12).timeout
	attack_hitbox.monitoring = false
	attack_hitbox.monitorable = false
	is_attacking = false
	attack_timer = attack_interval

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
	
	# 1. Áp dụng phản lực Knockback lùi về sau hướng tấn công
	var attack_dir = Vector2.RIGHT
	if incoming_hitbox.owner and incoming_hitbox.owner is Node2D:
		attack_dir = (global_position - (incoming_hitbox.owner as Node2D).global_position).normalized()
	if incoming_hitbox.knockback_force != Vector2.ZERO:
		knockback_velocity = incoming_hitbox.knockback_force
	else:
		knockback_velocity = Vector2(sign(attack_dir.x) if sign(attack_dir.x) != 0 else 1.0, 0.0) * 110.0

	# 2. Hit-flash shader / Modulate flash đanh thép (0.07s)
	if visual:
		var mat = visual.material
		if mat is ShaderMaterial:
			mat.set_shader_parameter("flash_active", true)
			mat.set_shader_parameter("flash_color", Color(1.0, 1.0, 1.0, 1.0))
			await get_tree().create_timer(0.07).timeout
			mat.set_shader_parameter("flash_active", false)
		else:
			visual.modulate = Color(2.5, 2.5, 2.5, 1.0)
			await get_tree().create_timer(0.07).timeout
			if visual:
				visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	if current_hp <= 0:
		_hide_telegraph_icon()
		if status_label:
			status_label.text = "KO!"
		await get_tree().create_timer(1.2).timeout
		current_hp = max_hp
		if status_label:
			status_label.text = ""
		_update_labels()

func apply_knockback(dir: Vector2, force: float = 120.0) -> void:
	knockback_velocity = dir.normalized() * force

func _update_labels() -> void:
	if hp_label:
		hp_label.text = "%d/%d" % [round(current_hp), round(max_hp)]
	if hp_fill:
		var ratio := clampf(current_hp / max(1.0, max_hp), 0.0, 1.0)
		hp_fill.size.x = 32.0 * ratio
