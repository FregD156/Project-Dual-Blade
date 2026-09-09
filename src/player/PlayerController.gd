class_name PlayerController
extends CharacterBody2D

## PlayerController - Finite State Machine (FSM) cho Project Dual Blade
## Kế thừa CharacterBody2D, hỗ trợ Platforming, 4-hit Combo, Air-Combo, Dash, Parry, Blade Dance

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	WALL_SLIDE,
	ATTACK,
	AIR_ATTACK,
	DASH,
	PARRY,
	BLADE_DANCE,
	HURT,
	DEAD
}

@export var move_speed: float = 180.0
@export var jump_velocity: float = -320.0
@export var double_jump_velocity: float = -280.0
@export var wall_slide_speed: float = 60.0
@export var wall_jump_velocity: Vector2 = Vector2(220.0, -300.0)
@export var gravity: float = 900.0

var current_state: State = State.IDLE
var can_double_jump: bool = false
var facing_direction: int = 1 # 1: phải, -1: trái

# Combo System
var combo_index: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 0.45
const ATTACK_DURATIONS: Array[float] = [0.18, 0.18, 0.24, 0.35]
const SKILL_MULTIPLIERS: Array[float] = [1.0, 1.1, 1.3, 1.8] # Finisher x1.8

# Air combo float
var air_float_timer: float = 0.0
const AIR_FLOAT_DURATION: float = 0.3

# Subsystems
var flow_meter: FlowMeter
var parry_handler: CrossParryHandler

# Dash system
var dash_timer: float = 0.0
const DASH_DURATION: float = 0.22
const DASH_SPEED: float = 400.0
var is_iframe: bool = false

# Hit-stop
var hit_stop_timer: float = 0.0

@onready var anim_sprite: PlayerAnimationController = $AnimSprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	flow_meter = FlowMeter.new()
	parry_handler = CrossParryHandler.new()
	parry_handler.parry_success.connect(_on_parry_success)

func _physics_process(delta: float) -> void:
	# Xử lý hit-stop
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		return

	flow_meter.update(delta)
	parry_handler.update(delta)

	match current_state:
		State.IDLE, State.RUN:
			_handle_ground_movement(delta)
		State.JUMP, State.FALL:
			_handle_air_movement(delta)
		State.WALL_SLIDE:
			_handle_wall_slide(delta)
		State.ATTACK:
			_handle_attack_state(delta)
		State.AIR_ATTACK:
			_handle_air_attack_state(delta)
		State.DASH:
			_handle_dash_state(delta)
		State.PARRY:
			_handle_parry_state(delta)
		State.BLADE_DANCE:
			_handle_blade_dance_state(delta)

	_update_sprite_visual()
	move_and_slide()

func _handle_ground_movement(delta: float) -> void:
	if not is_on_floor():
		current_state = State.FALL
		return

	can_double_jump = true

	# Check Actions
	if Input.is_action_just_pressed("attack"):
		_start_attack(0)
		return
	if Input.is_action_just_pressed("parry"):
		_start_parry()
		return
	if Input.is_action_just_pressed("dash"):
		_start_dash()
		return
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		current_state = State.JUMP
		return

	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0:
		facing_direction = 1 if move_input > 0 else -1
		velocity.x = move_input * move_speed * flow_meter.get_speed_multiplier()
		current_state = State.RUN
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 10.0 * delta)
		current_state = State.IDLE

func _handle_air_movement(delta: float) -> void:
	velocity.y += gravity * delta

	# Wall slide check
	if is_on_wall() and velocity.y > 0:
		current_state = State.WALL_SLIDE
		return

	if Input.is_action_just_pressed("jump") and can_double_jump:
		velocity.y = double_jump_velocity
		can_double_jump = false
		current_state = State.JUMP
		return

	if Input.is_action_just_pressed("attack"):
		_start_air_attack()
		return

	if Input.is_action_just_pressed("dash"):
		_start_dash()
		return

	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0:
		facing_direction = 1 if move_input > 0 else -1
		velocity.x = move_input * move_speed * flow_meter.get_speed_multiplier()
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed * 2.0 * delta)

	if is_on_floor():
		current_state = State.IDLE

