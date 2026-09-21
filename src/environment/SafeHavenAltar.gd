class_name SafeHavenAltar
extends Area2D

## Safe Haven (Trạm Nghỉ An Toàn 1.9 theo detail.md):
## - Bệ Thờ / Đài Tế: Chạm vào hoặc bấm E/J để phục hồi 100% Máu & đầy 3 Bình Máu Lớn
## - Bàn Thợ Rèn (Lão Thợ Rèn Vulcan Tàn Diệt): Hỗ trợ mở túi đồ nâng cấp / tẩy dòng

signal player_rested()

@export var world_index: int = 1:
	set(val):
		world_index = val
		if is_node_ready():
			_apply_world_theme_colors()

@onready var prompt_label: Label = $PromptLabel
@onready var flame_aura: Sprite2D = get_node_or_null("SanctuaryFlameAura")
@onready var flame_core: Sprite2D = get_node_or_null("SanctuaryFlameCore")
@onready var monolith: Sprite2D = get_node_or_null("AltarMonolith")
@onready var warp_beam: Sprite2D = get_node_or_null("TeleportWarpBeam")

var player_in_range: Player = null
var has_used: bool = false
var current_dialogue_idx: int = 0
var haven_dialogues: Array[Dictionary] = []

var anim_timer: float = 0.0
var current_frame: int = 0
const FRAME_TIME: float = 0.09

var beam_anim_timer: float = 0.0
var beam_frame: int = 0
var is_channeling: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 # Player hurtbox / player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	haven_dialogues = DialogueManager.get_dialogue_for_haven(world_index)
	if prompt_label:
		prompt_label.visible = false
	_apply_world_theme_colors()

func _apply_world_theme_colors() -> void:
	if not is_node_ready():
		return
	# Cấu hình màu sắc ngọn lửa thánh và hoa văn đài tế theo từng Thế giới
	var flame_color = Color(0.2, 1.0, 0.65, 0.75) # Mặc định xanh ngọc phục sinh
	var core_color = Color(0.75, 1.2, 0.9, 0.95)
	var stone_tint = Color(1.0, 1.0, 1.0, 1.0)
	
	match world_index:
		1:
			flame_color = Color(0.2, 0.9, 1.0, 0.75) # Xanh lam thần thánh Cổ Thành
			core_color = Color(0.7, 1.1, 1.3, 0.95)
			stone_tint = Color(0.9, 0.95, 1.05, 1.0)
		2:
			flame_color = Color(0.15, 1.0, 0.5, 0.75) # Xanh ngọc thanh tẩy độc dược Huyết Rễ
			core_color = Color(0.65, 1.3, 0.8, 0.95)
			stone_tint = Color(0.85, 1.05, 0.9, 1.0)
		3:
			flame_color = Color(1.0, 0.8, 0.25, 0.75) # Lửa hơi nước vàng hổ phách Cơ Giới
			core_color = Color(1.3, 1.1, 0.6, 0.95)
			stone_tint = Color(1.05, 1.0, 0.85, 1.0)
		4:
			flame_color = Color(0.85, 0.35, 1.0, 0.75) # Lửa tím hư không Đền Thờ
			core_color = Color(1.2, 0.8, 1.3, 0.95)
			stone_tint = Color(1.0, 0.85, 1.1, 1.0)
			
	if flame_aura:
		flame_aura.modulate = flame_color
	if flame_core:
		flame_core.modulate = core_color
	if warp_beam:
		warp_beam.modulate = core_color
	if monolith:
		monolith.modulate = stone_tint

