class_name StrategicWarheadRules
extends RefCounted

const TRIGGER_RADIUS := 18.0
const BLAST_RADIUS := 58.0
const MAX_SECONDARY_TARGETS := 4
const SECONDARY_DAMAGE := 4

static func is_strategic_round(bullet: Dictionary) -> bool:
	return bool(bullet.get("strategic_support", false))

static func can_burst(bullet: Dictionary) -> bool:
	return is_strategic_round(bullet) and not bool(bullet.get("strategic_burst", false))

static func trigger_enemy_index(position: Vector2, enemies: Array) -> int:
	var best := -1
	var best_distance := INF
	var radius_sq := TRIGGER_RADIUS * TRIGGER_RADIUS
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0: continue
		var enemy_position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := enemy_position.distance_squared_to(position)
		if distance <= radius_sq and distance < best_distance:
			best = i
			best_distance = distance
	return best

static func secondary_indices(origin: Vector2, enemies: Array, primary_index: int) -> Array[int]:
	var candidates: Array = []
	var radius_sq := BLAST_RADIUS * BLAST_RADIUS
	for i in range(enemies.size()):
		if i == primary_index: continue
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 1: continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(origin)
		if distance <= radius_sq:
			candidates.append({"index":i,"distance":distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	var result: Array[int] = []
	for i in range(mini(MAX_SECONDARY_TARGETS, candidates.size())):
		result.append(int(candidates[i]["index"]))
	return result
