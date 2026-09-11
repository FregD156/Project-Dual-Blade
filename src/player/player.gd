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
	BLADE_DANCE,
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
signal armor_changed(current_armor: float, max_armor: float)
signal armor_equipped(equipped_armor: Dictionary)
signal shield_equipped(shield_data: Dictionary)
signal items_merged(merged_items: Array[Dictionary])
signal player_died()

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
var base_max_hp: float = 100.0
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

# Armor Equipment System (Helmet, Chest, Arms, Legs)
var equipped_armor: Dictionary = {
	"helmet": {},
	"chest": {},
	"arms": {},
	"legs": {}
}
var max_armor: float = 0.0
var current_armor: float = 0.0

# Shield Equipment System (Khiên Hộ Thân)
var equipped_shield: Dictionary = {}
var block_chance: float = 0.0
var shield_damage_reduction: float = 0.0

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

# Chiêu thức Tất Sát: Blade Dance (Vũ Điệu Bão Đao)
var blade_dance_timer: float = 0.0
var blade_dance_slashes_left: int = 0
var blade_dance_slash_interval: float = 0.0
var is_infinite_slash: bool = false
const BLADE_DANCE_SLASH_INTERVAL_BASE: float = 0.08
const BLADE_DANCE_SLASH_COUNT_BASE: int = 8
const BLADE_DANCE_SLASH_COUNT_SSR: int = 14

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
	
	# Trang bị khởi đầu bộ giáp Bậc D & Khiên Gỗ Bậc D
	equip_armor_piece(ArmorSystem.create_armor_item("helmet", "tier_d"))
	equip_armor_piece(ArmorSystem.create_armor_item("chest", "tier_d"))
	equip_armor_piece(ArmorSystem.create_armor_item("arms", "tier_d"))
	equip_armor_piece(ArmorSystem.create_armor_item("legs", "tier_d"))
	equip_shield(ShieldSystem.create_shield_item("tier_d"))
	
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
		State.BLADE_DANCE:
			_state_blade_dance(delta)
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
	is_iframe = (current_state == State.DASH or current_state == State.BLADE_DANCE)
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
			State.BLADE_DANCE:
				anim_player.play("attack_3")
			State.HURT:
				anim_player.play("hurt")
			State.DEAD:
				if hurtbox:
					hurtbox.set_deferred("monitoring", false)
					hurtbox.set_deferred("monitorable", false)
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

	if Input.is_action_just_pressed("blade_dance"):
		if _can_cast_blade_dance():
			_start_blade_dance()
			return
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
 
	if Input.is_action_just_pressed("blade_dance"):
		if _can_cast_blade_dance():
			_start_blade_dance()
			return
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
		if abs(velocity.x) < 15.0 or is_on_wall():
			velocity.x = 0.0
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
		var move_in := Input.get_axis("move_left", "move_right")
		_change_state(State.RUN if move_in != 0.0 else State.IDLE)
		return

	_check_air_actions()

func _check_air_actions() -> void:
	if Input.is_action_just_pressed("blade_dance"):
		if _can_cast_blade_dance():
			_start_blade_dance()
			return
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
	if current_state == State.BLADE_DANCE:
		return
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

func _can_cast_blade_dance() -> bool:
	return current_flow >= MAX_FLOW and current_state != State.DEAD and current_state != State.HURT and current_state != State.BLADE_DANCE

func _start_blade_dance() -> void:
	if not _can_cast_blade_dance():
		return
		
	# Tiêu hao toàn bộ thanh Flow
	_reset_flow()
	
	# Kiểm tra Lõi Thức Tỉnh SSR "Diệt Thế Thần Khí" (Vô Hạn Trảm 12 nhát)
	is_infinite_slash = false
	for opt in weapon_options:
		if opt.get("infinite_slash", false):
			is_infinite_slash = true
			break
			
	blade_dance_slashes_left = BLADE_DANCE_SLASH_COUNT_SSR if is_infinite_slash else BLADE_DANCE_SLASH_COUNT_BASE
	blade_dance_slash_interval = 0.0
	blade_dance_timer = (blade_dance_slashes_left + 1) * BLADE_DANCE_SLASH_INTERVAL_BASE + 0.15
	
	_change_state(State.BLADE_DANCE)
	velocity = Vector2.ZERO
	
	# Hiệu ứng mờ dần nhân vật như tan biến vào hư ảnh
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.35, 0.08)
		
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 6.0, 0.2)

