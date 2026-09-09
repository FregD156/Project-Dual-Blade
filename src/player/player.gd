class_name Player
extends CharacterBody2D

## Player Controller (Project Dual Blade)
## Máy trạng thái hữu hạn (FSM) hoàn chỉnh kèm Input Buffering, Combo 2-hit, 
## Shadow Dash i-frame, Cross-Parry 0.15s, Double Jump & Wall Slide/Jump.

# ------------------------------------------------------------------------------
# 1. ENUM VÀ SIGNALS
# ------------------------------------------------------------------------------
enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK_1,
	ATTACK_2,
	DASH,
	PARRY,
	HURT,
	DEAD
}

signal hp_changed(current_hp: float, max_hp: float)
signal flow_changed(stacks: int, is_full: bool)
signal state_changed(new_state_name: String, is_iframe: bool)

# ------------------------------------------------------------------------------
# 2. THÔNG SỐ VẬT LÝ & DI CHUYỂN
# ------------------------------------------------------------------------------
@export_group("Movement")
@export var move_speed: float = 160.0
@export var acceleration: float = 1200.0
@export var friction: float = 1000.0

@export_group("Jump & Gravity")
@export var jump_velocity: float = -280.0
@export var double_jump_velocity: float = -250.0
@export var wall_jump_velocity: Vector2 = Vector2(180.0, -260.0)
@export var wall_slide_speed: float = 50.0
@export var gravity: float = 850.0

@export_group("Combat Stats")
@export var max_hp: float = 100.0
var current_hp: float = 100.0

# ------------------------------------------------------------------------------
# 3. BIẾN QUẢN LÝ FSM & SKILLS
# ------------------------------------------------------------------------------
var current_state: State = State.IDLE
var can_double_jump: bool = false
var facing_direction: int = 1 # 1: Phải, -1: Trái
var is_iframe: bool = false

# Dash
const DASH_SPEED: float = 340.0
const DASH_DURATION: float = 0.2
var dash_timer: float = 0.0

# Cross-Parry (Cửa sổ 0.15 giây ~ 9 frames)
const PARRY_WINDOW: float = 0.15
var parry_timer: float = 0.0
var is_parrying: bool = false

# Flow Meter (Thanh Cuồng Bạo 5 nấc, 2.5s decay)
const MAX_FLOW: int = 5
const FLOW_DECAY_DURATION: float = 2.5
var current_flow: int = 0
var flow_timer: float = 0.0

# Combo & Input Buffering
var has_buffered_attack: bool = false
const BUFFER_WINDOW: float = 0.25
var buffer_timer: float = 0.0

# Hit-stop
var hit_stop_timer: float = 0.0

# ------------------------------------------------------------------------------
# 4. NODE REFERENCES
# ------------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var hitbox: Hitbox = $Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var push_area: PushArea = $PushArea if has_node("PushArea") else null

# ------------------------------------------------------------------------------
# 5. GODOT ENGINE CALLBACKS
# ------------------------------------------------------------------------------
func _ready() -> void:
	current_hp = max_hp
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("flow_changed", current_flow, false)
	_change_state(State.IDLE)
	
	if hitbox:
		hitbox.hit_landed.connect(_on_attack_landed)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurtbox_hit_received)

func _physics_process(delta: float) -> void:
	# Xử lý hit-stop (đóng băng khung hình khi parry thành công hoặc trúng đòn chí mạng)
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		return

	_update_flow_meter(delta)
	_update_input_buffering(delta)

	match current_state:
		State.IDLE:
			_state_idle(delta)
		State.RUN:
			_state_run(delta)
		State.JUMP:
			_state_jump(delta)
		State.FALL:
			_state_fall(delta)
		State.ATTACK_1:
			_state_attack_1(delta)
		State.ATTACK_2:
			_state_attack_2(delta)
		State.DASH:
			_state_dash(delta)
		State.PARRY:
			_state_parry(delta)
		State.HURT:
			_state_hurt(delta)
		State.DEAD:
			pass

	if push_area:
		var push_vec = push_area.get_push_vector()
		velocity += push_vec * delta

	move_and_slide()
	_update_facing_and_hitbox()

func _state_hurt(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)

