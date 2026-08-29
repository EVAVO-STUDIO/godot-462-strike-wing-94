class_name StrikeOrdnanceRules
extends RefCounted

const MAX_ORDNANCE := 6
const DROP_COOLDOWN := 0.55
const IMPACT_DELAY := 0.48
const BLAST_RADIUS := 48.0
const BASE_DAMAGE := 18
const BOSS_DAMAGE := 8

static func altitude_allowed(altitude: String) -> bool:
	return altitude in ["low", "mid"]

static func form_allowed(form: String) -> bool:
	return form == "bomber"

static func can_drop(form: String, altitude: String, ordnance: int, cooldown: float) -> bool:
	return form_allowed(form) and altitude_allowed(altitude) and ordnance > 0 and cooldown <= 0.0

static func target_point(player_position: Vector2, altitude: String) -> Vector2:
	var lead := 64.0 if altitude == "low" else 82.0
	return Vector2(player_position.x, player_position.y - lead)

static func blast_radius(altitude: String) -> float:
	return BLAST_RADIUS if altitude == "low" else BLAST_RADIUS * 0.82

static func damage_for_target(enemy_class: String, is_boss: bool, altitude: String) -> int:
	if is_boss:
		return BOSS_DAMAGE
	var surface := enemy_class in ["ground", "sea"]
	if not surface:
		return 3
	return BASE_DAMAGE if altitude == "low" else int(round(BASE_DAMAGE * 0.72))

static func rearm(current: int, amount: int = MAX_ORDNANCE) -> int:
	return clampi(current + maxi(0, amount), 0, MAX_ORDNANCE)
