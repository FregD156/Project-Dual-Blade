class_name Player3D
extends CharacterBody3D

## Player 2.5D: Project Dual Blade (Khóa trục Z)
## Thiết kế theo detail.md Phần A:
## - Flow Meter 5 nấc & Trạng thái Xuất Quỷ (After-images)
## - Combo 4 nhát Song Đao
## - Shadow Dash xuyên thấu + Khung bất tử
## - Cross-Parry (0.15s window, Freeze frame + Phản kích)
## - Blade Dance (Vũ điệu bão kiếm)
## - Không chiến (Double jump, Air combo float, Spinning dive)

signal hp_changed(current: float, max_hp: float)
signal flow_changed(current_flow: int, max_flow: int, is_overflow: bool)
signal parry_success()
signal player_died()

const GhostTrail3D = preload("res://src_3d/vfx/GhostTrail3D.gd")
const DamageNumber3D = preload("res://src_3d/vfx/DamageNumber3D.gd")

@export_group("Stats")
@export var max_hp: float = 100.0
@export var current_hp: float = 100.0
@export var base_atk: float = 25.0
@export var move_speed: float = 6.5
@export var jump_force: float = 11.5
@export var gravity: float = 28.0

@export_group("Flow System")
@export var max_flow: int = 5
var current_flow: int = 0
var flow_decay_timer: float = 0.0
const FLOW_DECAY_DELAY: float = 2.5
var is_overdrive: bool = false # Trạng thái Xuất Quỷ

# Movement & State
var facing_direction: int = 1 # 1 = phải (+X), -1 = trái (-X)
var jump_count: int = 0
var max_jumps: int = 2
var is_dashing: bool = false
var dash_timer: float = 0.0
const DASH_DURATION: float = 0.22
const DASH_SPEED: float = 16.0
var dash_cooldown_timer: float = 0.0
const DASH_COOLDOWN: float = 0.55
var is_invulnerable: bool = false

# Combat States
enum State { IDLE, RUN, JUMP, FALL, ATTACK, DIVE, PARRY, BLADE_DANCE, HURT, DEAD }
var current_state: State = State.IDLE

var combo_index: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.65
var attack_busy_timer: float = 0.0

var is_parrying: bool = false
var parry_timer: float = 0.0
const PARRY_WINDOW: float = 0.16

# Nodes
@onready var visual_root: Node3D = $VisualRoot
@onready var attack_area: Area3D = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var parry_shield_fx: Node3D = get_node_or_null("VisualRoot/ParryShieldFX")

func _ready() -> void:
	current_hp = max_hp
	flow_changed.emit(current_flow, max_flow, is_overdrive)
	hp_changed.emit(current_hp, max_hp)
	if attack_area:
		attack_area.monitoring = false

func _physics_process(delta: float) -> void:
	# Khóa cứng trục Z = 0 cho chuẩn 2.5D
	global_position.z = 0.0
	
	_update_timers(delta)
	
	if current_state == State.DEAD:
		_apply_gravity(delta)
		move_and_slide()
		return
		
	match current_state:
		State.IDLE, State.RUN, State.JUMP, State.FALL:
			_handle_movement(delta)
			_handle_combat_inputs()
		State.ATTACK:
			_process_attack_state(delta)
		State.DIVE:
			_process_dive_state(delta)
		State.PARRY:
			_process_parry_state(delta)
		State.BLADE_DANCE:
			_process_blade_dance(delta)
			
	move_and_slide()
	
	# Luôn ép velocity.z = 0
	velocity.z = 0.0
	global_position.z = 0.0
	
	_update_facing()
	_update_ghost_trails(delta)

var trail_timer: float = 0.0

func _update_ghost_trails(delta: float) -> void:
	if is_dashing or (is_overdrive and velocity.length() > 2.0):
		trail_timer -= delta
		if trail_timer <= 0.0:
			trail_timer = 0.04 if is_dashing else 0.08
			_spawn_ghost_trail()

func _spawn_ghost_trail() -> void:
	if not visual_root or not get_parent():
		return
	var trail = GhostTrail3D.new()
	get_parent().add_child(trail)
	var tint = Color(1.0, 0.25, 0.45, 0.65) if is_overdrive else Color(0.25, 0.7, 1.0, 0.6)
	trail.setup(visual_root, tint, 0.28)

