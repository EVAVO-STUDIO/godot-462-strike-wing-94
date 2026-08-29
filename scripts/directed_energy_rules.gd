class_name DirectedEnergyRules
extends RefCounted

const STORM_WEAPON_ID := "storm_cannon"
const PLASMA_WEAPON_ID := "plasma_lance"

const STORM_PULSE_RADIUS := 30.0
const STORM_TRIGGER_RADIUS := 15.0
const STORM_MAX_SECONDARY_TARGETS := 2
const STORM_SECONDARY_DAMAGE := 1

const PLASMA_PULSE_RADIUS := 48.0
const PLASMA_TRIGGER_RADIUS := 20.0
const PLASMA_MAX_SECONDARY_TARGETS := 3
const PLASMA_SECONDARY_DAMAGE := 2

# Backward-compatible aliases retained for existing tooling around Storm Cannon.
const PULSE_RADIUS := STORM_PULSE_RADIUS
const TRIGGER_RADIUS := STORM_TRIGGER_RADIUS
const MAX_SECONDARY_TARGETS := STORM_MAX_SECONDARY_TARGETS
const SECONDARY_DAMAGE := STORM_SECONDARY_DAMAGE

static func weapon_id(bullet: Dictionary) -> String:
	return str(bullet.get("weapon_id", ""))

static func is_storm_packet(bullet: Dictionary) -> bool:
	return weapon_id(bullet) == STORM_WEAPON_ID

static func is_plasma_packet(bullet: Dictionary) -> bool:
	return weapon_id(bullet) == PLASMA_WEAPON_ID

static func is_directed_energy_packet(bullet: Dictionary) -> bool:
	return is_storm_packet(bullet) or is_plasma_packet(bullet)

static func can_discharge(bullet: Dictionary) -> bool:
	return is_directed_energy_packet(bullet) and not bool(bullet.get("pulse_discharged", false))

static func trigger_radius(bullet: Dictionary) -> float:
	return PLASMA_TRIGGER_RADIUS if is_plasma_packet(bullet) else STORM_TRIGGER_RADIUS

static func pulse_radius(bullet: Dictionary) -> float:
	return PLASMA_PULSE_RADIUS if is_plasma_packet(bullet) else STORM_PULSE_RADIUS

static func max_secondary_targets(bullet: Dictionary) -> int:
	return PLASMA_MAX_SECONDARY_TARGETS if is_plasma_packet(bullet) else STORM_MAX_SECONDARY_TARGETS

static func secondary_damage(bullet: Dictionary) -> int:
	return PLASMA_SECONDARY_DAMAGE if is_plasma_packet(bullet) else STORM_SECONDARY_DAMAGE

static func trigger_enemy_index(bullet_position: Vector2, enemies: Array, bullet: Dictionary = {}) -> int:
	var best_index := -1
	var best_distance := INF
	var radius_value := trigger_radius(bullet)
	var radius_sq := radius_value * radius_value
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0:
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(bullet_position)
		if distance <= radius_sq and distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

static func secondary_indices(origin: Vector2, enemies: Array, primary_index: int, bullet: Dictionary = {}) -> Array[int]:
	var candidates: Array = []
	var radius_value := pulse_radius(bullet)
	var radius_sq := radius_value * radius_value
	for i in range(enemies.size()):
		if i == primary_index:
			continue
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0:
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(origin)
		if distance <= radius_sq:
			candidates.append({"index":i,"distance":distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	var result: Array[int] = []
	for i in range(mini(max_secondary_targets(bullet), candidates.size())):
		result.append(int(candidates[i]["index"]))
	return result
