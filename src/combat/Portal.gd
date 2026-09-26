class_name Portal
extends Area2D

## Portal đại diện cho Cổng Dịch Chuyển Phân Nhánh Phòng theo detail.md IV.2:
## - Combat Portal (Cổng Đao Kiếm): Màu đỏ cam rực lửa, tăng quái/tinh anh, tỷ lệ rơi phôi trang bị cao.
## - Sustain Portal (Cổng Sinh Mệnh): Màu xanh ngọc/lá chữa lành, quái thưa hơn, bảo đảm rơi Hạt Sinh Mệnh/Bình Máu.
## - Standard Portal (Cổng Thường): Dành cho ải đặc biệt (1.4 -> 1.5, 1.8 -> 1.9, 1.9 -> 1.10).

enum PortalType {
	COMBAT,
	SUSTAIN,
	STANDARD
}

@export var portal_type: PortalType = PortalType.STANDARD:
	set(val):
		portal_type = val
		if is_node_ready():
			_update_visuals()

@export var world_index: int = 1:
	set(val):
		world_index = val
		if is_node_ready():
			_update_visuals()

signal player_chosen_portal(type: PortalType)

@onready var gate_vortex: Sprite2D = get_node_or_null("GateVortex")
@onready var gate_frame: Sprite2D = get_node_or_null("GothicGateFrame")
@onready var teleport_burst: Sprite2D = get_node_or_null("TeleportBurst")
@onready var banner_plate: Sprite2D = get_node_or_null("BannerContainer/BannerPlate")
@onready var title_label: Label = get_node_or_null("BannerContainer/TitleLabel")
@onready var desc_label: Label = get_node_or_null("BannerContainer/DescLabel")
@onready var label: Label = get_node_or_null("PromptContainer/Label")
@onready var banner_container: Node2D = get_node_or_null("BannerContainer")
@onready var prompt_container: Node2D = get_node_or_null("PromptContainer")

var player_in_range: Player = null
var is_active: bool = false
var anim_timer: float = 0.0
var current_frame: int = 0
const FRAME_TIME: float = 0.065 # ~15 FPS cho hoạt ảnh 12 frame cực kỳ mượt mà

var burst_anim_timer: float = 0.0
var burst_frame: int = 0
var is_teleporting: bool = false
var base_banner_y: float = -125.0
var base_prompt_y: float = -96.0
var warp_player: Player = null
var player_tween: Tween = null

func _ready() -> void:
	z_index = -1 # Cổng dịch chuyển luôn nằm ở lớp sau (background) để nhân vật hiển thị rõ ràng phía trước
	collision_layer = 128
	collision_mask = 2 # Player CharacterBody2D layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_container:
		prompt_container.visible = false
	_update_visuals()

func setup(type: PortalType, world_idx: int = 1) -> void:
	world_index = world_idx
	portal_type = type
	_update_visuals()

func _update_visuals() -> void:
	if not is_node_ready():
		return

	# Tùy chỉnh màu sắc cánh cổng và hoa văn khung đá Gothic theo Thế giới
	var stone_tint = Color.WHITE
	match world_index:
		1: stone_tint = Color(0.92, 0.95, 1.05, 1.0) # Đá xám Gothic Cổ Thành
		2: stone_tint = Color(0.82, 1.08, 0.85, 1.0) # Rêu phong Huyết Rễ
		3: stone_tint = Color(1.18, 1.02, 0.72, 1.0) # Đồng thau Cơ Giới
		4: stone_tint = Color(0.95, 0.82, 1.25, 1.0) # Đá Hư Vô ma mị

	if gate_frame:
		gate_frame.modulate = stone_tint
	if banner_plate:
		banner_plate.modulate = stone_tint

	match portal_type:
		PortalType.COMBAT:
			var aura_col = Color(1.2, 0.35, 0.15, 0.9)
			if gate_vortex:
				gate_vortex.modulate = aura_col
			if teleport_burst:
				teleport_burst.modulate = Color(1.4, 0.5, 0.2, 1.0)
			if title_label:
				title_label.text = "⚔ CỔNG ĐAO KIẾM"
				title_label.modulate = Color(1.0, 0.45, 0.3)
			if desc_label:
				desc_label.text = "Mật độ quái dày • Tăng rơi phôi"
				desc_label.modulate = Color(1.0, 0.85, 0.6)
			if label:
				label.text = "[W / UP / E] VÀO CHIẾN TRẬN"
				label.modulate = Color(1.0, 0.45, 0.3)

		PortalType.SUSTAIN:
			var aura_col = Color(0.2, 1.15, 0.55, 0.9)
			if gate_vortex:
				gate_vortex.modulate = aura_col
			if teleport_burst:
				teleport_burst.modulate = Color(0.3, 1.3, 0.7, 1.0)
			if title_label:
				title_label.text = "❤ CỔNG SINH MỆNH"
				title_label.modulate = Color(0.3, 1.0, 0.65)
			if desc_label:
				desc_label.text = "Quái thưa • Chắc chắn rơi Bình Máu"
				desc_label.modulate = Color(0.7, 1.0, 0.85)
			if label:
				label.text = "[W / UP / E] VÀO BẢO TOÀN"
				label.modulate = Color(0.3, 1.0, 0.65)

		PortalType.STANDARD:
			var aura_col = Color(0.3, 0.85, 1.3, 0.9)
			if world_index == 2:
				aura_col = Color(0.25, 1.05, 0.8, 0.9)
			elif world_index == 3:
				aura_col = Color(1.25, 0.9, 0.3, 0.9)
			elif world_index == 4:
				aura_col = Color(0.9, 0.4, 1.25, 0.9)

			if gate_vortex:
				gate_vortex.modulate = aura_col
			if teleport_burst:
				teleport_burst.modulate = aura_col
			if title_label:
				title_label.text = "✦ CỔNG TIẾN BƯỚC"
				title_label.modulate = aura_col
			if desc_label:
				desc_label.text = "Đường tới ải tiếp theo"
				desc_label.modulate = Color(0.85, 0.95, 1.0)
			if label:
				label.text = "[W / UP / E] VÀO ẢI TIẾP THEO"
				label.modulate = aura_col

