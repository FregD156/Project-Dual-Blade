class_name EnemyBase3D
extends CharacterBody3D

## Lớp cơ sở cho Quái Vật 3D trong Project Dual Blade (Khóa trục Z)
## Quản lý máu, giáp, hiệu ứng trúng đòn, knockback và rơi đồ

signal enemy_died(enemy: EnemyBase3D)
signal hp_changed(curr: float, max_v: float)

const DamageNumber3D = preload("res://src_3d/vfx/DamageNumber3D.gd")
const SpawnPoint3D = preload("res://src_3d/world/SpawnPoint3D.gd")

@export_group("Stats")
@export var enemy_name: String = "Quái Vật"
@export var max_hp: float = 120.0
var current_hp: float = 120.0
@export var base_atk: float = 15.0
@export var def: float = 0.0 # Giáp phòng thủ theo Detail.md Phần D
@export var resist: float = 0.0 # Kháng sát thương %
@export var move_speed: float = 3.2
@export var gravity: float = 28.0

@export_group("Tier & Spawning")
@export var assigned_tier: int = 1
var last_valid_position: Vector3 = Vector3.ZERO
var stuck_timer: float = 0.0
var stuck_count: int = 0
var last_check_pos: Vector3 = Vector3.ZERO
const STUCK_TIME_THRESHOLD: float = 2.0
const MIN_MOVE_DISTANCE: float = 0.08
const DEATH_Y_THRESHOLD: float = -4.0

var facing_direction: int = -1 # -1 = trái, 1 = phải
var is_dead: bool = false
var flash_timer: float = 0.0

@onready var visual_root: Node3D = $VisualRoot

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")
	last_valid_position = global_position
	last_check_pos = global_position
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(46.0)

func _physics_process(delta: float) -> void:
	global_position.z = 0.0
	
	if is_dead:
		_apply_gravity(delta)
		move_and_slide()
		return
		
	# 1. Kiểm tra rơi khỏi map
	if global_position.y < DEATH_Y_THRESHOLD:
		_handle_out_of_bounds()
		return

	# 2. Xử lý hành vi AI
	_process_enemy_behavior(delta)
	
	_apply_gravity(delta)
	move_and_slide()
	
	velocity.z = 0.0
	global_position.z = 0.0
	_update_visual_facing()
	
	# 3. Giám sát kẹt địa hình (Anti-stuck Watchdog)
	_monitor_stuck_state(delta)
	
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0:
			_reset_flash()

func _handle_out_of_bounds() -> void:
	stuck_count += 1
	print("[EnemyBase3D] [CẢNH BÁO] Quái '%s' (%s) rơi dưới vực Y=%.2f, đang phục hồi về sàn..." % [enemy_name, name, global_position.y])
	_recover_to_nearest_spawn_point("fell_out_of_bounds")

func _monitor_stuck_state(delta: float) -> void:
	if not is_on_floor():
		return
		
	# Nếu quái vật đứng yên hoặc di chuyển quá ít (< 0.08m)
	if global_position.distance_to(last_check_pos) < MIN_MOVE_DISTANCE:
		var player = get_player()
		# Chỉ kích hoạt tính thời gian kẹt khi có ý định di chuyển áp sát người chơi
		if player and abs(player.global_position.x - global_position.x) > 1.8:
			stuck_timer += delta
			if stuck_timer >= STUCK_TIME_THRESHOLD:
				stuck_timer = 0.0
				stuck_count += 1
				print("[EnemyBase3D] [CẢNH BÁO] Quái '%s' (%s) đứng yên/kẹt tại %s quá 2.0s, đang phục hồi..." % [enemy_name, name, global_position])
				_recover_to_nearest_spawn_point("stuck_in_geometry")
	else:
		last_check_pos = global_position
		stuck_timer = 0.0
		if global_position.y >= -1.0:
			last_valid_position = global_position

func _recover_to_nearest_spawn_point(reason: String = "recovery") -> void:
	var sps = get_tree().get_nodes_in_group("spawn_points")
	var best_sp: SpawnPoint3D = null
	var min_d: float = 999999.0
	var space_state = get_world_3d().direct_space_state if get_world_3d() else null
	
	for sp in sps:
		if sp is SpawnPoint3D and sp.tier == assigned_tier:
			if space_state:
				var res = sp.validate_location(space_state)
				if not res.get("valid", false):
					continue
			var d = global_position.distance_to(sp.global_position)
			if d < min_d:
				min_d = d
				best_sp = sp
				
	if best_sp:
		global_position = best_sp.global_position
		velocity = Vector3.ZERO
		global_position.z = 0.0
		print("[EnemyBase3D] [PHỤC HỒI THÀNH CÔNG] Quái '%s' (%s) đã dịch về SpawnPoint '%s' tại %s (Lý do: %s)" % [
			enemy_name, name, best_sp.name, global_position, reason
		])
	elif last_valid_position != Vector3.ZERO:
		global_position = last_valid_position
		velocity = Vector3.ZERO
		global_position.z = 0.0
		print("[EnemyBase3D] [PHỤC HỒI THÀNH CÔNG] Quái '%s' (%s) đã về last_valid_position tại %s (Lý do: %s)" % [
			enemy_name, name, global_position, reason
		])

func _process_enemy_behavior(_delta: float) -> void:
	# Ghi đè ở các lớp con
	pass

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if velocity.y < 0:
			velocity.y = 0.0

