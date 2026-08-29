class_name DirectedEnergyRules
extends RefCounted

const STORM_WEAPON_ID := "storm_cannon"
const PULSE_RADIUS := 30.0
const TRIGGER_RADIUS := 15.0
const MAX_SECONDARY_TARGETS := 2
const SECONDARY_DAMAGE := 1

static func is_storm_packet(bullet: Dictionary) -> bool:
	return str(bullet.get("weapon_id", "")) == STORM_WEAPON_ID

static func can_discharge(bullet: Dictionary) -> bool:
	return is_storm_packet(bullet) and not bool(bullet.get("pulse_discharged", false))

static func trigger_enemy_index(bullet_position: Vector2, enemies: Array) -> int:
	var best_index := -1
	var best_distance := INF
	var radius_sq := TRIGGER_RADIUS * TRIGGER_RADIUS
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

static func secondary_indices(origin: Vector2, enemies: Array, primary_index: int) -> Array[int]:
	var candidates: Array = []
	var radius_sq := PULSE_RADIUS * PULSE_RADIUS
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
	for i in range(mini(MAX_SECONDARY_TARGETS, candidates.size())):
		result.append(int(candidates[i]["index"]))
	return result