func _update_timers(delta: float) -> void:
	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta
		
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_index = 0
			
	if current_flow > 0:
		flow_decay_timer -= delta
		if flow_decay_timer <= 0.0:
			_reset_flow()

func _handle_movement(delta: float) -> void:
	# Trọng lực
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y < 0:
			current_state = State.FALL
	else:
		jump_count = 0
		if velocity.y <= 0:
			velocity.y = 0.0
			
	# Input di chuyển
	var input_x = Input.get_axis("move_left", "move_right")
	var speed = move_speed * (1.2 if is_overdrive else 1.0)
	
	# Bám tường trượt chậm (Wall Slide theo detail.md II.2)
	var is_wall_sliding = false
	if is_on_wall_only() and velocity.y < 0 and input_x != 0:
		is_wall_sliding = true
		velocity.y = max(velocity.y, -3.2)
		jump_count = 0
	
	if input_x != 0:
		velocity.x = input_x * speed
		facing_direction = 1 if input_x > 0 else -1
		if is_on_floor():
			current_state = State.RUN
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
		if is_on_floor():
			current_state = State.IDLE
			
	# Nhảy / Nhảy đúp / Đạp tường nhảy cao (Wall Jump)
	if Input.is_action_just_pressed("jump"):
		if is_wall_sliding:
			var wall_norm = get_wall_normal()
			velocity.x = wall_norm.x * move_speed * 1.35
			velocity.y = jump_force * 1.08
			facing_direction = 1 if wall_norm.x > 0 else -1
			jump_count = 1
			_play_anim("Jump")
		elif jump_count < max_jumps:
			velocity.y = jump_force * (0.9 if jump_count > 0 else 1.0)
			jump_count += 1
			current_state = State.JUMP
			_play_anim("Jump" if jump_count == 1 else "DoubleJump")
		
	# Shadow Dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0.0:
		_start_shadow_dash()

func _handle_combat_inputs() -> void:
	# Đánh thường Combo
	if Input.is_action_just_pressed("attack"):
		if not is_on_floor() and Input.is_action_pressed("move_down"):
			_start_spinning_dive()
		else:
			_start_attack_combo()
		return
		
	# Cross-Parry
	if Input.is_action_just_pressed("parry"):
		_start_cross_parry()
		return
		
	# Blade Dance (Yêu cầu đầy Flow)
	if Input.is_action_just_pressed("blade_dance"):
		if current_flow >= max_flow:
			_start_blade_dance()
		return

func _start_attack_combo() -> void:
	current_state = State.ATTACK
	combo_index = (combo_index % 4) + 1
	combo_timer = COMBO_WINDOW
	
	# Air float (giữ lơ lửng trên không 0.25s)
	if not is_on_floor():
		velocity.y = max(velocity.y, 1.5)
		
	# Lướt nhẹ tới trước
	velocity.x = facing_direction * (2.8 if combo_index < 4 else 4.2)
	attack_busy_timer = 0.28
	
	_trigger_hitbox(true)
	_play_anim("Attack" + str(combo_index))
	_spawn_slash_vfx(combo_index)

func _process_attack_state(delta: float) -> void:
	attack_busy_timer -= delta
	velocity.x = move_toward(velocity.x, 0, 12.0 * delta)
	if not is_on_floor():
		velocity.y -= gravity * 0.4 * delta # Trọng lực nhẹ khi chém trên không
		
	if attack_busy_timer <= 0.0:
		_trigger_hitbox(false)
		current_state = State.IDLE if is_on_floor() else State.FALL

func _start_spinning_dive() -> void:
	current_state = State.DIVE
	velocity.x = 0
	velocity.y = -18.0
	_trigger_hitbox(true)
	_play_anim("SpinningDive")

func _process_dive_state(delta: float) -> void:
	velocity.y = -22.0
	if is_on_floor():
		_trigger_hitbox(false)
		current_state = State.IDLE
		_play_anim("DiveLand")
		_create_screen_shake(0.2)

func _start_cross_parry() -> void:
	current_state = State.PARRY
	is_parrying = true
	parry_timer = PARRY_WINDOW
	velocity.x = 0
	_play_anim("CrossParry")
	if parry_shield_fx:
		parry_shield_fx.visible = true

