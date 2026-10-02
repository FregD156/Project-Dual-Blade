class_name SafeHavenAltar3D
extends Area3D

## Safe Haven (Trạm Nghỉ An Toàn 1.9 3D theo detail.md):
## - Bệ Thờ / Đài Tế Hoàng Gia: Bấm E / J hoặc chạm vào để hồi 100% HP, Giáp và đầy 3 Bình Máu
## - Lưu mốc Checkpoint an toàn trước khi vào cửa Boss 1.10

signal player_rested()

@onready var prompt_label: Label3D = $PromptLabel
@onready var altar_light: OmniLight3D = $AltarLight
@onready var monolith_sprite: Sprite3D = $MonolithSprite

var player_in_range: Node3D = null
var pulse_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if prompt_label:
		prompt_label.visible = false

func _process(delta: float) -> void:
	pulse_timer += delta * 2.5
	if altar_light:
		altar_light.light_energy = 2.0 + sin(pulse_timer) * 0.8
		
	if player_in_range and (Input.is_key_pressed(KEY_E) or Input.is_action_just_pressed("attack")):
		rest_at_altar()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_in_range = body
		if prompt_label:
			prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body == player_in_range:
		player_in_range = null
		if prompt_label:
			prompt_label.visible = false

func rest_at_altar() -> void:
	if not player_in_range:
		return
		
	# Hồi phục HP
	if "current_hp" in player_in_range and "max_hp" in player_in_range:
		player_in_range.current_hp = player_in_range.max_hp
		if player_in_range.has_signal("hp_changed"):
			player_in_range.hp_changed.emit(player_in_range.current_hp, player_in_range.max_hp)
			
	# Hồi phục Giáp
	if "current_armor" in player_in_range and "max_armor" in player_in_range:
		player_in_range.current_armor = player_in_range.max_armor
		if player_in_range.has_signal("armor_changed"):
			player_in_range.armor_changed.emit(player_in_range.current_armor, player_in_range.max_armor)
			
	# Hồi đầy 3 bình máu
	if "life_flasks" in player_in_range and "max_flasks" in player_in_range:
		player_in_range.life_flasks = player_in_range.max_flasks
		if player_in_range.has_signal("flasks_changed"):
			player_in_range.flasks_changed.emit(player_in_range.life_flasks, player_in_range.max_flasks)

	# Hiệu ứng hào quang
	if altar_light:
		var tw = create_tween()
		tw.tween_property(altar_light, "light_energy", 6.0, 0.2)
		tw.tween_property(altar_light, "light_energy", 2.5, 0.4)

	player_rested.emit()
	if prompt_label:
		prompt_label.text = "✨ ĐÃ HỒI PHỤC TOÀN BỘ SINH LỰC & BÌNH MÁU! ✨"
		prompt_label.modulate = Color(0.3, 1.2, 0.6)