# ------------------------------------------------------------------------------
# 6. FSM LOGIC TỪNG TRẠNG THÁI
# ------------------------------------------------------------------------------
func _change_state(new_state: State) -> void:
	current_state = new_state
	is_iframe = (current_state == State.DASH)
	if hurtbox:
		hurtbox.is_invincible = is_iframe

	var state_name: String = str(State.keys()[current_state])
	emit_signal("state_changed", state_name, is_iframe)

	# Chuyển đổi AnimationPlayer tương ứng
	match current_state:
		State.IDLE:
			anim_player.play("idle")
		State.RUN:
			anim_player.play("run")
		State.JUMP:
			anim_player.play("jump")
		State.FALL:
			anim_player.play("fall")
		State.ATTACK_1:
			anim_player.play("attack_1")
			has_buffered_attack = false
		State.ATTACK_2:
			anim_player.play("attack_2")
			has_buffered_attack = false
		State.DASH:
			anim_player.play("dash")
		State.PARRY:
			anim_player.play("parry")
		State.HURT:
			anim_player.play("hurt")
		State.DEAD:
			anim_player.play("dead")

func _state_idle(delta: float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)

	if not is_on_floor():
		_change_state(State.FALL)
		return

	can_double_jump = true

	if Input.is_action_just_pressed("attack"):
		_change_state(State.ATTACK_1)
		return
	if Input.is_action_just_pressed("dash"):
		_start_dash()
		return
	if Input.is_action_just_pressed("parry"):
		_start_parry()
		return
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		_change_state(State.JUMP)
		return

	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		_change_state(State.RUN)

func _state_run(delta: float) -> void:
	_apply_gravity(delta)

	if not is_on_floor():
		_change_state(State.FALL)
		return

	can_double_jump = true

	if Input.is_action_just_pressed("attack"):
		_change_state(State.ATTACK_1)
		return
	if Input.is_action_just_pressed("dash"):
		_start_dash()
		return
	if Input.is_action_just_pressed("parry"):
		_start_parry()
		return
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		_change_state(State.JUMP)
		return

	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		facing_direction = 1 if move_input > 0.0 else -1
		var speed_mult := 1.2 if is_full_flow() else 1.0
		velocity.x = move_toward(velocity.x, move_input * move_speed * speed_mult, acceleration * delta)
	else:
		_apply_friction(delta)
		if abs(velocity.x) < 5.0:
			_change_state(State.IDLE)

func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	_handle_air_horizontal_movement(delta)

	if velocity.y >= 0.0:
		_change_state(State.FALL)
		return

	_check_air_actions()

func _state_fall(delta: float) -> void:
	# Kiểm tra Wall Slide khi trượt tường
	if is_on_wall() and velocity.y > 0.0:
		velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)
		if Input.is_action_just_pressed("jump"):
			var wall_norm := get_wall_normal()
			velocity.x = wall_norm.x * wall_jump_velocity.x
			velocity.y = wall_jump_velocity.y
			facing_direction = 1 if velocity.x > 0.0 else -1
			can_double_jump = true
			_change_state(State.JUMP)
			return
	else:
		_apply_gravity(delta)

	_handle_air_horizontal_movement(delta)

	if is_on_floor():
		_change_state(State.IDLE if velocity.x == 0.0 else State.RUN)
		return

	_check_air_actions()

func _check_air_actions() -> void:
	if Input.is_action_just_pressed("jump") and can_double_jump:
		velocity.y = double_jump_velocity
		can_double_jump = false
		_change_state(State.JUMP)
		return
	if Input.is_action_just_pressed("dash"):
		_start_dash()
		return
	if Input.is_action_just_pressed("attack"):
		_change_state(State.ATTACK_1)
		return

func _handle_air_horizontal_movement(delta: float) -> void:
	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		facing_direction = 1 if move_input > 0.0 else -1
		velocity.x = move_toward(velocity.x, move_input * move_speed, acceleration * 0.7 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.3 * delta)

