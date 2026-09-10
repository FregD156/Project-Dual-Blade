class_name EnemyBase
extends CharacterBody2D

## Base class for all enemies in Project Dual Blade
## Implements:
## - Finite State Machine (IDLE, PATROL, CHASE, WINDUP, ATTACK, HURT, DEAD)
## - Hoạt họa tự động mượt mà (Walk/Run cycle & Attack/Windup poses)
## - ARPG Armor Damage Mitigation (K=50) via DamageCalculator
## - Telegraphing warning icons (Parry Star vs Danger Eye)
## - Dynamic Drop on death (Life Shard, Life Flask, Weapons, Upgrade Crystals)
## - Soft separation push area

signal died(enemy_instance: EnemyBase)
signal attack_warning_started(is_unparryable: bool)

enum State { IDLE, PATROL, CHASE, WINDUP, ATTACK, HURT, DEAD }

@export_group("Enemy Identity")
@export var enemy_name: String = "Enemy"
@export var is_elite: bool = false
@export var is_boss: bool = false

@export_group("Stats")
@export var max_hp: float = 80.0
var current_hp: float = 80.0
@export var def: float = 2.0 # Mitigation ~ 3.8%
@export var move_speed: float = 50.0
@export var attack_damage: float = 12.0
@export var attack_range: float = 30.0
@export var detection_range: float = 180.0
@export var attack_cooldown: float = 2.0
@export var windup_time: float = 0.6
@export var unparryable_chance: float = 0.2

var current_state: State = State.IDLE
var target_player: Player = null
var facing_direction: int = -1
var attack_timer: float = 1.0
var windup_timer: float = 0.0
var next_attack_unparryable: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

# Biến đếm nhịp hoạt họa động cho quái
var anim_step_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_hitbox: Hitbox = $AttackHitbox
@onready var hp_fill: ColorRect = get_node_or_null("FloatingUI/HPBarBorder/HPBarFill")
@onready var hp_label: Label = get_node_or_null("FloatingUI/HPLabel")
@onready var telegraph_icon: Sprite2D = get_node_or_null("FloatingUI/TelegraphIcon")
@onready var push_area: PushArea = get_node_or_null("PushArea")
@onready var anim_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

const ICON_PARRY = preload("res://assets/sprites/vfx/telegraph_parry_star.png")
const ICON_DANGER = preload("res://assets/sprites/vfx/telegraph_danger_eye.png")
var drop_item_scene = null

func _ready() -> void:
	current_hp = max_hp
	if ResourceLoader.exists("res://scenes/DropItem.tscn"):
		drop_item_scene = load("res://scenes/DropItem.tscn")
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
		attack_hitbox.damage = attack_damage
	if telegraph_icon:
		telegraph_icon.visible = false
	_update_hp_bar()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y += 900.0 * delta

	# Process knockback
	if knockback_velocity.length_squared() > 1.0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)
		velocity.x = knockback_velocity.x
	else:
		_process_ai_state(delta)

	if push_area:
		var push_vec = push_area.get_push_vector()
		velocity += push_vec * delta

	move_and_slide()
	_update_facing()
	_update_sprite_animation(delta)

func _update_sprite_animation(delta: float) -> void:
	if not sprite:
		return
	if anim_player and anim_player.is_playing():
		return

	# Cập nhật khung hình hoạt họa theo trạng thái
	match current_state:
		State.IDLE:
			sprite.frame = 0
		State.CHASE, State.PATROL:
			if abs(velocity.x) > 5.0:
				anim_step_timer += delta * 6.0
				var frames_count = max(1, sprite.hframes)
				sprite.frame = int(anim_step_timer) % frames_count
			else:
				sprite.frame = 0
		State.WINDUP:
			sprite.frame = min(sprite.hframes - 1, 1)
		State.ATTACK:
			sprite.frame = min(sprite.hframes - 1, 2)
		State.HURT:
			sprite.frame = min(sprite.hframes - 1, 1)

