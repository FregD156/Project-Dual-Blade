class_name DebugLayer
extends CanvasLayer

## Debug Overlay Layer riêng biệt (Topmost Layer = 100)
## Không chặn chuột hay input (mouse_filter = IGNORE)
## Ẩn / Hiện bằng phím F1 hoặc phím Tilde (~)

@onready var state_label: Label = $MarginContainer/VBoxContainer/StateLabel
@onready var guide_label: Label = $MarginContainer/VBoxContainer/GuideLabel

var is_debug_visible: bool = true

func _ready() -> void:
	layer = 100 # Luôn nằm trên cùng

func _input(event: InputEvent) -> void:
	# Bật / tắt bằng phím F1 hoặc phím Tilde `~` (Keycode 4194332 hoặc 96)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1 or event.keycode == KEY_QUOTELEFT:
			toggle_debug_overlay()
		elif event.keycode == KEY_ESCAPE:
			# Nhấn ESC trong trận đấu để quay về Main Menu
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func toggle_debug_overlay() -> void:
	is_debug_visible = !is_debug_visible
	visible = is_debug_visible
	print("[DEBUG] Debug overlay:", "BẬT" if is_debug_visible else "TẮT")

func connect_player(player: Player) -> void:
	if not player:
		return
	player.state_changed.connect(_on_player_state_changed)

func _on_player_state_changed(s_name: String, is_iframe: bool) -> void:
	if state_label:
		state_label.text = "[F1: Toggle Debug] STATE: %s | I-FRAME: %s" % [s_name, "ON" if is_iframe else "OFF"]