func _process(delta: float) -> void:
	# Hoạt ảnh ngọn lửa thánh bập bùng
	anim_timer += delta
	if anim_timer >= FRAME_TIME:
		anim_timer -= FRAME_TIME
		current_frame = (current_frame + 1) % 8
		if flame_aura:
			flame_aura.frame = current_frame
		if flame_core:
			flame_core.frame = (current_frame + 2) % 8

	# Hoạt ảnh cột sáng thanh tẩy / dịch chuyển
	if is_channeling and warp_beam:
		beam_anim_timer += delta
		if beam_anim_timer >= 0.05:
			beam_anim_timer -= 0.05
			beam_frame += 1
			if beam_frame >= 8:
				is_channeling = false
				warp_beam.visible = false
			else:
				warp_beam.frame = beam_frame

	# Nhịp thở xung điện từ của đài tế
	var time_ms = Time.get_ticks_msec()
	if flame_aura:
		var pulse = 0.8 + 0.06 * sin(time_ms * 0.005)
		flame_aura.scale = Vector2(pulse, pulse)
	if flame_core:
		var pulse_core = 0.65 + 0.04 * cos(time_ms * 0.006)
		flame_core.scale = Vector2(pulse_core, pulse_core)

	if player_in_range and (Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("attack")):
		rest_at_altar()

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_show_player_prompt(body)

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		_hide_player_prompt()

func _on_area_entered(area: Area2D) -> void:
	if area.owner is Player:
		_show_player_prompt(area.owner)

func _on_area_exited(area: Area2D) -> void:
	if area.owner == player_in_range:
		_hide_player_prompt()

func _show_player_prompt(player: Player) -> void:
	player_in_range = player
	if prompt_label:
		prompt_label.visible = true
		prompt_label.text = "[E/Chém]: ĐÀI TẾ HỒI PHỤC  |  [M]: BẢN ĐỒ DỊCH CHUYỂN"
		prompt_label.modulate = Color(0.2, 1.0, 0.6)

func _hide_player_prompt() -> void:
	player_in_range = null
	if prompt_label:
		prompt_label.visible = false

func trigger_checkpoint_warp_animation() -> void:
	# Kích hoạt hiệu ứng cột sáng không gian khi player dịch chuyển tới đây
	is_channeling = true
	beam_frame = 0
	beam_anim_timer = 0.0
	if warp_beam:
		warp_beam.visible = true
		warp_beam.frame = 0

func rest_at_altar() -> void:
	if not player_in_range:
		return
		
	# Hồi đầy máu
	player_in_range.current_hp = player_in_range.max_hp
	player_in_range.emit_signal("hp_changed", player_in_range.current_hp, player_in_range.max_hp)
	
	# Hồi đầy 3 bình máu
	player_in_range.life_flasks = player_in_range.max_flasks
	player_in_range.emit_signal("flasks_changed", player_in_range.life_flasks, player_in_range.max_flasks)
	
	# Hồi đầy 100% Giáp bảo vệ
	if player_in_range.has_method("refill_armor_after_round"):
		player_in_range.refill_armor_after_round()
	
	# 1. Bật cột sáng thánh thanh tẩy (Sanctuary Beam)
	trigger_checkpoint_warp_animation()
	
	# 2. Hiệu ứng ánh sáng thanh tẩy bừng sáng trên người nhân vật (Purifying Light)
	if player_in_range.sprite:
		var tween = create_tween()
		tween.tween_property(player_in_range.sprite, "modulate", Color(0.2, 1.6, 0.7, 1.0), 0.25)
		tween.tween_property(player_in_range.sprite, "modulate", Color.WHITE, 0.3)
		
	# 3. Rung chấn mặt đất nhẹ khi kích hoạt thánh địa
	if player_in_range.has_node("Camera2D"):
		var cam: Camera2D = player_in_range.get_node("Camera2D")
		if cam:
			VFXManager.screen_shake(cam, 2.0, 0.2)
		
	# 4. Hiệu ứng ngọn lửa đài tế bùng sáng khi ban phước
	if flame_aura:
		var tw_flame = create_tween()
		tw_flame.tween_property(flame_aura, "scale", Vector2(1.25, 1.35), 0.15)
		tw_flame.tween_property(flame_aura, "scale", Vector2(0.8, 0.8), 0.25)
		
	if prompt_label:
		if haven_dialogues.size() > 0:
			var d = haven_dialogues[current_dialogue_idx % haven_dialogues.size()]
			prompt_label.text = "[%s]: \"%s\"" % [d["speaker"], d["text"]]
			current_dialogue_idx += 1
		else:
			prompt_label.text = "✦ ĐÃ PHỤC HỒI ĐẦY 100% HP & 3 BÌNH MÁU! ✦"
		prompt_label.modulate = Color(0.3, 1.0, 0.5)
		
	player_rested.emit()