func _state_blade_dance(delta: float) -> void:
	velocity = Vector2.ZERO
	blade_dance_timer -= delta
	blade_dance_slash_interval -= delta
	
	if blade_dance_slashes_left > 0 and blade_dance_slash_interval <= 0.0:
		blade_dance_slash_interval = BLADE_DANCE_SLASH_INTERVAL_BASE
		blade_dance_slashes_left -= 1
		# Đảo hướng và đổi hoạt ảnh vung đao liên hồi
		if anim_player:
			var anim_to_play = "attack_1" if (blade_dance_slashes_left % 2 == 0) else "attack_3"
			anim_player.play(anim_to_play)
		facing_direction = -facing_direction
		_update_facing_and_hitbox()
		_execute_blade_dance_slash()
		
	if blade_dance_timer <= 0.0 or blade_dance_slashes_left <= 0:
		_finish_blade_dance()

func _execute_blade_dance_slash() -> void:
	# Tìm mục tiêu trong vùng kích hoạt hoặc chém quét toàn màn hình nếu SSR
	var enemies = get_tree().get_nodes_in_group("enemies")
	var range_limit = 9999.0 if is_infinite_slash else 180.0
	var valid_enemies: Array[Node] = []
	
	for e in enemies:
		if e is Node2D and is_instance_valid(e) and (not ("current_state" in e) or e.current_state != 4): # không phải DEAD
			var d = global_position.distance_to(e.global_position)
			if d <= range_limit:
				valid_enemies.append(e)
				
	# Hệ số sát thương mỗi nhát chém bão đao: 1.5x ATK (SSR là 2.2x)
	var slash_dmg = base_atk * (2.2 if is_infinite_slash else 1.5)
	var slash_pos = global_position + Vector2(randf_range(-40, 40) * facing_direction, randf_range(-25, 10))
	
	if valid_enemies.size() > 0:
		# Ưu tiên mục tiêu gần hoặc chém ngẫu nhiên mục tiêu trong tầm
		var target_enemy = valid_enemies[randi() % valid_enemies.size()]
		slash_pos = target_enemy.global_position + Vector2(randf_range(-12, 12), randf_range(-18, 5))
		
		# Gây sát thương trực tiếp lên kẻ địch qua hitbox ảo
		if target_enemy.has_method("_on_hit_received"):
			var virtual_hitbox = Hitbox.new()
			virtual_hitbox.damage = slash_dmg
			virtual_hitbox.skill_mult = 1.0
			virtual_hitbox.is_crit = (randf() < (crit_rate + 0.15))
			target_enemy._on_hit_received(virtual_hitbox)
			virtual_hitbox.queue_free()
			
	# Spawn hiệu ứng chém điện quang, vòng cung kiếm quang cực đại và vệt dư ảnh bão đao
	var slash_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.8, 0.8)).normalized()
	var trail_color = Color(1.0, 0.2, 0.8, 0.95) if is_infinite_slash else Color(0.0, 0.9, 1.0, 0.9)
	_spawn_ghost_trail(trail_color)
	
	if get_parent():
		# 1. Spawn vệt chém kiếm quang điện ảnh (Blade Dance Arc Slash)
		var arc_vfx = BladeDanceSlashVFX.new()
		get_parent().add_child(arc_vfx)
		var slash_angle = slash_dir.angle()
		arc_vfx.setup(slash_pos, slash_angle, randf_range(44.0, 62.0), is_infinite_slash)
		
		# 2. Spawn tia lửa, máu và số sát thương
		VFXManager.spawn_combat_impact(get_parent(), slash_pos, slash_dir, slash_dmg, true, false)
		
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 4.5, 0.08)