func activate() -> void:
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	
	# Hiệu ứng cổng trồi lên từ sàn đá đất cổ một cách hùng tráng
	scale = Vector2(0.8, 0.05)
	modulate.a = 0.0
	var tw = create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.4)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	player_in_range = null

func _process(delta: float) -> void:
	if not is_active or not visible:
		return
		
	# Hoạt ảnh dòng xoáy hư không 12 khung hình liên tục
	anim_timer += delta
	if anim_timer >= FRAME_TIME:
		anim_timer -= FRAME_TIME
		current_frame = (current_frame + 1) % 12
		if gate_vortex:
			gate_vortex.frame = current_frame

	# Hoạt ảnh vụ nổ không gian khi bước qua cổng
	if is_teleporting and teleport_burst:
		burst_anim_timer += delta
		if burst_anim_timer >= 0.04:
			burst_anim_timer -= 0.04
			burst_frame = min(9, burst_frame + 1)
			teleport_burst.frame = burst_frame

	# Hiệu ứng trôi nổi bảng thông tin nhẹ nhàng
	var time_ms = Time.get_ticks_msec()
	var float_offset = sin(time_ms * 0.0035) * 2.5
	if banner_container:
		banner_container.position.y = base_banner_y + float_offset
	if prompt_container:
		prompt_container.position.y = base_prompt_y + float_offset * 0.5

	# Kiểm tra người chơi kích hoạt cổng
	if player_in_range and is_instance_valid(player_in_range) and not is_teleporting:
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_UP):
			_trigger_portal()

func _trigger_portal() -> void:
	if not is_active or is_teleporting:
		return
	is_teleporting = true
	set_deferred("monitoring", false)
	
	warp_player = player_in_range
	
	# 1. Kích hoạt hiệu ứng Vụ Nổ Dịch Chuyển Không Gian (Teleport Burst)
	if teleport_burst:
		teleport_burst.visible = true
		teleport_burst.frame = 0
		burst_frame = 0
		burst_anim_timer = 0.0

	# 2. Hoạt ảnh hút nhân vật vào cổng chiều không gian (Warp Suction Pull)
	if warp_player and is_instance_valid(warp_player):
		warp_player.velocity = Vector2.ZERO
		if player_tween:
			player_tween.kill()
		player_tween = create_tween().set_parallel(true)
		player_tween.tween_property(warp_player, "global_position", global_position + Vector2(0, -32), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if warp_player.sprite:
			player_tween.tween_property(warp_player.sprite, "modulate:a", 0.0, 0.28)
			player_tween.tween_property(warp_player.sprite, "scale", Vector2(0.01, 0.01), 0.28)

	# Rung chấn màn hình mạnh mẽ khi dịch chuyển
	var cam: Camera2D = null
	if warp_player and is_instance_valid(warp_player) and warp_player.has_node("Camera2D"):
		cam = warp_player.get_node("Camera2D")
	if cam:
		VFXManager.screen_shake(cam, 4.0, 0.28)

	# Chờ hiệu ứng bùng nổ năng lượng hoàn tất
	await get_tree().create_timer(0.38).timeout
	
	# Dừng tween nhân vật và phục hồi hiển thị đầy đủ cho Player TRƯỚC KHI emit chuyển ải
	if player_tween:
		player_tween.kill()
		player_tween = null
	if is_instance_valid(warp_player) and warp_player.sprite:
		warp_player.sprite.modulate.a = 1.0
		warp_player.sprite.scale = Vector2.ONE
	
	player_chosen_portal.emit(portal_type)
	
	# Đảm bảo chắc chắn sprite người chơi hiển thị đầy đủ ở ải mới
	if is_instance_valid(warp_player) and warp_player.sprite:
		warp_player.sprite.modulate.a = 1.0
		warp_player.sprite.scale = Vector2.ONE
	
	# Thu hẹp cổng và biến mất
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale:x", 0.0, 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body
		if prompt_container:
			prompt_container.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		if prompt_container:
			prompt_container.visible = false
