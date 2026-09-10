class_name Player
extends CharacterBody2D

## Player Controller (Project Dual Blade)
## Máy trạng thái hữu hạn (FSM) hoàn chỉnh kèm Input Buffering, Combo 4-hit, 
## Không chiến (Air Slash), Shadow Dash i-frame + Dư ảnh GhostTrail, 
## Cross-Parry 0.15s, Double Jump & Wall Slide/Jump, và Kỹ năng Option Pool.

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
	ATTACK_3,
	ATTACK_4,
	AIR_ATTACK,
	DASH,
	PARRY,
	HURT,
	DEAD
}

signal hp_changed(current_hp: float, max_hp: float)
signal flow_changed(stacks: int, is_full: bool)
signal state_changed(new_state_name: String, is_iframe: bool)
signal flasks_changed(current: int, maximum: int)
signal weapon_equipped(tier_name: String, atk: float, crit: float)
signal crystals_changed(count: int)
signal inventory_changed(items: Array[Dictionary])

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
@export var base_atk: float = 12.0
@export var crit_rate: float = 0.05
var current_weapon_tier: String = "tier_d"
var current_weapon_data: Dictionary = {}
var weapon_options: Array[Dictionary] = []

var life_flasks: int = 1
var max_flasks: int = 3
var upgrade_crystals: int = 0
var inventory: Array[Dictionary] = []

# ------------------------------------------------------------------------------
# 3. BIẾN QUẢN LÝ FSM & SKILLS
# ------------------------------------------------------------------------------
var current_state: State = State.IDLE
var can_double_jump: bool = false
var facing_direction: int = 1 # 1: Phải, -1: Trái
var is_iframe: bool = false

# Dash & Afterimage
const DASH_SPEED: float = 340.0
const DASH_DURATION: float = 0.2
var dash_timer: float = 0.0
var ghost_spawn_timer: float = 0.0

# Cross-Parry (0.15s)
const PARRY_WINDOW: float = 0.15
var parry_timer: float = 0.0
var is_parrying: bool = false

# Flow Meter (5 nấc, 2.5s decay)
const MAX_FLOW: int = 5
const FLOW_DECAY_DURATION: float = 2.5
var current_flow: int = 0
var flow_timer: float = 0.0

# Combo & Input Buffering
var has_buffered_attack: bool = false
const BUFFER_WINDOW: float = 0.25
var buffer_timer: float = 0.0

# Air Attack
var air_attack_timer: float = 0.0
const AIR_ATTACK_DURATION: float = 0.25

# Hit-stop
var hit_stop_timer: float = 0.0

# Drop through one-way platform
var is_dropping_through: bool = false
var drop_through_timer: float = 0.0

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
	add_to_group("player")
	current_hp = max_hp
	emit_signal("hp_changed", current_hp, max_hp)
	emit_signal("flow_changed", current_flow, false)
	emit_signal("flasks_changed", life_flasks, max_flasks)
	emit_signal("crystals_changed", upgrade_crystals)
	
	equip_weapon_tier("tier_d")
	_change_state(State.IDLE)
	
	if hitbox:
		hitbox.hit_landed.connect(_on_attack_landed)
	if hurtbox:
		hurtbox.hit_received.connect(_on_hurtbox_hit_received)

func _physics_process(delta: float) -> void:
	if hit_stop_timer > 0.0:
		hit_stop_timer -= delta
		return

	_update_flow_meter(delta)
	_update_input_buffering(delta)
	_update_ghost_trail(delta)

	if is_dropping_through:
		drop_through_timer -= delta
		if drop_through_timer <= 0.0:
			is_dropping_through = false
			set_collision_mask_value(1, true)

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
		State.ATTACK_3:
			_state_attack_3(delta)
		State.ATTACK_4:
			_state_attack_4(delta)
		State.AIR_ATTACK:
			_state_air_attack(delta)
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

	if anim_player:
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
				_set_hitbox_damage_mult(1.0)
			State.ATTACK_2:
				anim_player.play("attack_2")
				has_buffered_attack = false
				_set_hitbox_damage_mult(1.1)
			State.ATTACK_3:
				anim_player.play("attack_3")
				has_buffered_attack = false
				_set_hitbox_damage_mult(1.25)
			State.ATTACK_4:
				anim_player.play("attack_4")
				has_buffered_attack = false
				_set_hitbox_damage_mult(1.6)
			State.AIR_ATTACK:
				anim_player.play("attack_2")
				has_buffered_attack = false
				_set_hitbox_damage_mult(1.2)
				air_attack_timer = AIR_ATTACK_DURATION
			State.DASH:
				anim_player.play("dash")
			State.PARRY:
				anim_player.play("parry")
			State.HURT:
				anim_player.play("hurt")
			State.DEAD:
				anim_player.play("dead")
	else:
		if current_state == State.AIR_ATTACK:
			air_attack_timer = AIR_ATTACK_DURATION

