class_name PlayerAnimationController
extends AnimatedSprite2D

## Điều khiển chuyển động và chuỗi frame hoạt họa cho Người Chơi
## Các chuỗi: idle, run, attack, parry, jump, dash

func _ready() -> void:
	# Khởi tạo SpriteFrames nếu chưa có
	if sprite_frames == null:
		var sf := SpriteFrames.new()
		
		# Idle (4 frames, loop, 6 fps)
		sf.add_animation("idle")
		sf.set_animation_loop("idle", true)
		sf.set_animation_speed("idle", 6.0)
		for i in range(4):
			sf.add_frame("idle", load("res://assets/sprites/characters/player/idle_%d.png" % i))
			
		# Run (6 frames, loop, 12 fps)
		sf.add_animation("run")
		sf.set_animation_loop("run", true)
		sf.set_animation_speed("run", 12.0)
		for i in range(6):
			sf.add_frame("run", load("res://assets/sprites/characters/player/run_%d.png" % i))
			
		# Attack (5 frames, non-loop, 15 fps)
		sf.add_animation("attack")
		sf.set_animation_loop("attack", false)
		sf.set_animation_speed("attack", 15.0)
		for i in range(5):
			sf.add_frame("attack", load("res://assets/sprites/characters/player/attack_%d.png" % i))
			
		# Parry (5 frames, non-loop, 16 fps)
		sf.add_animation("parry")
		sf.set_animation_loop("parry", false)
		sf.set_animation_speed("parry", 16.0)
		for i in range(5):
			sf.add_frame("parry", load("res://assets/sprites/characters/player/parry_%d.png" % i))
			
		# Jump (5 frames, non-loop, 10 fps)
		sf.add_animation("jump")
		sf.set_animation_loop("jump", false)
		sf.set_animation_speed("jump", 10.0)
		for i in range(5):
			sf.add_frame("jump", load("res://assets/sprites/characters/player/jump_%d.png" % i))
			
		# Dash (4 frames, non-loop, 14 fps)
		sf.add_animation("dash")
		sf.set_animation_loop("dash", false)
		sf.set_animation_speed("dash", 14.0)
		for i in range(4):
			sf.add_frame("dash", load("res://assets/sprites/characters/player/dash_%d.png" % i))
			
		sprite_frames = sf
		play("idle")
