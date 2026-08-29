class_name BattlefieldSupportRules
extends RefCounted

const TANKER_RADIUS := 30.0
const TANKER_REQUIRED_SECONDS := 3.5
const TANKER_ENERGY_PER_SECOND := 32.0
const TANKER_SHIELD_PER_SECOND := 8.0
const TANKER_HULL_PER_SECOND := 3.0

static func support_for_id(catalog: Array, support_id: String) -> Dictionary:
	for item in catalog:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == support_id:
			return item
	return {}

static func allowed_ids(context: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var values = context.get("support", [])
	if typeof(values) != TYPE_ARRAY:
		return result
	for value in values:
		var id := str(value)
		if id != "" and id not in result:
			result.append(id)
	return result

static func cycle_index(index: int, count: int) -> int:
	return 0 if count <= 0 else posmod(index + 1, count)

static func tanker_hose_point(tanker_position: Vector2) -> Vector2:
	return tanker_position + Vector2(0, 66)

static func tanker_connected(player_position: Vector2, tanker_position: Vector2) -> bool:
	return player_position.distance_to(tanker_hose_point(tanker_position)) <= TANKER_RADIUS

static func tanker_progress(current: float, connected: bool, delta: float) -> float:
	if connected:
		return clampf(current + maxf(0.0, delta), 0.0, TANKER_REQUIRED_SECONDS)
	return maxf(0.0, current - maxf(0.0, delta) * 0.5)

static func tanker_complete(progress: float) -> bool:
	return progress >= TANKER_REQUIRED_SECONDS - 0.0001

static func tanker_restore(current: float, maximum: float, per_second: float, delta: float) -> float:
	return clampf(current + maxf(0.0, per_second) * maxf(0.0, delta), 0.0, maxf(0.0, maximum))

static func altitude_allowed(support: Dictionary, altitude: String) -> bool:
	var values = support.get("altitudes", [])
	return typeof(values) == TYPE_ARRAY and altitude in values