func _set_hitbox_damage_mult(mult: float) -> void:
	if hitbox:
		var bonus_mult = 1.2 if is_full_flow() else 1.0
		hitbox.damage = base_atk * mult * bonus_mult
		hitbox.is_crit = (randf() < crit_rate)

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
		if Input.is_action_pressed("move_down"):
			_drop_through_platform()
			return
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
		if Input.is_action_pressed("move_down"):
			_drop_through_platform()
			return
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

func _drop_through_platform() -> void:
	is_dropping_through = true
	drop_through_timer = 0.22
	set_collision_mask_value(1, false)
	position.y += 2.0
	_change_state(State.FALL)

func _state_jump(delta: float) -> void:
	_apply_gravity(delta)
	_handle_air_horizontal_movement(delta)

	if velocity.y >= 0.0:
		_change_state(State.FALL)
		return

	_check_air_actions()

func _state_fall(delta: float) -> void:
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
		# Air Slash (lơ lửng trên không 0.25s)
		_change_state(State.AIR_ATTACK)
		return

func _handle_air_horizontal_movement(delta: float) -> void:
	var move_input := Input.get_axis("move_left", "move_right")
	if move_input != 0.0:
		facing_direction = 1 if move_input > 0.0 else -1
		velocity.x = move_toward(velocity.x, move_input * move_speed, acceleration * 0.7 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * 0.3 * delta)