func _process_ai_state(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		_find_player()
		velocity.x = 0.0
		return

	var dist_to_player = global_position.distance_to(target_player.global_position)
	var dir_to_player = sign(target_player.global_position.x - global_position.x)
	if dir_to_player != 0:
		facing_direction = int(dir_to_player)

	match current_state:
		State.IDLE:
			velocity.x = 0.0
			attack_timer -= delta
			if dist_to_player <= detection_range:
				current_state = State.CHASE
		State.CHASE:
			if dist_to_player <= attack_range and attack_timer <= 0.0:
				_start_windup()
			elif dist_to_player > attack_range:
				velocity.x = facing_direction * move_speed
			else:
				velocity.x = 0.0
				attack_timer -= delta
		State.WINDUP:
			velocity.x = 0.0
			windup_timer -= delta
			if windup_timer <= 0.0:
				_execute_attack()
		State.ATTACK:
			velocity.x = 0.0
		State.HURT:
			velocity.x = 0.0

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
	else:
		var p = get_node_or_null("../../Player")
		if p is Player:
			target_player = p

func _start_windup() -> void:
	current_state = State.WINDUP
	windup_timer = windup_time
	next_attack_unparryable = (randf() < unparryable_chance)
	_show_telegraph(next_attack_unparryable)
	attack_warning_started.emit(next_attack_unparryable)
	if anim_player and anim_player.has_animation("windup"):
		anim_player.play("windup")

func _show_telegraph(unparryable: bool) -> void:
	if not telegraph_icon:
		return
	telegraph_icon.texture = ICON_DANGER if unparryable else ICON_PARRY
	telegraph_icon.visible = true
	telegraph_icon.scale = Vector2(0.2, 0.2)
	telegraph_icon.modulate = Color(2.5, 2.5, 2.5, 0.0) if not unparryable else Color(2.0, 0.5, 0.5, 0.0)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(telegraph_icon, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(telegraph_icon, "modulate:a", 1.0, 0.08)

func _hide_telegraph() -> void:
	if telegraph_icon:
		telegraph_icon.visible = false

func _execute_attack() -> void:
	current_state = State.ATTACK
	_hide_telegraph()
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
	elif sprite:
		sprite.frame = min(sprite.hframes - 1, 2)
		
	if attack_hitbox:
		attack_hitbox.damage = attack_damage
		attack_hitbox.is_unparryable = next_attack_unparryable
		attack_hitbox.monitoring = true
		attack_hitbox.monitorable = true
		
	await get_tree().create_timer(0.2).timeout
	
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
		
	current_state = State.IDLE
	attack_timer = attack_cooldown

func _on_hit_received(incoming_hitbox: Hitbox) -> void:
	if current_state == State.DEAD:
		return
		
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
	_update_hp_bar()

	# Knockback & Combat VFX
	var attack_dir = Vector2.RIGHT
	if incoming_hitbox.owner and incoming_hitbox.owner is Node2D:
		attack_dir = (global_position - (incoming_hitbox.owner as Node2D).global_position).normalized()
	knockback_velocity = Vector2(sign(attack_dir.x) if sign(attack_dir.x) != 0 else 1.0, 0.0) * 110.0

	# Spawn Damage Number, Sparks, Blood
	VFXManager.spawn_combat_impact(get_parent(), global_position + Vector2(0, -14), attack_dir, dmg, incoming_hitbox.is_crit, false)

	# Flash white
	if sprite:
		sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
		await get_tree().create_timer(0.07).timeout
		if is_instance_valid(sprite):
			sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if current_hp <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	_hide_telegraph()
	if attack_hitbox:
		attack_hitbox.monitoring = false
		attack_hitbox.monitorable = false
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	set_collision_layer_value(2, false)

	_spawn_loot_drops()
	died.emit(self)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(queue_free)

func _spawn_loot_drops() -> void:
	if not drop_item_scene:
		return
		
	var player_hp_pct = 1.0
	if target_player:
		player_hp_pct = target_player.current_hp / max(1.0, target_player.max_hp)

	# Mercy drop algorithm (detail.md VII.2)
	var life_shard_chance = 0.25
	var life_flask_chance = 0.05
	if player_hp_pct < 0.3:
		life_shard_chance = 0.60
		life_flask_chance = 0.35
	elif player_hp_pct < 0.7:
		life_shard_chance = 0.30
		life_flask_chance = 0.12

	if is_elite:
		life_flask_chance = 0.50
		_drop_item("heart_core")

	if randf() < life_shard_chance:
		_drop_item("life_shard")
	if randf() < life_flask_chance:
		_drop_item("life_flask")
	if randf() < 0.4:
		_drop_item("upgrade_crystal")

	var weapon_chance = 0.25 if not is_elite else 0.85
	if is_boss:
		weapon_chance = 1.0

	if randf() < weapon_chance:
		var tier = "tier_d"
		if is_boss:
			var r = randf()
			tier = "tier_ssr" if r < 0.15 else ("tier_sr" if r < 0.5 else "tier_r")
		elif is_elite:
			var r = randf()
			tier = "tier_r" if r < 0.2 else ("tier_a" if r < 0.6 else "tier_b")
		else:
			var r = randf()
			tier = "tier_b" if r < 0.1 else ("tier_c" if r < 0.4 else "tier_d")
			
		# 50% rơi vũ khí, 50% rơi mảnh giáp (Mũ, Áo, Tay, Chân)
		if randf() < 0.5:
			_drop_item(tier) # Vũ khí
		else:
			var parts = ["armor_helmet_", "armor_chest_", "armor_arms_", "armor_legs_"]
			var chosen_part = parts[randi() % parts.size()]
			_drop_item(chosen_part + tier)

func _drop_item(item_type: String) -> void:
	if not drop_item_scene:
		return
	var drop = drop_item_scene.instantiate()
	# Spawn rơi trên mặt sàn chuẩn
	drop.global_position = Vector2(global_position.x + randf_range(-14, 14), global_position.y - 10)
	drop.base_ground_pos_y = 192.0
	drop.item_type = item_type
	get_parent().add_child(drop)

func apply_knockback(dir: Vector2, force: float = 120.0) -> void:
	knockback_velocity = dir.normalized() * force

func _update_hp_bar() -> void:
	if hp_label:
		hp_label.text = "%d/%d" % [round(current_hp), round(max_hp)]
	if hp_fill:
		var ratio = clampf(current_hp / max(1.0, max_hp), 0.0, 1.0)
		hp_fill.size.x = 32.0 * ratio

func _update_facing() -> void:
	if sprite:
		sprite.flip_h = (facing_direction > 0)
	if attack_hitbox:
		attack_hitbox.position.x = abs(attack_hitbox.position.x) * (1 if facing_direction > 0 else -1)
