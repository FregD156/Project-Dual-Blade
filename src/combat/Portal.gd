class_name Portal
extends Area2D

## Portal đại diện cho Cổng Dịch Chuyển Phân Nhánh Phòng theo detail.md IV.2:
## - Combat Portal (Cổng Đao Kiếm): Màu đỏ/cam rực lửa, tăng quái/tinh anh, tỷ lệ rơi phôi trang bị cao.
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

signal player_chosen_portal(type: PortalType)

@onready var vortex_aura: Sprite2D = get_node_or_null("VortexAura")
@onready var vortex_core: Sprite2D = get_node_or_null("VortexCore")
@onready var gothic_frame: Sprite2D = get_node_or_null("GothicArchFrame")
@onready var label: Label = $Label
@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var desc_label: Label = get_node_or_null("DescLabel")

var player_in_range: Player = null
var is_active: bool = false
var anim_timer: float = 0.0
var current_frame: int = 0
const FRAME_TIME: float = 0.08 # 12.5 FPS cho hoạt ảnh xoáy mượt mà

func _ready() -> void:
	collision_layer = 128
	collision_mask = 2 # Player CharacterBody2D layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visuals()

func setup(type: PortalType) -> void:
	portal_type = type
	_update_visuals()

func _update_visuals() -> void:
	if not is_node_ready():
		return

	match portal_type:
		PortalType.COMBAT:
			if vortex_aura:
				vortex_aura.modulate = Color(1.0, 0.25, 0.1, 0.65) # Đỏ cam rực lửa
			if vortex_core:
				vortex_core.modulate = Color(1.3, 0.85, 0.3, 0.95)
			if gothic_frame:
				gothic_frame.modulate = Color(1.1, 0.75, 0.7, 1.0)
			if title_label:
				title_label.text = "⚔ CỔNG ĐAO KIẾM"
				title_label.modulate = Color(1.0, 0.4, 0.3)
			if desc_label:
				desc_label.text = "Mật độ quái dày • Tăng rơi phôi trang bị"
				desc_label.modulate = Color(1.0, 0.85, 0.5)
			if label:
				label.text = "[W / UP / E] VÀO CHIẾN TRẬN"
				label.modulate = Color(1.0, 0.4, 0.3)
		PortalType.SUSTAIN:
			if vortex_aura:
				vortex_aura.modulate = Color(0.1, 1.0, 0.45, 0.65) # Xanh ngọc sinh mệnh
			if vortex_core:
				vortex_core.modulate = Color(0.6, 1.2, 0.9, 0.95)
			if gothic_frame:
				gothic_frame.modulate = Color(0.7, 1.1, 0.85, 1.0)
			if title_label:
				title_label.text = "❤ CỔNG SINH MỆNH"
				title_label.modulate = Color(0.2, 1.0, 0.6)
			if desc_label:
				desc_label.text = "Quái thưa • Chắc chắn rớt Bình Máu"
				desc_label.modulate = Color(0.6, 1.0, 0.8)
			if label:
				label.text = "[W / UP / E] VÀO BẢO TOÀN"
				label.modulate = Color(0.2, 1.0, 0.6)
		PortalType.STANDARD:
			if vortex_aura:
				vortex_aura.modulate = Color(0.2, 0.75, 1.2, 0.65) # Xanh lam thần bí
			if vortex_core:
				vortex_core.modulate = Color(0.85, 1.1, 1.3, 0.95)
			if gothic_frame:
				gothic_frame.modulate = Color(0.85, 0.95, 1.1, 1.0)
			if title_label:
				title_label.text = "✦ CỔNG TIẾN BƯỚC"
				title_label.modulate = Color(0.4, 0.9, 1.0)
			if desc_label:
				desc_label.text = "Đường tới ải tiếp theo"
				desc_label.modulate = Color(0.8, 0.9, 1.0)
			if label:
				label.text = "[W / UP / E] VÀO ẢI TIẾP THEO"
				label.modulate = Color(0.4, 0.9, 1.0)

func activate() -> void:
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	
	# Hiệu ứng xuất hiện nở bừng mượt mà
	scale = Vector2(0.1, 0.1)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.35)

func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	player_in_range = null

func _process(delta: float) -> void:
	if not is_active or not visible:
		return
		
	# Hoạt ảnh lốc xoáy ma thuật 8 frames
	anim_timer += delta
	if anim_timer >= FRAME_TIME:
		anim_timer -= FRAME_TIME
		current_frame = (current_frame + 1) % 8
		if vortex_aura:
			vortex_aura.frame = current_frame
		if vortex_core:
			# Lõi xoay lệch pha tạo chiều sâu 3D 2 lớp
			vortex_core.frame = (current_frame + 4) % 8

	# Hiệu ứng nhấp nhô & xung nhịp năng lượng
	var time_ms = Time.get_ticks_msec()
	if vortex_aura:
		var pulse = 1.05 + 0.08 * sin(time_ms * 0.005)
		vortex_aura.scale = Vector2(pulse, pulse)
	if vortex_core:
		var pulse_inner = 0.85 + 0.06 * cos(time_ms * 0.006)
		vortex_core.scale = Vector2(pulse_inner, pulse_inner)

	# Kiểm tra người chơi kích hoạt cổng
	if player_in_range and is_instance_valid(player_in_range):
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_UP):
			_trigger_portal()

func _trigger_portal() -> void:
	if not is_active:
		return
	is_active = false
	set_deferred("monitoring", false)
	
	player_chosen_portal.emit(portal_type)
	
	# Hiệu ứng hút xoáy thu nhỏ rồi biến mất
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.35, 1.35), 0.1)
	tw.tween_property(self, "modulate:a", 0.0, 0.2).set_delay(0.08)
	tw.chain().tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