# ------------------------------------------------------------------------------
# 7. COMBO TẤN CÔNG & INPUT BUFFERING
# ------------------------------------------------------------------------------
func _state_attack_1(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
	
	if Input.is_action_just_pressed("attack"):
		has_buffered_attack = true
		buffer_timer = BUFFER_WINDOW

func _state_attack_2(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)

# Hàm callback được AnimationPlayer gọi khi kết thúc animation chém
func on_attack_animation_finished(attack_name: String) -> void:
	if attack_name == "attack_1":
		if has_buffered_attack:
			has_buffered_attack = false
			velocity.x = facing_direction * 50.0 # Bật nhẹ về phía trước nhát 2
			_change_state(State.ATTACK_2)
		else:
			_change_state(State.IDLE if is_on_floor() else State.FALL)
	elif attack_name == "attack_2":
		_change_state(State.IDLE if is_on_floor() else State.FALL)

# ------------------------------------------------------------------------------
# 8. SHADOW DASH & CROSS-PARRY
# ------------------------------------------------------------------------------
func _start_dash() -> void:
	_change_state(State.DASH)
	dash_timer = DASH_DURATION
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0.0

func _state_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.y = 0.0
	if dash_timer <= 0.0:
		_change_state(State.IDLE if is_on_floor() else State.FALL)

func _start_parry() -> void:
	_change_state(State.PARRY)
	parry_timer = PARRY_WINDOW
	is_parrying = true
	velocity = Vector2.ZERO

func _state_parry(delta: float) -> void:
	parry_timer -= delta
	if parry_timer <= 0.0:
		is_parrying = false
		_change_state(State.IDLE)

func _on_hurtbox_hit_received(incoming_hitbox: Hitbox) -> void:
	# 1. Đang trong khung i-frame (Dash) -> Miễn nhiễm sát thương
	if is_iframe:
		return

	# 2. Đang trong trạng thái Cross-Parry
	if is_parrying:
		if incoming_hitbox.is_unparryable:
			# Đòn báo đỏ không thể đỡ -> dính trọn đòn!
			_take_damage(incoming_hitbox.damage)
		else:
			# PARRY THÀNH CÔNG!
			_on_parry_success(incoming_hitbox.owner)
		return

	# 3. Dính đòn bình thường
	_take_damage(incoming_hitbox.damage)

func _on_parry_success(enemy_node: Node) -> void:
	hit_stop_timer = 0.1 # Khựng hình 0.1s
	parry_timer = 0.0
	is_parrying = false
	
	# Giữ hoặc tăng Flow khi parry thành công
	add_flow(1)
	
	# Dịch chuyển tức thì ra sau lưng đối thủ
	if enemy_node and enemy_node is Node2D:
		var enemy_pos: Vector2 = (enemy_node as Node2D).global_position
		global_position = enemy_pos + Vector2(-facing_direction * 35.0, 0.0)
		
	_change_state(State.IDLE)

func _take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	emit_signal("hp_changed", current_hp, max_hp)
	_reset_flow() # Dính đòn làm mất thanh Cuồng Bạo lập tức
	
	if current_hp <= 0.0:
		_change_state(State.DEAD)
	else:
		_change_state(State.HURT)
		# Khựng đau 0.2s rồi hồi phục
		await get_tree().create_timer(0.2).timeout
		if current_state == State.HURT:
			_change_state(State.IDLE)

# ------------------------------------------------------------------------------
# 9. FLOW METER (THANH CUỒNG BẠO)
# ------------------------------------------------------------------------------
func _update_flow_meter(delta: float) -> void:
	if current_flow > 0:
		flow_timer -= delta
		if flow_timer <= 0.0:
			_reset_flow()

func add_flow(amount: int = 1) -> void:
	current_flow = clampi(current_flow + amount, 0, MAX_FLOW)
	flow_timer = FLOW_DECAY_DURATION
	emit_signal("flow_changed", current_flow, is_full_flow())

func _reset_flow() -> void:
	if current_flow != 0:
		current_flow = 0
		flow_timer = 0.0
		emit_signal("flow_changed", current_flow, false)

func is_full_flow() -> bool:
	return current_flow >= MAX_FLOW

func _on_attack_landed(target) -> void:
	add_flow(1)
	# 1. Kích hoạt Freeze Frame / Hit-Stop đanh thép (0.06s)
	HitStopManager.freeze(get_tree(), 0.06, 0.05)
	
	# 2. Truyền lực đẩy Knockback dồn dập vào kẻ địch theo hướng chém
	if target and target.owner:
		var target_entity = target.owner
		if target_entity.has_method("apply_knockback"):
			target_entity.apply_knockback(Vector2(facing_direction, 0.0), 130.0)

func _update_input_buffering(delta: float) -> void:
	if has_buffered_attack:
		buffer_timer -= delta
		if buffer_timer <= 0.0:
			has_buffered_attack = false

# ------------------------------------------------------------------------------
# 10. TIỆN ÍCH VẬT LÝ & HƯỚNG XOAY
# ------------------------------------------------------------------------------
func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func _apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _update_facing_and_hitbox() -> void:
	if sprite:
		sprite.flip_h = (facing_direction < 0)
	if hitbox:
		# Lật hitbox về phía trước mặt nhân vật
		hitbox.position.x = abs(hitbox.position.x) * facing_direction