# ------------------------------------------------------------------------------
# 7. COMBO TẤN CÔNG 4 NHÁT & AIR ATTACK
# ------------------------------------------------------------------------------
func _state_attack_1(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
	if Input.is_action_just_pressed("attack"):
		has_buffered_attack = true
		buffer_timer = BUFFER_WINDOW

func _state_attack_2(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
	if Input.is_action_just_pressed("attack"):
		has_buffered_attack = true
		buffer_timer = BUFFER_WINDOW

func _state_attack_3(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 2.0 * delta)
	if Input.is_action_just_pressed("attack"):
		has_buffered_attack = true
		buffer_timer = BUFFER_WINDOW

func _state_attack_4(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * 1.5 * delta)

func _state_air_attack(delta: float) -> void:
	# Treo lơ lửng trên không (0.25s) để né quét sàn
	velocity.y = 20.0
	_handle_air_horizontal_movement(delta)
	air_attack_timer -= delta
	if air_attack_timer <= 0.0 or is_on_floor():
		_change_state(State.IDLE if is_on_floor() else State.FALL)

func on_attack_animation_finished(attack_name: String) -> void:
	match attack_name:
		"attack_1":
			if has_buffered_attack:
				has_buffered_attack = false
				velocity.x = facing_direction * 65.0
				_change_state(State.ATTACK_2)
			else:
				_change_state(State.IDLE if is_on_floor() else State.FALL)
		"attack_2":
			if has_buffered_attack:
				has_buffered_attack = false
				velocity.x = facing_direction * 80.0
				_change_state(State.ATTACK_3)
			else:
				_change_state(State.IDLE if is_on_floor() else State.FALL)
		"attack_3":
			if has_buffered_attack:
				has_buffered_attack = false
				velocity.x = facing_direction * 110.0 # Bật tiến finisher
				_change_state(State.ATTACK_4)
			else:
				_change_state(State.IDLE if is_on_floor() else State.FALL)
		"attack_4":
			# Finisher lùi nhẹ an toàn
			velocity.x = -facing_direction * 40.0
			_change_state(State.IDLE if is_on_floor() else State.FALL)
		_:
			_change_state(State.IDLE if is_on_floor() else State.FALL)

# ------------------------------------------------------------------------------
# 8. SHADOW DASH & CROSS-PARRY & GHOST TRAIL
# ------------------------------------------------------------------------------
func _start_dash() -> void:
	_change_state(State.DASH)
	dash_timer = DASH_DURATION
	velocity.x = facing_direction * DASH_SPEED
	velocity.y = 0.0
	_spawn_ghost_trail(Color(0.2, 0.8, 1.0, 0.7))

func _state_dash(delta: float) -> void:
	dash_timer -= delta
	velocity.y = 0.0
	if dash_timer <= 0.0:
		_change_state(State.IDLE if is_on_floor() else State.FALL)

func _update_ghost_trail(delta: float) -> void:
	ghost_spawn_timer -= delta
	if ghost_spawn_timer <= 0.0:
		if current_state == State.DASH:
			ghost_spawn_timer = 0.05
			_spawn_ghost_trail(Color(0.2, 0.8, 1.0, 0.75))
		elif is_full_flow() and (current_state == State.RUN or current_state == State.ATTACK_1 or current_state == State.ATTACK_2 or current_state == State.ATTACK_3 or current_state == State.ATTACK_4):
			ghost_spawn_timer = 0.08
			_spawn_ghost_trail(Color(1.0, 0.85, 0.2, 0.6))

func _spawn_ghost_trail(color: Color) -> void:
	if not sprite or not get_parent():
		return
	var trail = GhostTrail.new()
	get_parent().add_child(trail)
	trail.setup(sprite, color)

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
	if is_iframe:
		return

	if is_parrying:
		if incoming_hitbox.is_unparryable:
			_take_damage(incoming_hitbox.damage)
		else:
			_on_parry_success(incoming_hitbox.owner)
		return

	_take_damage(incoming_hitbox.damage)

func _on_parry_success(enemy_node: Node) -> void:
	hit_stop_timer = 0.1
	parry_timer = 0.0
	is_parrying = false
	add_flow(2)
	
	if enemy_node and enemy_node is Node2D:
		var enemy_pos: Vector2 = (enemy_node as Node2D).global_position
		global_position = enemy_pos + Vector2(-facing_direction * 35.0, 0.0)
		_spawn_ghost_trail(Color(1.0, 0.9, 0.2, 0.9))
		
	# Check Option Phản Kích Tử Thần (SR)
	for opt in weapon_options:
		if opt.get("counter_heal", 0.0) > 0.0:
			current_hp = min(max_hp, current_hp + max_hp * opt["counter_heal"])
			emit_signal("hp_changed", current_hp, max_hp)
		
	_change_state(State.ATTACK_2)

func _take_damage(amount: float) -> void:
	current_hp = max(0.0, current_hp - amount)
	emit_signal("hp_changed", current_hp, max_hp)
	_reset_flow()
	
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 5.0, 0.15)
	VFXManager.spawn_combat_impact(get_parent(), global_position + Vector2(0, -14), Vector2(-facing_direction, 0.0), amount, false, true)
	
	if sprite:
		sprite.modulate = Color(2.5, 0.5, 0.5, 1.0)
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE

	if current_hp <= 0.0:
		_change_state(State.DEAD)
	else:
		_change_state(State.HURT)
		await get_tree().create_timer(0.2).timeout
		if current_state == State.HURT:
			_change_state(State.IDLE)

# ------------------------------------------------------------------------------
# 9. FLOW METER & ATTACK FEEDBACK
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
	HitStopManager.freeze(get_tree(), 0.06, 0.05)
	
	if target and target.owner:
		var target_entity = target.owner
		if target_entity.has_method("apply_knockback"):
			target_entity.apply_knockback(Vector2(facing_direction, 0.0), 130.0)

	# Option Huyết Khát (B) & Nạp Khí
	for opt in weapon_options:
		if opt.get("vamp_pct", 0.0) > 0.0:
			current_hp = min(max_hp, current_hp + max_hp * opt["vamp_pct"])
			emit_signal("hp_changed", current_hp, max_hp)

func _update_input_buffering(delta: float) -> void:
	if has_buffered_attack:
		buffer_timer -= delta
		if buffer_timer <= 0.0:
			has_buffered_attack = false

# ------------------------------------------------------------------------------
# 10. TIỆN ÍCH VẬT LÝ, BÌNH MÁU & TRANG BỊ
# ------------------------------------------------------------------------------
func _apply_gravity(delta: float) -> void:
	velocity.y += gravity * delta

func _apply_friction(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _update_facing_and_hitbox() -> void:
	if sprite:
		sprite.flip_h = (facing_direction < 0)
	if hitbox:
		hitbox.position.x = abs(hitbox.position.x) * facing_direction

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("use_flask") or (event is InputEventKey and event.pressed and event.keycode == KEY_Q):
		use_flask()

func use_flask() -> void:
	if life_flasks > 0 and current_hp < max_hp:
		life_flasks -= 1
		var heal = max_hp * 0.35
		current_hp = min(max_hp, current_hp + heal)
		emit_signal("hp_changed", current_hp, max_hp)
		emit_signal("flasks_changed", life_flasks, max_flasks)

func add_flask(count: int = 1) -> void:
	life_flasks = clampi(life_flasks + count, 0, max_flasks)
	emit_signal("flasks_changed", life_flasks, max_flasks)

func add_crystals(count: int = 1) -> void:
	upgrade_crystals += count
	emit_signal("crystals_changed", upgrade_crystals)

func equip_weapon_dict(item_dict: Dictionary) -> void:
	current_weapon_data = item_dict
	weapon_options = item_dict.get("options", [])
	equip_weapon_tier(item_dict.get("tier", "tier_d"))

func equip_weapon_tier(tier: String) -> void:
	current_weapon_tier = tier
	match tier:
		"tier_d":
			base_atk = 12.0
			crit_rate = 0.05
		"tier_c":
			base_atk = 21.0
			crit_rate = 0.07
		"tier_b":
			base_atk = 36.0
			crit_rate = 0.10
		"tier_a":
			base_atk = 61.0
			crit_rate = 0.14
		"tier_r":
			base_atk = 100.0
			crit_rate = 0.18
		"tier_sr":
			base_atk = 168.0
			crit_rate = 0.23
		"tier_ssr":
			base_atk = 270.0
			crit_rate = 0.28
	
	# Cộng dồn chỉ số từ Weapon Options
	for opt in weapon_options:
		if opt.has("atk_pct"):
			base_atk *= (1.0 + opt["atk_pct"])
		if opt.has("crit_pct"):
			crit_rate += opt["crit_pct"]

	if hitbox:
		hitbox.damage = base_atk
		hitbox.is_crit = (randf() < crit_rate)

	_play_equip_vfx(tier)
	emit_signal("weapon_equipped", current_weapon_tier, base_atk, crit_rate)

func _play_equip_vfx(tier: String) -> void:
	var tier_colors = {
		"tier_d": Color(0.7, 0.7, 0.7),
		"tier_c": Color(1.0, 1.0, 1.0),
		"tier_b": Color(0.2, 1.0, 0.3),
		"tier_a": Color(0.2, 0.6, 1.0),
		"tier_r": Color(0.8, 0.3, 1.0),
		"tier_sr": Color(1.0, 0.85, 0.2),
		"tier_ssr": Color(1.0, 0.3, 0.8)
	}
	var glow_color = tier_colors.get(tier, Color.WHITE)
	
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", glow_color * 2.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
		
	if get_parent():
		var dmg_num = DamageNumber.new()
		dmg_num.global_position = global_position + Vector2(0, -28)
		dmg_num.setup(base_atk, true, glow_color)
		get_parent().call_deferred("add_child", dmg_num)

func add_to_inventory(item_dict: Dictionary) -> void:
	inventory.append(item_dict)
	emit_signal("inventory_changed", inventory)

func salvage_weapon(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		return false
	var item = inventory[index]
	inventory.remove_at(index)
	add_crystals(2)
	emit_signal("inventory_changed", inventory)
	return true
