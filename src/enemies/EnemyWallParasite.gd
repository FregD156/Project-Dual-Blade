class_name EnemyWallParasite
extends EnemyBase

## Quái Đặc Thù World 2: Ấu Trùng Bám Tường/Trần (The Wall Parasite - detail.md Phần C World 2)
## - Bám trên trần cao hoặc bục đá
## - Khi Player đi ngang qua bên dưới, buông mình rơi đột kích (Ambush Drop)
## - Sau khi chạm đất, di chuyển bò nhanh tiếp cận mục tiêu

var is_ceiling_attached: bool = true
var initial_y: float = 0.0

func _ready() -> void:
	enemy_name = "Ấu Trùng Bám Tường"
	max_hp = 75.0
	current_hp = 75.0
	def = 2.0
	move_speed = 65.0
	attack_damage = 18.0
	attack_range = 28.0
	detection_range = 160.0
	attack_cooldown = 1.5
	windup_time = 0.35
	unparryable_chance = 0.25
	initial_y = global_position.y
	super._ready()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
		
	_find_player()
	
	if is_ceiling_attached:
		velocity = Vector2.ZERO
		if target_player:
			var dx = abs(target_player.global_position.x - global_position.x)
			# Nếu người chơi đi ngang qua gần vị trí rơi (dx < 45 px)
			if dx < 45.0 and target_player.global_position.y > global_position.y:
				_drop_from_ceiling()
		return
		
	# Khi đã rơi xuống đất, áp dụng logic chase bình thường
	super._physics_process(delta)

func _drop_from_ceiling() -> void:
	is_ceiling_attached = false
	current_state = State.CHASE
	# Tăng tốc độ rơi nhanh
	velocity.y = 260.0
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "rotation", 0.0, 0.15)
