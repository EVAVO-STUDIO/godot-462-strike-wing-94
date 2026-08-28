class_name BombRules
extends RefCounted

const MIN_BOSS_DAMAGE := 6
const MAX_BOSS_DAMAGE := 18
const BOSS_DAMAGE_RATIO := 0.12

static func boss_bomb_damage(max_hp: int) -> int:
	var safe_max := maxi(1, max_hp)
	return clampi(int(round(float(safe_max) * BOSS_DAMAGE_RATIO)), MIN_BOSS_DAMAGE, MAX_BOSS_DAMAGE)

static func apply_nonlethal_boss_damage(current_hp: int, max_hp: int) -> int:
	var safe_hp := maxi(1, current_hp)
	return maxi(1, safe_hp - boss_bomb_damage(max_hp))
