class_name SafeHavenAltar
extends Area2D

## Safe Haven (Trạm Nghỉ An Toàn 1.9 theo detail.md):
## - Bệ Thờ / Đài Tế: Chạm vào hoặc bấm E/J để phục hồi 100% Máu & đầy 3 Bình Máu Lớn
## - Bàn Thợ Rèn (Lão Thợ Rèn Vulcan Tàn Diệt): Hỗ trợ mở túi đồ nâng cấp / tẩy dòng

signal player_rested()

@onready var prompt_label: Label = $PromptLabel

var player_in_range: Player = null
var has_used: bool = false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 4 # Player hurtbox / player layer
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	if prompt_label:
		prompt_label.visible = false

func _process(_delta: float) -> void:
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
		prompt_label.text = "[E hoặc Chém]: ĐÀI TẾ HỒI PHỤC HOÀN TOÀN"
		prompt_label.modulate = Color(0.2, 1.0, 0.6)

func _hide_player_prompt() -> void:
	player_in_range = null
	if prompt_label:
		prompt_label.visible = false

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
	
	# Hiệu ứng ánh sáng thanh tẩy (Purifying Light)
	if player_in_range.sprite:
		var tween = create_tween()
		tween.tween_property(player_in_range.sprite, "modulate", Color(0.2, 1.5, 0.6, 1.0), 0.25)
		tween.tween_property(player_in_range.sprite, "modulate", Color.WHITE, 0.3)
		
	if prompt_label:
		prompt_label.text = "✦ ĐÃ PHỤC HỒI ĐẦY 100% HP & 3 BÌNH MÁU! ✦"
		prompt_label.modulate = Color(0.3, 1.0, 0.5)
		
	player_rested.emit()
