class_name BombRules
extends RefCounted

const MIN_BOSS_DAMAGE := 6
const MAX_BOSS_DAMAGE := 18
const BOSS_DAMAGE_RATIO := 0.12
const LEGACY_STRIKE_LEAD := 72.0
const LEGACY_STRIKE_RADIUS := 54.0
const LEGACY_SURFACE_DAMAGE := 24

static func strike_point(player_position: Vector2) -> Vector2:
	return Vector2(player_position.x, player_position.y - LEGACY_STRIKE_LEAD)

static func in_strike_radius(target_position: Vector2, point: Vector2) -> bool:
	return target_position.distance_squared_to(point) <= LEGACY_STRIKE_RADIUS * LEGACY_STRIKE_RADIUS

static func can_damage_category(category: String, is_boss: bool = false) -> bool:
	return is_boss or category in ["ground", "sea"]

static func boss_bomb_damage(max_hp: int) -> int:
	var safe_max := maxi(1, max_hp)
	return clampi(int(round(float(safe_max) * BOSS_DAMAGE_RATIO)), MIN_BOSS_DAMAGE, MAX_BOSS_DAMAGE)

static func apply_nonlethal_boss_damage(current_hp: int, max_hp: int) -> int:
	var safe_hp := maxi(1, current_hp)
	return maxi(1, safe_hp - boss_bomb_damage(max_hp))
