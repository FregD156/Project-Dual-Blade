class_name EnemyAnimationController
extends AnimatedSprite2D

## Animation Controller cho quái thường Lính Gác Rỉ Sét
## Animations: walk (4 frames loop), attack (vung kiếm)

func _ready() -> void:
	if sprite_frames == null:
		var sf := SpriteFrames.new()
		
		# Walk / Idle (4 frames, loop, 5 fps)
		sf.add_animation("walk")
		sf.set_animation_loop("walk", true)
		sf.set_animation_speed("walk", 5.0)
		for i in range(4):
			sf.add_frame("walk", load("res://assets/sprites/enemies/rusty_guard_anim_%d.png" % i))
			
		sprite_frames = sf
		play("walk")
