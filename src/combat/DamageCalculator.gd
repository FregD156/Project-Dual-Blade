class_name DamageCalculator
extends RefCounted

## Damage Calculator theo công thức chuẩn ARPG tại Phần D Detail.md & agent.md
## Mitigation% = DEF / (DEF + K)  (mặc định K = 50.0)
## Damage = max(1, ATK * SkillMultiplier * (1 - Mitigation%) * (1 - Resist%))

static func calculate_mitigation(def: float, k_factor: float = 50.0) -> float:
	if def <= 0.0:
		return 0.0
	return def / (def + k_factor)

static func calculate_damage(
	atk: float,
	skill_mult: float,
	target_def: float,
	target_resist: float = 0.0,
	k_factor: float = 50.0,
	is_crit: bool = false,
	crit_dmg_mult: float = 1.5
) -> Dictionary:
	var mitigation: float = calculate_mitigation(target_def, k_factor)
	var raw_damage: float = atk * skill_mult
	if is_crit:
		raw_damage *= crit_dmg_mult
	
	var final_damage: float = raw_damage * (1.0 - mitigation) * (1.0 - target_resist)
	final_damage = max(1.0, final_damage)
	
	return {
		"damage": round(final_damage),
		"is_crit": is_crit,
		"mitigation_pct": mitigation,
		"raw_damage": raw_damage
	}
