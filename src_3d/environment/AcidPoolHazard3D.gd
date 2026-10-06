class_name AcidPoolHazard3D
extends Area3D

## Hồ Axit / Cống ăn mòn 3D (Acid Pool Hazard 3D)
## Gây sát thương ăn mòn thanh Giáp (Armor Corrode) theo thời gian khi người chơi đứng trong vũng axit

@export var armor_dps: float = 25.0
@export var direct_hp_dps: float = 12.0

var overlapping_players: Array[Node3D] = []

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 # Player 3D
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for player in overlapping_players:
		if is_instance_valid(player) and player.has_method("take_damage"):
			# Nếu có giáp thì ăn mòn giáp, nếu hết giáp thì trừ trực tiếp máu
			var dps: float = armor_dps if (player.get("current_armor") != null and player.current_armor > 0.0) else direct_hp_dps
			player.take_damage(dps * delta, global_position)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not overlapping_players.has(body):
		overlapping_players.append(body)

func _on_body_exited(body: Node3D) -> void:
	if overlapping_players.has(body):
		overlapping_players.erase(body)