func _update_visual_facing() -> void:
	if visual_root:
		var sp = visual_root.get_node_or_null("Sprite3D")
		if sp:
			sp.flip_h = (facing_direction > 0)
		else:
			var target_rot_y = deg_to_rad(90.0 if facing_direction > 0 else -90.0)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot_y, 0.25)

func get_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		return players[0]
	return null

func take_hit(amount: float, attacker_pos: Vector3, incoming_crit: bool = false) -> void:
	if is_dead:
		return

	# Tính toán sát thương chuẩn ARPG Detail.md Phần D:
	# Mitigation% = DEF / (DEF + 50)
	# Damage = max(1, ATK * (1 - Mitigation%) * (1 - Resist%))
	var calc_res = DamageCalculator.calculate_damage(amount, 1.0, def, resist, 50.0, incoming_crit)
	var final_dmg: float = calc_res.get("damage", amount)
	var is_crit: bool = calc_res.get("is_crit", incoming_crit)
		
	current_hp = max(0.0, current_hp - final_dmg)
	hp_changed.emit(current_hp, max_hp)
	
	flash_timer = 0.12
	_flash_white()
	
	# Đẩy lùi theo trục X
	var dir_x = sign(global_position.x - attacker_pos.x)
	if dir_x == 0: dir_x = 1
	velocity.x = dir_x * 4.2
	velocity.y = 2.0
	
	# Hiện số sát thương 3D
	if get_parent():
		var num = DamageNumber3D.new()
		get_parent().add_child(num)
		num.setup(final_dmg, global_position + Vector3(0, 1.4, 0), is_crit, false)
		
	if current_hp <= 0.0:
		die()

func _flash_white() -> void:
	for sp in find_children("*", "Sprite3D"):
		if sp is Sprite3D:
			sp.modulate = Color(3.0, 1.2, 1.2)
	for m in find_children("*", "MeshInstance3D"):
		if m is MeshInstance3D and m.material_override:
			if m.material_override is ShaderMaterial:
				m.material_override.set_shader_parameter("emission_color", Color(1.5, 0.4, 0.4))
				m.material_override.set_shader_parameter("emission_energy", 3.0)

func _reset_flash() -> void:
	for sp in find_children("*", "Sprite3D"):
		if sp is Sprite3D:
			sp.modulate = Color.WHITE
	for m in find_children("*", "MeshInstance3D"):
		if m is MeshInstance3D and m.material_override:
			if m.material_override is ShaderMaterial:
				m.material_override.set_shader_parameter("emission_energy", 0.0)

const DROP_ITEM_SCENE = preload("res://scenes_3d/DropItem3D.tscn")

func die(reason: String = "hp_depleted") -> void:
	if is_dead:
		return
	print("[EnemyBase3D] [TIÊU DIỆT] Quái '%s' (%s) tử nạn/xóa bỏ với lý do: '%s' | Vị trí: %s | HP: %.1f/%.1f" % [
		enemy_name, name, reason, global_position, current_hp, max_hp
	])
	is_dead = true
	enemy_died.emit(self)
	_spawn_loot()
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(0.0, 0.0, 0.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)

func _spawn_loot() -> void:
	if not DROP_ITEM_SCENE or not get_parent():
		return
	var player = get_player()
	var player_low_hp = false
	if player and "current_hp" in player and "max_hp" in player:
		player_low_hp = (player.current_hp / player.max_hp) < 0.35
		
	var roll = randf()
	# 1. Hạt Sinh Mệnh (Mercy Drop theo detail.md VII)
	if roll < (0.60 if player_low_hp else 0.30):
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(0, 0.4, 0)
		item.setup(DropItem3D.ItemType.LIFE_SHARD, DropItem3D.Rarity.D, "Hạt Sinh Mệnh")
	# 2. Vũ Khí Song Đao (Bậc D hoặc C)
	elif roll < 0.55:
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.4, 0)
		var r = DropItem3D.Rarity.C if randf() < 0.35 else DropItem3D.Rarity.D
		var w_name = "Song Đao Thép Thô" if r == DropItem3D.Rarity.C else "Song Đao Rỉ Sét"
		item.setup(DropItem3D.ItemType.WEAPON, r, w_name)
	# 3. Mảnh Giáp 4 bộ phận (Helmet, Chest, Arms, Legs)
	elif roll < 0.75:
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.4, 0)
		var parts = ["helmet", "chest", "arms", "legs"]
		var p_chosen = parts.pick_random()
		var r = DropItem3D.Rarity.C if randf() < 0.3 else DropItem3D.Rarity.D
		var part_display = ArmorSystem.PART_NAMES.get(p_chosen, "Mảnh Giáp")
		item.setup(DropItem3D.ItemType.ARMOR, r, part_display, p_chosen)
	# 4. Khiên Hộ Thân (Shield)
	elif roll < 0.90:
		var item = DROP_ITEM_SCENE.instantiate()
		get_parent().add_child(item)
		item.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 0.4, 0)
		var r = DropItem3D.Rarity.C if randf() < 0.3 else DropItem3D.Rarity.D
		var s_name = "Khiên Sắt Tân Binh" if r == DropItem3D.Rarity.C else "Khiên Gỗ Rỉ"
		item.setup(DropItem3D.ItemType.SHIELD, r, s_name)
