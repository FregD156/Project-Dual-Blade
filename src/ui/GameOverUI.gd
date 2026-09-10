class_name GameOverUI
extends Control

## GameOverUI - Bảng thông báo Tử Trận (Defeat / Game Over) chuẩn Pixel-Art
## Kèm các tính năng:
## - Thông báo: "NGƯƠI ĐÃ TỬ TRẬN" (Dark Red / Blood Crimson)
## - Nút [CHƠI LẠI (PLAY AGAIN)]: Hồi sinh nhân vật, đặt lại máu & bắt đầu lại
## - Nút [TRANG CHỦ (MAIN MENU)]: Quay trở về màn hình trang chủ
## - Phím tắt nhanh: [SPACE] hoặc [ENTER] để Play Again ngay lập tức

@onready var play_again_btn: Button = find_child("PlayAgainBtn", true, false)
@onready var main_menu_btn: Button = find_child("MainMenuBtn", true, false)
@onready var death_title: Label = find_child("DeathTitle", true, false)
@onready var info_label: Label = find_child("InfoLabel", true, false)

var player_ref: Player = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS # Vẫn bấm được ngay cả khi paused
	
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu_pressed)

func connect_player(player: Player) -> void:
	player_ref = player
	if not player_ref:
		return
	if player_ref.has_signal("player_died"):
		player_ref.player_died.connect(show_game_over)

func show_game_over() -> void:
	visible = true
	modulate.a = 0.0
	
	if info_label and player_ref:
		var tier_str = player_ref.current_weapon_tier.replace("tier_", "").to_upper()
		info_label.text = "Vũ khí: Song Đao Bậc %s  |  Tinh thể: %d" % [tier_str, player_ref.upgrade_crystals]
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	if play_again_btn:
		play_again_btn.grab_focus()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_play_again_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			_on_main_menu_pressed()
			get_viewport().set_input_as_handled()

func _on_play_again_pressed() -> void:
	# Reload lại toàn bộ màn chơi hoặc reset vị trí & máu của player
	visible = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	visible = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