func _finish_blade_dance() -> void:
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 1.0, 0.1)
		
	_spawn_ghost_trail(Color(1.0, 0.9, 0.2, 0.9))
	_change_state(State.IDLE if is_on_floor() else State.FALL)

func _start_parry() -> void:
	_change_state(State.PARRY)
	parry_timer = PARRY_WINDOW
	is_parrying = true
	velocity = Vector2.ZERO
	
	# Hiển thị khiên chắn hộ thể khi nhấn phím K
	if get_parent():
		var block_vfx = ShieldBlockVFX.new()
		get_parent().add_child(block_vfx)
		var block_pos = global_position + Vector2(facing_direction * 14.0, -14.0)
		var tier = equipped_shield.get("tier", "tier_d")
		var vfx_color = Color(0.1, 0.8, 1.0, 1.0)
		match tier:
			"tier_sr": vfx_color = Color(1.0, 0.85, 0.2, 1.0)
			"tier_ssr": vfx_color = Color(1.0, 0.25, 0.8, 1.0)
		block_vfx.setup(block_pos, facing_direction, vfx_color)

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

	# Kiểm tra Chặn Đòn từ Khiên Hộ Thân (Shield Block Chance)
	if _try_shield_block(incoming_hitbox):
		return

	_take_damage(incoming_hitbox.damage)

func _try_shield_block(incoming_hitbox: Hitbox) -> bool:
	if equipped_shield.is_empty():
		return false
		
	var effective_block = block_chance
	# Option Thần Hộ Mệnh SSR: Nếu HP < 25% thì chặn 100%
	for opt in equipped_shield.get("options", []):
		if opt.get("immortal_threshold", 0.0) > 0.0 and (current_hp / max_hp) <= opt["immortal_threshold"]:
			effective_block = 1.0
			break

	if randf() < effective_block:
		# Kích hoạt Chặn Đòn Thành Công (BLOCK!)
		_on_shield_block_success(incoming_hitbox)
		return true
		
	return false

func _on_shield_block_success(incoming_hitbox: Hitbox) -> void:
	# 1. Spawn hiệu ứng vòm khiên phát quang (ShieldBlockVFX)
	if get_parent():
		var block_vfx = ShieldBlockVFX.new()
		get_parent().add_child(block_vfx)
		var block_pos = global_position + Vector2(facing_direction * 12.0, -14.0)
		var tier = equipped_shield.get("tier", "tier_d")
		var vfx_color = Color(0.1, 0.8, 1.0, 1.0) # Cobalt Blue
		match tier:
			"tier_sr": vfx_color = Color(1.0, 0.85, 0.2, 1.0) # Vàng kim
			"tier_ssr": vfx_color = Color(1.0, 0.25, 0.8, 1.0) # Hồng tím Thần Thánh
		block_vfx.setup(block_pos, facing_direction, vfx_color)
		
		# Hiện chữ "BLOCK!" màu xanh lam
		var dmg_num = DamageNumber.new()
		dmg_num.global_position = block_pos + Vector2(0, -12)
		get_parent().add_child(dmg_num)
		dmg_num.setup(0.0, true, Color(0.2, 0.9, 1.0, 1.0))
		var lbl = dmg_num.get_child(0)
		if lbl is Label:
			lbl.text = "BLOCK!"

	# 2. Khựng nhẹ và rung chấn phòng thủ
	HitStopManager.freeze(get_tree(), 0.04, 0.04)
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 2.5, 0.08)

	# 3. Kích hoạt hiệu ứng từ các dòng Option của Khiên
	var opts = equipped_shield.get("options", [])
	for opt in opts:
		if opt.get("block_heal_armor", 0.0) > 0.0:
			current_armor = min(max_armor, current_armor + max_armor * opt["block_heal_armor"])
			emit_signal("armor_changed", current_armor, max_armor)
		if opt.get("block_flow", 0) > 0:
			add_flow(opt["block_flow"])
		if opt.get("block_stun", false) and incoming_hitbox.owner and incoming_hitbox.owner.has_method("apply_knockback"):
			incoming_hitbox.owner.apply_knockback(Vector2(-facing_direction, 0.0), 160.0)

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
	var remaining_damage = amount
	
	# 1. Hấp thụ qua Lớp Giáp Bảo Vệ trước
	if current_armor > 0.0:
		if current_armor >= remaining_damage:
			current_armor -= remaining_damage
			remaining_damage = 0.0
		else:
			remaining_damage -= current_armor
			current_armor = 0.0
		emit_signal("armor_changed", current_armor, max_armor)
		
	# 2. Sát thương xuyên qua trừ vào Máu (HP)
	if remaining_damage > 0.0:
		current_hp = max(0.0, current_hp - remaining_damage)
		emit_signal("hp_changed", current_hp, max_hp)
		
	_reset_flow()
	
	var cam: Camera2D = get_node_or_null("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 5.0, 0.15)
	VFXManager.spawn_combat_impact(get_parent(), global_position + Vector2(0, -14), Vector2(-facing_direction, 0.0), amount, false, true)
	
	if current_hp <= 0.0:
		_change_state(State.DEAD)
		emit_signal("player_died")
		return

	if sprite:
		sprite.modulate = Color(2.5, 0.5, 0.5, 1.0)
		await get_tree().create_timer(0.08).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color.WHITE

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
	
	# Khi chém đủ 5 Flow: Tự động giải phóng Tuyệt kĩ Tất Sát (Blade Dance)
	if is_full_flow() and _can_cast_blade_dance():
		call_deferred("_start_blade_dance")

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
	var pressed_flask = false
	if InputMap.has_action("use_flask") and event.is_action_pressed("use_flask"):
		pressed_flask = true
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_O or event.keycode == KEY_Q):
		pressed_flask = true

	if pressed_flask:
		use_flask()
		return

	var pressed_blade_dance = false
	if InputMap.has_action("blade_dance") and event.is_action_pressed("blade_dance"):
		pressed_blade_dance = true
	elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_U or event.keycode == KEY_E):
		pressed_blade_dance = true

	if pressed_blade_dance and _can_cast_blade_dance():
		_start_blade_dance()

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
	check_and_merge_inventory()
	emit_signal("inventory_changed", inventory)

