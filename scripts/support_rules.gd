class_name SupportRules
extends RefCounted

const ALLOWED_TYPES := ["rockets", "crossfire", "hunter", "defence", "emp", "magnetic"]

static func sanitize_unlock(index: int, catalog_size: int) -> int:
	return clampi(index, 0, maxi(0, catalog_size - 1))

static func sanitize_selected(index: int, unlocked_index: int, catalog_size: int) -> int:
	var safe_unlock := sanitize_unlock(unlocked_index, catalog_size)
	return clampi(index, 0, safe_unlock)

static func cycle_selected(current_index: int, unlocked_index: int, catalog_size: int) -> int:
	var safe_unlock := sanitize_unlock(unlocked_index, catalog_size)
	if safe_unlock <= 0:
		return 0
	return (sanitize_selected(current_index, safe_unlock, catalog_size) + 1) % (safe_unlock + 1)

static func support_type(support: Dictionary) -> String:
	var value := str(support.get("type", ""))
	return value if value in ALLOWED_TYPES else ""

static func energy_cost(support: Dictionary) -> float:
	return maxf(0.0, float(support.get("energy_cost", 0.0)))

static func cooldown(support: Dictionary) -> float:
	return maxf(0.05, float(support.get("cooldown", 0.5)))

static func radius(support: Dictionary, fallback: float = 90.0) -> float:
	return clampf(float(support.get("radius", fallback)), 1.0, 240.0)

static func duration(support: Dictionary, fallback: float = 1.0) -> float:
	return clampf(float(support.get("duration", fallback)), 0.1, 8.0)

static func max_targets(support: Dictionary) -> int:
	return clampi(int(support.get("max_targets", 1)), 1, 16)

static func projectile_angles(support: Dictionary) -> Array[float]:
	var result: Array[float] = []
	var count := clampi(int(support.get("projectiles", 1)), 1, 5)
	var spread := deg_to_rad(maxf(0.0, float(support.get("spread_degrees", 0.0))))
	if count == 1:
		result.append(0.0)
		return result
	for i in range(count):
		result.append(lerpf(-spread, spread, float(i) / float(count - 1)))
	return result

static func defence_indices(enemy_bullets: Array, player_position: Vector2, support: Dictionary) -> Array[int]:
	var radius_value := radius(support)
	var radius_sq := radius_value * radius_value
	var candidates: Array = []
	for i in range(enemy_bullets.size()):
		var bullet = enemy_bullets[i]
		if typeof(bullet) != TYPE_DICTIONARY:
			continue
		var position: Vector2 = bullet.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(player_position)
		if distance <= radius_sq:
			candidates.append({"index":i,"distance":distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	var result: Array[int] = []
	for i in range(mini(max_targets(support), candidates.size())):
		result.append(int(candidates[i]["index"]))
	result.sort()
	result.reverse()
	return result

static func autonomous_enemy_indices(enemies: Array, player_position: Vector2, support: Dictionary) -> Array[int]:
	var radius_value := radius(support, 160.0)
	var radius_sq := radius_value * radius_value
	var candidates: Array = []
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if typeof(enemy) != TYPE_DICTIONARY or int(enemy.get("hp", 0)) <= 0:
			continue
		if str(enemy.get("faction", "")) != "autonomous":
			continue
		var position: Vector2 = enemy.get("position", Vector2.ZERO)
		var distance := position.distance_squared_to(player_position)
		if distance <= radius_sq:
			candidates.append({"index":i,"distance":distance})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["distance"]) < float(b["distance"]))
	var result: Array[int] = []
	for i in range(mini(max_targets(support), candidates.size())):
		result.append(int(candidates[i]["index"]))
	return result

static func can_activate(energy: float, timer: float, support: Dictionary, has_target := true) -> bool:
	var type := support_type(support)
	if type == "":
		return false
	if timer > 0.0 or energy + 0.0001 < energy_cost(support):
		return false
	if type in ["defence", "emp"] and not has_target:
		return false
	return true
