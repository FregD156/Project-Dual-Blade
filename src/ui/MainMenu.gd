class_name MainMenu
extends Control

## Main Menu (Trang chủ chính) - Project Dual Blade
## Thiết kế theo chuẩn giao diện Action RPG Dark Fantasy Pixel-Art 16-bit
## Hỗ trợ:
## - Bàn phím & Chuột: W/S hoặc Lên/Xuống để duyệt menu, Phím Enter / Space / J để chọn
## - Màn hình Cài đặt (Settings / Audio & Keybinds) và Bảng Hướng dẫn điều khiển (Controls Guide)
## - Chuyển cảnh mượt mà (Fade transition) vào gameplay chính (scenes/Main.tscn)

@onready var title_logo: TextureRect = $CenterContainer/VBoxContainer/TitleLogo
@onready var button_start: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnStart
@onready var button_controls: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnControls
@onready var button_settings: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnSettings
@onready var button_quit: Button = $CenterContainer/VBoxContainer/MenuButtons/BtnQuit

@onready var controls_modal: Control = $ControlsModal
@onready var settings_modal: Control = $SettingsModal
@onready var transition_fade: ColorRect = $TransitionOverlay

var menu_buttons: Array[Button] = []
var current_focus_index: int = 0

func _ready() -> void:
	# Khởi tạo danh sách button để điều hướng bàn phím mượt mà
	menu_buttons = [button_start, button_controls, button_settings, button_quit]
	for i in range(menu_buttons.size()):
		var btn = menu_buttons[i]
		btn.mouse_entered.connect(_on_button_hovered.bind(i))
		
	button_start.pressed.connect(_on_start_pressed)
	button_controls.pressed.connect(_on_controls_pressed)
	button_settings.pressed.connect(_on_settings_pressed)
	button_quit.pressed.connect(_on_quit_pressed)
	
	if controls_modal:
		controls_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
		
	# Mặc định focus vào nút đầu tiên
	button_start.grab_focus()
	
	# Hiệu ứng mờ dần khi mở menu (Fade In)
	if transition_fade:
		transition_fade.visible = true
		transition_fade.modulate.a = 1.0
		var tw = create_tween()
		tw.tween_property(transition_fade, "modulate:a", 0.0, 0.4)
		tw.tween_callback(func(): transition_fade.visible = false)
		
	# Hiệu ứng Breathing/Floating cho logo
	if title_logo:
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(title_logo, "position:y", title_logo.position.y - 4.0, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		float_tween.tween_property(title_logo, "position:y", title_logo.position.y, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _input(event: InputEvent) -> void:
	# Đóng popup nếu nhấn ESC hoặc B
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if controls_modal and controls_modal.visible:
			controls_modal.visible = false
			button_controls.grab_focus()
			get_viewport().set_input_as_handled()
		elif settings_modal and settings_modal.visible:
			settings_modal.visible = false
			button_settings.grab_focus()
			get_viewport().set_input_as_handled()

func _on_button_hovered(index: int) -> void:
	current_focus_index = index
	menu_buttons[index].grab_focus()

func _on_start_pressed() -> void:
	# Hiệu ứng chuyển màn sang game
	if transition_fade:
		transition_fade.visible = true
		transition_fade.modulate.a = 0.0
		var tw = create_tween()
		tw.tween_property(transition_fade, "modulate:a", 1.0, 0.35)
		tw.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/Main.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_controls_pressed() -> void:
	if controls_modal:
		controls_modal.visible = true
		var close_btn = controls_modal.get_node_or_null("Panel/BtnCloseControls")
		if close_btn:
			close_btn.grab_focus()

func _on_settings_pressed() -> void:
	if settings_modal:
		settings_modal.visible = true
		var close_btn = settings_modal.get_node_or_null("Panel/BtnCloseSettings")
		if close_btn:
			close_btn.grab_focus()

func _on_quit_pressed() -> void:
	get_tree().quit()

func close_all_modals() -> void:
	if controls_modal:
		controls_modal.visible = false
	if settings_modal:
		settings_modal.visible = false
	button_start.grab_focus()
