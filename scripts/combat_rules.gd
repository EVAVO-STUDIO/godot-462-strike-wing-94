class_name CombatRules
extends RefCounted

const NORMAL_TARGET_DURABILITY_SCALE := 0.58
const NORMAL_TARGET_HP_CAP := 9

static var _incoming_damage_multiplier := 1.0

static func set_incoming_damage_multiplier(value: float) -> void:
	_incoming_damage_multiplier = clampf(value, 0.65, 1.0)

static func incoming_damage_multiplier() -> float:
	return _incoming_damage_multiplier

static func mitigated_damage(amount: int, multiplier: float = -1.0) -> int:
	var raw := maxi(0, amount)
	if raw <= 0:
		return 0
	var applied_multiplier := _incoming_damage_multiplier if multiplier < 0.0 else clampf(multiplier, 0.65, 1.0)
	return maxi(1, int(round(float(raw) * applied_multiplier)))

static func apply_shielded_damage(hull: int, shield: int, amount: int) -> Dictionary:
	var remaining := mitigated_damage(amount)
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

static func normal_target_hp(scaled_hp: int, is_boss: bool) -> int:
	var safe_hp := maxi(1, scaled_hp)
	if is_boss:
		return safe_hp
	return mini(NORMAL_TARGET_HP_CAP, maxi(1, int(ceil(float(safe_hp) * NORMAL_TARGET_DURABILITY_SCALE))))