func check_and_merge_inventory() -> Array[Dictionary]:
	var merged_items = MergeSystem.perform_merge(inventory)
	if merged_items.size() > 0:
		emit_signal("items_merged", merged_items)
		emit_signal("inventory_changed", inventory)
		_play_merge_notification_vfx(merged_items)
	return merged_items

func _play_merge_notification_vfx(merged_items: Array[Dictionary]) -> void:
	for item in merged_items:
		var tier = item.get("tier", "tier_c")
		var item_name = item.get("name", "Trang Bị")
		var tier_str = tier.replace("tier_", "").to_upper()
		
		# Hiển thị thông báo Floating Text rực rỡ trên đầu nhân vật
		if get_parent():
			var dmg_num = DamageNumber.new()
			dmg_num.global_position = global_position + Vector2(0, -32 - randf_range(0, 15))
			var tier_colors = {
				"tier_c": Color(1.0, 1.0, 1.0),
				"tier_b": Color(0.2, 1.0, 0.3),
				"tier_a": Color(0.2, 0.6, 1.0),
				"tier_r": Color(0.8, 0.3, 1.0),
				"tier_sr": Color(1.0, 0.85, 0.2),
				"tier_ssr": Color(1.0, 0.3, 0.8)
			}
			var col = tier_colors.get(tier, Color(1.0, 0.9, 0.3))
			dmg_num.setup(0, false, col)
			# Gán nhãn text hiển thị thông báo ghép thành công
			for child in dmg_num.get_children():
				if child is Label:
					child.text = "GHÉP THÀNH CÔNG: %s!" % item_name
					child.custom_minimum_size = Vector2(160, 20)
					child.position = Vector2(-80, -10)
			get_parent().call_deferred("add_child", dmg_num)
			
		# Hiệu ứng ánh hào quang loé sáng trên người Player
		if sprite:
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color(2.0, 2.0, 0.5, 1.0), 0.12)
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)

