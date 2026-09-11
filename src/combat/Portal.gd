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

@onready var glow: ColorRect = $PortalGlow
@onready var core: ColorRect = $PortalCore
@onready var label: Label = $Label
@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var desc_label: Label = get_node_or_null("DescLabel")

var player_in_range: Player = null
var is_active: bool = false

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
	if not glow or not core or not label:
		return

	match portal_type:
		PortalType.COMBAT:
			glow.color = Color(1.0, 0.25, 0.15, 0.65) # Đỏ cam chiến trận
			core.color = Color(1.0, 0.9, 0.4, 0.9)
			if title_label:
				title_label.text = "⚔ CỔNG ĐAO KIẾM"
				title_label.modulate = Color(1.0, 0.4, 0.3)
			if desc_label:
				desc_label.text = "Mật độ quái dày • Tăng rơi phôi trang bị"
				desc_label.modulate = Color(1.0, 0.85, 0.5)
			label.text = "[W / UP / E] VÀO CHIẾN TRẬN"
			label.modulate = Color(1.0, 0.4, 0.3)
		PortalType.SUSTAIN:
			glow.color = Color(0.15, 0.95, 0.5, 0.65) # Xanh ngọc sinh mệnh
			core.color = Color(0.7, 1.0, 0.9, 0.9)
			if title_label:
				title_label.text = "❤ CỔNG SINH MỆNH"
				title_label.modulate = Color(0.2, 1.0, 0.6)
			if desc_label:
				desc_label.text = "Quái thưa • Chắc chắn rớt Bình Máu"
				desc_label.modulate = Color(0.6, 1.0, 0.8)
			label.text = "[W / UP / E] VÀO BẢO TOÀN"
			label.modulate = Color(0.2, 1.0, 0.6)
		PortalType.STANDARD:
			glow.color = Color(0.2, 0.8, 1.0, 0.55) # Xanh lam thần bí
			core.color = Color(0.9, 1.0, 1.0, 0.85)
			if title_label:
				title_label.text = "✦ CỔNG TIẾN BƯỚC"
				title_label.modulate = Color(0.4, 0.9, 1.0)
			if desc_label:
				desc_label.text = "Đường tới ải tiếp theo"
				desc_label.modulate = Color(0.8, 0.9, 1.0)
			label.text = "[W / UP / E] VÀO ẢI TIẾP THEO"
			label.modulate = Color(0.4, 0.9, 1.0)

func activate() -> void:
	is_active = true
	visible = true
	set_deferred("monitoring", true)
	
	# Hiệu ứng xuất hiện nở bừng
	scale = Vector2(0.1, 0.1)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.35)

func deactivate() -> void:
	is_active = false
	visible = false
	set_deferred("monitoring", false)
	player_in_range = null

func _process(_delta: float) -> void:
	if not is_active or not visible:
		return
		
	# Hiệu ứng xung nhịp năng lượng của cổng (Pulsing Glow)
	if glow:
		var pulse = 0.55 + 0.15 * sin(Time.get_ticks_msec() * 0.005)
		glow.color.a = pulse

	# Kiểm tra người chơi kích hoạt cổng
	if player_in_range and is_instance_valid(player_in_range):
		if Input.is_action_just_pressed("move_up") or Input.is_action_just_pressed("jump") or Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_UP):
			_trigger_portal()

func _trigger_portal() -> void:
	if not is_active:
		return
	is_active = false
	set_deferred("monitoring", false)
	
	# Emit signal lựa chọn cổng ngay lập tức
	player_chosen_portal.emit(portal_type)
	
	# Hiệu ứng phóng to và tan biến
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tw.tween_property(self, "scale", Vector2(0.0, 0.0), 0.15)
	tw.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_in_range = body
		# Nhấn trực tiếp hoặc bấm nút W/E
		if not is_active:
			return

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