func _process_parry_state(delta: float) -> void:
	parry_timer -= delta
	if parry_timer <= 0.0:
		is_parrying = false
		if parry_shield_fx:
			parry_shield_fx.visible = false
		current_state = State.IDLE

func trigger_parry_counter(attacker_pos: Vector3) -> void:
	# Thành công: Hit-stop, biến ra sau lưng kẻ địch và phản đòn
	is_parrying = false
	if parry_shield_fx:
		parry_shield_fx.visible = false
	parry_success.emit()
	_create_screen_shake(0.3)
	
	# Lướt ra sau lưng kẻ địch
	var target_x = attacker_pos.x + (-facing_direction * 1.5)
	global_position.x = target_x
	facing_direction = -facing_direction
	
	# Phản đòn chí mạng
	_start_attack_combo()
	add_flow(2)

func _start_shadow_dash() -> void:
	dash_cooldown_timer = DASH_COOLDOWN
	is_dashing = true
	is_invulnerable = true
	dash_timer = DASH_DURATION
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0.0
	_play_anim("ShadowDash")
	
	var tween = create_tween()
	tween.tween_interval(DASH_DURATION)
	tween.tween_callback(func():
		is_dashing = false
		is_invulnerable = false
	)

func _start_blade_dance() -> void:
	current_state = State.BLADE_DANCE
	is_invulnerable = true
	velocity = Vector3.ZERO
	_reset_flow()
	_play_anim("BladeDance")
	
	var tween = create_tween()
	for i in range(7):
		tween.tween_callback(func():
			_trigger_hitbox(true)
			_spawn_slash_vfx(randi_range(1, 4))
			_create_screen_shake(0.12)
		)
		tween.tween_interval(0.08)
		tween.tween_callback(func(): _trigger_hitbox(false))
	
	tween.tween_callback(func():
		is_invulnerable = false
		current_state = State.IDLE
	)

func add_flow(amount: int = 1) -> void:
	current_flow = min(max_flow, current_flow + amount)
	flow_decay_timer = FLOW_DECAY_DELAY
	is_overdrive = (current_flow >= max_flow)
	flow_changed.emit(current_flow, max_flow, is_overdrive)

func _reset_flow() -> void:
	current_flow = 0
	is_overdrive = false
	flow_changed.emit(current_flow, max_flow, is_overdrive)

func take_damage(amount: float, attacker_pos: Vector3 = Vector3.ZERO) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return
		
	if is_parrying:
		trigger_parry_counter(attacker_pos)
		return
		
	current_hp = max(0.0, current_hp - amount)
	hp_changed.emit(current_hp, max_hp)
	_reset_flow()
	_create_screen_shake(0.2)
	
	if current_hp <= 0.0:
		_die()
	else:
		_play_anim("Hurt")
		velocity.x = -facing_direction * 3.5
		velocity.y = 3.0

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO
	_play_anim("Die")
	player_died.emit()

func _update_facing() -> void:
	if visual_root:
		# Quay góc Y: 90 độ khi nhìn sang phải, -90 độ khi sang trái
		var target_rot_y = deg_to_rad(90.0 if facing_direction > 0 else -90.0)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, 0.35)

func _trigger_hitbox(active: bool) -> void:
	if attack_area:
		attack_area.monitoring = active
		if active:
			# Đặt vị trí hitbox theo hướng nhìn
			attack_area.position.x = facing_direction * 0.9

func _spawn_slash_vfx(combo_num: int) -> void:
	# VFX chém 3D
	var vfx = get_node_or_null("VisualRoot/SlashArc")
	if vfx and vfx.has_method("play_slash"):
		vfx.play_slash(combo_num, is_overdrive)

func _process_blade_dance(_delta: float) -> void:
	velocity = Vector3.ZERO

func _create_screen_shake(intensity: float) -> void:
	var cam = get_viewport().get_camera_3d()
	if cam and cam.has_method("apply_shake"):
		cam.apply_shake(intensity)

func _play_anim(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _on_attack_area_body_entered(body: Node3D) -> void:
	if body == self:
		return
	if body.has_method("take_hit"):
		var damage = base_atk * (1.2 if is_overdrive else 1.0)
		if combo_index == 4:
			damage *= 1.6 # Finisher
		body.take_hit(damage, global_position)
		add_flow(1)
		_create_screen_shake(0.08)