func _handle_wall_slide(delta: float) -> void:
	velocity.y = min(velocity.y + gravity * delta, wall_slide_speed)

	if Input.is_action_just_pressed("jump"):
		var wall_normal := get_wall_normal()
		velocity.x = wall_normal.x * wall_jump_velocity.x
		velocity.y = wall_jump_velocity.y
		facing_direction = 1 if velocity.x > 0 else -1
		current_state = State.JUMP
		can_double_jump = true
		return

	if not is_on_wall() or is_on_floor():
		current_state = State.IDLE if is_on_floor() else State.FALL

func _start_attack(index: int) -> void:
	current_state = State.ATTACK
	combo_index = index
	combo_timer = ATTACK_DURATIONS[combo_index]
	velocity.x = facing_direction * 40.0 # bước nhích nhẹ về phía trước
	
	if hitbox:
		hitbox.damage = 20.0 * flow_meter.get_damage_multiplier()
		hitbox.skill_mult = SKILL_MULTIPLIERS[combo_index]
		hitbox.monitoring = true
		hitbox.monitorable = true
		# Tự động tắt hitbox sau một nửa thời gian vung đao
		get_tree().create_timer(ATTACK_DURATIONS[combo_index] * 0.6).timeout.connect(func():
			if hitbox:
				hitbox.monitoring = false
				hitbox.monitorable = false
		)

func _handle_attack_state(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 300.0 * delta)
	combo_timer -= delta

	if combo_timer <= 0.0:
		if hitbox:
			hitbox.monitoring = false
			hitbox.monitorable = false
		if combo_index < 3 and Input.is_action_pressed("attack"):
			_start_attack(combo_index + 1)
		else:
			current_state = State.IDLE if is_on_floor() else State.FALL

func _start_air_attack() -> void:
	current_state = State.AIR_ATTACK
	air_float_timer = AIR_FLOAT_DURATION
	velocity = Vector2.ZERO # Lơ lửng trên không 0.3s
	if hitbox:
		hitbox.damage = 18.0 * flow_meter.get_damage_multiplier()
		hitbox.skill_mult = 1.0
		hitbox.monitoring = true
		hitbox.monitorable = true

func _handle_air_attack_state(delta: float) -> void:
	air_float_timer -= delta
	if air_float_timer <= 0.0:
		if hitbox:
			hitbox.monitoring = false
			hitbox.monitorable = false
		current_state = State.FALL

func _start_dash() -> void:
	current_state = State.DASH
	dash_timer = DASH_DURATION
	is_iframe = true
	if hurtbox:
		hurtbox.is_invincible = true
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0

func _handle_dash_state(delta: float) -> void:
	dash_timer -= delta
	if dash_timer <= 0.0:
		is_iframe = false
		if hurtbox:
			hurtbox.is_invincible = false
		current_state = State.IDLE if is_on_floor() else State.FALL

func _start_parry() -> void:
	current_state = State.PARRY
	parry_handler.start_parry()
	velocity = Vector2.ZERO

func _handle_parry_state(_delta: float) -> void:
	if not parry_handler.is_parrying:
		current_state = State.IDLE

func _start_blade_dance() -> void:
	current_state = State.BLADE_DANCE
	is_iframe = true
	if hurtbox:
		hurtbox.is_invincible = true

func _handle_blade_dance_state(_delta: float) -> void:
	pass

func _on_parry_success(enemy_node: Node) -> void:
	hit_stop_timer = 0.1 # 0.1s hit-stop
	flow_meter.on_parry_success()
	# Dịch chuyển tức thì ra sau lưng đối thủ
	if enemy_node and enemy_node is Node2D:
		var enemy_pos: Vector2 = (enemy_node as Node2D).global_position
		global_position = enemy_pos + Vector2(-facing_direction * 40.0, 0)
	current_state = State.IDLE


func _update_sprite_visual() -> void:
	if not anim_sprite:
		return
	anim_sprite.flip_h = (facing_direction < 0)
	match current_state:
		State.IDLE:
			anim_sprite.play("idle")
		State.RUN:
			anim_sprite.play("run")
		State.ATTACK, State.AIR_ATTACK:
			anim_sprite.play("attack")
		State.PARRY:
			anim_sprite.play("parry")
		State.JUMP, State.FALL:
			anim_sprite.play("jump")
		State.DASH:
			anim_sprite.play("dash")
