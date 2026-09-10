class_name EnemySpawner
extends Node2D

## Hệ thống Smart Spawner phân bổ quái vật theo địa hình & vai trò chiến thuật
## - Lính nỏ/bắn tỉa: Spawn trên bục đá cao
## - Lính cận chiến: Spawn trên sàn chính cách nhau 80-120px kẹp thịt người chơi (Flanking)

@export var enemy_scene: PackedScene = preload("res://scenes/Main.tscn") # Placeholder hoặc instance
@export var spawn_on_ready: bool = true

@onready var spawn_melee_left: Marker2D = $SpawnPoints/MeleeLeft
@onready var spawn_melee_right: Marker2D = $SpawnPoints/MeleeRight
@onready var spawn_sniper_high: Marker2D = $SpawnPoints/SniperHigh

func _ready() -> void:
	pass

func get_spawn_positions() -> Dictionary:
	return {
		"melee_left": spawn_melee_left.global_position if spawn_melee_left else Vector2(160, 210),
		"melee_right": spawn_melee_right.global_position if spawn_melee_right else Vector2(340, 210),
		"sniper_high": spawn_sniper_high.global_position if spawn_sniper_high else Vector2(240, 140)
	}
