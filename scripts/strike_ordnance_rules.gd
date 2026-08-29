class_name StrikeOrdnanceRules
extends RefCounted

const MAX_ORDNANCE := 6
const DROP_COOLDOWN := 0.55
const LOW_IMPACT_DELAY := 0.30
const MID_IMPACT_DELAY := 0.52
const LOW_AIM_RADIUS := 24.0
const MID_AIM_RADIUS := 38.0
const LOW_ASSIST_RADIUS := 46.0
const MID_ASSIST_RADIUS := 26.0
const LOW_BLAST_RADIUS := 44.0
const MID_BLAST_RADIUS := 36.0
const LOW_DAMAGE := 22
const MID_DAMAGE := 14
const BOSS_DAMAGE := 8
const ROUTE_PRECISION_SCORE := 450
const STABILITY_SECONDS := 0.65
const STABILITY_DECAY_MULTIPLIER := 1.8
const STABLE_IMPACT_MULTIPLIER := 0.72
const STABLE_AIM_MULTIPLIER := 0.72

static func altitude_allowed(altitude: String) -> bool:
	return altitude in ["low", "mid"]

static func form_allowed(form: String) -> bool:
	return form == "bomber"

static func can_drop(form: String, altitude: String, ordnance: int, cooldown: float) -> bool:
	return form_allowed(form) and altitude_allowed(altitude) and ordnance > 0 and cooldown <= 0.0

static func target_point(player_position: Vector2, altitude: String) -> Vector2:
	var lead := 52.0 if altitude == "low" else 84.0
	return Vector2(player_position.x, player_position.y - lead)

static func assisted_target_index(player_position: Vector2, altitude: String, enemies: Array) -> int:
	var projected := target_point(player_position, altitude)
	var radius := LOW_ASSIST_RADIUS if altitude == "low" else MID_ASSIST_RADIUS
	var radius_sq := radius * radius
	var best_priority := -1
	var best_priority_distance := INF
	var best_regular := -1
	var best_regular_distance := INF
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		if bool(enemy.get("boss", false)):
			continue
		var enemy_class := str(enemy.get("category", "air"))
		if enemy_class not in ["ground", "sea"]:
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(projected)
		if distance > radius_sq:
			continue
		if bool(enemy.get("strike_priority", false)):
			if distance < best_priority_distance:
				best_priority_distance = distance
				best_priority = i
		elif distance < best_regular_distance:
			best_regular_distance = distance
			best_regular = i
	return best_priority if best_priority >= 0 else best_regular

static func assisted_target_point(player_position: Vector2, altitude: String, enemies: Array) -> Vector2:
	var index := assisted_target_index(player_position, altitude, enemies)
	if index >= 0 and index < enemies.size():
		var enemy = enemies[index]
		if typeof(enemy) == TYPE_DICTIONARY:
			var position: Vector2 = enemy.get("position", target_point(player_position, altitude))
			return Vector2(roundf(position.x), roundf(position.y))
	return target_point(player_position, altitude)

static func priority_target_at_point(point: Vector2, enemies: Array, tolerance: float = 2.0) -> bool:
	var tolerance_sq := maxf(0.0, tolerance) * maxf(0.0, tolerance)
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY or not bool(enemy.get("strike_priority", false)):
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		if position.distance_squared_to(point) <= tolerance_sq:
			return true
	return false

static func route_precision_score(enemy: Dictionary, killed_by_ordnance: bool) -> int:
	if not killed_by_ordnance or not bool(enemy.get("strike_priority", false)):
		return 0
	return ROUTE_PRECISION_SCORE

static func update_stability(current: float, delta: float, low_bomber: bool, has_surface_lock: bool, lateral_input: float) -> float:
	var value := clampf(current, 0.0, 1.0)
	var dt := maxf(0.0, delta)
	var stable_line := low_bomber and has_surface_lock and absf(lateral_input) <= 0.18
	if stable_line:
		return clampf(value + dt / STABILITY_SECONDS, 0.0, 1.0)
	return clampf(value - dt * STABILITY_DECAY_MULTIPLIER / STABILITY_SECONDS, 0.0, 1.0)

static func stabilized_impact_delay(altitude: String, stability: float) -> float:
	var base := impact_delay(altitude)
	if altitude != "low":
		return base
	return lerpf(base, base * STABLE_IMPACT_MULTIPLIER, clampf(stability, 0.0, 1.0))

static func stabilized_aim_radius(altitude: String, stability: float) -> float:
	var base := aim_radius(altitude)
	if altitude != "low":
		return base
	return lerpf(base, base * STABLE_AIM_MULTIPLIER, clampf(stability, 0.0, 1.0))

static func impact_delay(altitude: String) -> float:
	return LOW_IMPACT_DELAY if altitude == "low" else MID_IMPACT_DELAY

static func aim_radius(altitude: String) -> float:
	return LOW_AIM_RADIUS if altitude == "low" else MID_AIM_RADIUS

static func assist_radius(altitude: String) -> float:
	return LOW_ASSIST_RADIUS if altitude == "low" else MID_ASSIST_RADIUS

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
