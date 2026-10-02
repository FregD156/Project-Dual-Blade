class_name StageManager3D
extends Node3D

signal wave_cleared()
signal stage_completed()

const Portal3D = preload("res://src_3d/world/Portal3D.gd")
const EnemyBase3D = preload("res://src_3d/enemies/EnemyBase3D.gd")

@export var portal: Area3D = null
@export var current_stage: int = 1

var active_enemies: Array = []

func _ready() -> void:
	if portal:
		portal.set_active(false)
		portal.portal_entered.connect(_on_portal_entered)
		
	# Tự động quét và đăng ký quái vật hiện có trong scene
	call_deferred("_register_initial_enemies")

func _register_initial_enemies() -> void:
	for node in find_children("*", "EnemyBase3D", true, false):
		if node is EnemyBase3D and not node.is_dead:
			register_enemy(node)
			
	if active_enemies.is_empty():
		_on_all_enemies_defeated()

func register_enemy(enemy: Node) -> void:
	if not active_enemies.has(enemy):
		active_enemies.append(enemy)
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)
			
		# Nếu là quái Tinh Anh hoặc Boss, hiển thị thanh máu lớn
		if "enemy_name" in enemy and ("Thủ Lĩnh" in enemy.enemy_name or "Boss" in enemy.enemy_name):
			var hud = get_node_or_null("../HUD3D")
			if hud and hud.has_method("show_boss_bar"):
				hud.show_boss_bar(enemy.enemy_name, enemy.max_hp)
				if enemy.has_signal("hp_changed"):
					enemy.hp_changed.connect(func(c, _m): hud.update_boss_bar(c))

func _on_enemy_died(enemy: Node) -> void:
	active_enemies.erase(enemy)
	if active_enemies.is_empty():
		_on_all_enemies_defeated()

func _on_all_enemies_defeated() -> void:
	wave_cleared.emit()
	if portal:
		portal.set_active(true)
		
	var hud = get_node_or_null("../HUD3D")
	if hud and hud.has_node("MarginContainer/VBoxContainer/StateLabel"):
		var lbl = hud.get_node("MarginContainer/VBoxContainer/StateLabel")
		lbl.text = "✨ ĐÃ DỌN SẠCH QUÁI - HÃY BƯỚC VÀO CỔNG! ✨"
		lbl.modulate = Color(0.3, 1.0, 0.5)

func _on_portal_entered() -> void:
	stage_completed.emit()
	var hud = get_node_or_null("../HUD3D")
	if hud and hud.has_node("MarginContainer/VBoxContainer/StateLabel"):
		var lbl = hud.get_node("MarginContainer/VBoxContainer/StateLabel")
		lbl.text = "🌀 ĐANG DỊCH CHUYỂN SANG ẢI KẾ TIẾP..."
