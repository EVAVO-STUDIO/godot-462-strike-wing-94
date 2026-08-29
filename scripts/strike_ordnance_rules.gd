class_name StrikeOrdnanceRules
extends RefCounted

const MAX_ORDNANCE := 6
const DROP_COOLDOWN := 0.55
const LOW_IMPACT_DELAY := 0.30
const MID_IMPACT_DELAY := 0.52
const LOW_AIM_RADIUS := 24.0
const MID_AIM_RADIUS := 38.0
const LOW_BLAST_RADIUS := 44.0
const MID_BLAST_RADIUS := 36.0
const LOW_DAMAGE := 22
const MID_DAMAGE := 14
const BOSS_DAMAGE := 8

static func altitude_allowed(altitude: String) -> bool:
	return altitude in ["low", "mid"]

static func form_allowed(form: String) -> bool:
	return form == "bomber"

static func can_drop(form: String, altitude: String, ordnance: int, cooldown: float) -> bool:
	return form_allowed(form) and altitude_allowed(altitude) and ordnance > 0 and cooldown <= 0.0

static func target_point(player_position: Vector2, altitude: String) -> Vector2:
	var lead := 52.0 if altitude == "low" else 84.0
	return Vector2(player_position.x, player_position.y - lead)

static func impact_delay(altitude: String) -> float:
	return LOW_IMPACT_DELAY if altitude == "low" else MID_IMPACT_DELAY

static func aim_radius(altitude: String) -> float:
	return LOW_AIM_RADIUS if altitude == "low" else MID_AIM_RADIUS

static func blast_radius(altitude: String) -> float:
	return LOW_BLAST_RADIUS if altitude == "low" else MID_BLAST_RADIUS

static func damage_for_target(enemy_class: String, is_boss: bool, altitude: String) -> int:
	if is_boss:
		return BOSS_DAMAGE
	var surface := enemy_class in ["ground", "sea"]
	if not surface:
		return 3
	return LOW_DAMAGE if altitude == "low" else MID_DAMAGE

static func delivery_quality(altitude: String) -> String:
	return "ATTACK RUN" if altitude == "low" else "STAND-OFF DROP"

static func rearm(current: int, amount: int = MAX_ORDNANCE) -> int:
	return clampi(current + maxi(0, amount), 0, MAX_ORDNANCE)
