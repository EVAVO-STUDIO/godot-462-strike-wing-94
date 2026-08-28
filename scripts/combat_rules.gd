class_name CombatRules
extends RefCounted

static func apply_shielded_damage(hull: int, shield: int, amount: int) -> Dictionary:
	var remaining := maxi(0, amount)
	var next_shield := maxi(0, shield)
	var next_hull := maxi(0, hull)
	if next_shield > 0 and remaining > 0:
		var absorbed := mini(next_shield, remaining)
		next_shield -= absorbed
		remaining -= absorbed
	if remaining > 0:
		next_hull = maxi(0, next_hull - remaining)
	return {"hull": next_hull, "shield": next_shield}

static func enemy_spawn_interval(wave: int) -> float:
	return maxf(0.28, 1.05 - float(maxi(1, wave)) * 0.055)

static func wave_for_time(mission_time: float) -> int:
	return 1 + int(maxf(0.0, mission_time) / 20.0)

static func destroy_value(base_value: int, wave: int) -> int:
	return maxi(0, base_value) + maxi(1, wave) * 15