func salvage_weapon(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		return false
	var item = inventory[index]
	inventory.remove_at(index)
	add_crystals(2)
	emit_signal("inventory_changed", inventory)
	return true

# ------------------------------------------------------------------------------
# 11. HỆ THỐNG MŨ, GIÁP, TAY, CHÂN (ARMOR EQUIPMENT & REGEN)
# ------------------------------------------------------------------------------
func equip_armor_piece(armor_item: Dictionary) -> void:
	var part = armor_item.get("part", "")
	if not equipped_armor.has(part):
		return
		
	equipped_armor[part] = armor_item
	recalculate_armor()
	emit_signal("armor_equipped", equipped_armor)

func recalculate_armor() -> void:
	var total_armor = 0.0
	var armor_pct_bonus = 0.0
	var flat_bonus = 0.0
	
	for part in equipped_armor.keys():
		var item = equipped_armor[part]
		if item.is_empty():
			continue
		total_armor += item.get("armor_value", 0.0)
		var opts = item.get("options", [])
		for opt in opts:
			armor_pct_bonus += opt.get("armor_pct", 0.0)
			flat_bonus += opt.get("flat_armor", 0.0)
			
	# Cộng thêm giáp từ Khiên Hộ Thân
	if not equipped_shield.is_empty():
		total_armor += equipped_shield.get("bonus_armor", 0.0)

	var prev_max = max_armor
	max_armor = round((total_armor + flat_bonus) * (1.0 + armor_pct_bonus))
	
	# Nếu vừa trang bị mới hoặc khởi tạo: Cập nhật current_armor tỉ lệ thuận
	if prev_max <= 0.0:
		current_armor = max_armor
	else:
		current_armor = clampf(current_armor + (max_armor - prev_max), 0.0, max_armor)
		
	emit_signal("armor_changed", current_armor, max_armor)

func refill_armor_after_round() -> void:
	# Cơ chế hồi phục 100% Giáp sau mỗi round theo yêu cầu người chơi
	current_armor = max_armor
	emit_signal("armor_changed", current_armor, max_armor)
	
	# Hiệu ứng hồi giáp: Ánh sáng lam/bạc bao quanh nhân vật
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(0.4, 0.9, 1.8, 1.0), 0.2)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)

# ------------------------------------------------------------------------------
# 12. HỆ THỐNG KHIÊN HỘ THÂN (SHIELD SYSTEM & BLOCK LOGIC)
# ------------------------------------------------------------------------------
func equip_shield(shield_dict: Dictionary) -> void:
	equipped_shield = shield_dict
	recalculate_shield_stats()
	emit_signal("shield_equipped", equipped_shield)

func recalculate_shield_stats() -> void:
	var shield_bonus_hp = 0.0
	var shield_bonus_armor = 0.0
	var shield_base_block = 0.0
	var shield_dmg_reduc = 0.0
	var bonus_block_rate = 0.0
	var hp_pct_bonus = 0.0

	if not equipped_shield.is_empty():
		shield_bonus_hp = equipped_shield.get("bonus_hp", 0.0)
		shield_bonus_armor = equipped_shield.get("bonus_armor", 0.0)
		shield_base_block = equipped_shield.get("block_chance", 0.0)
		shield_dmg_reduc = equipped_shield.get("damage_reduction", 0.0)
		
		for opt in equipped_shield.get("options", []):
			bonus_block_rate += opt.get("bonus_block", 0.0)
			hp_pct_bonus += opt.get("hp_pct", 0.0)

	block_chance = clampf(shield_base_block + bonus_block_rate, 0.0, 0.85)
	shield_damage_reduction = shield_dmg_reduc

	# Cập nhật Máu Tối Đa (Max HP) được cộng thêm từ Khiên
	var prev_max_hp = max_hp
	max_hp = round((base_max_hp + shield_bonus_hp) * (1.0 + hp_pct_bonus))
	if prev_max_hp != max_hp:
		current_hp = clampf(current_hp + (max_hp - prev_max_hp), 1.0, max_hp)
		emit_signal("hp_changed", current_hp, max_hp)

	# Tái tính toán Lớp Giáp tổng
	recalculate_armor()
