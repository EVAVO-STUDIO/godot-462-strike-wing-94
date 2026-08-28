class_name MissileBehaviorRules
extends RefCounted

const TAG_RADIUS_SQ := 49.0

static func missile_launcher_near(shot: Dictionary, enemies: Array) -> bool:
	var position: Vector2 = shot.get("position", Vector2.ZERO)
	for enemy in enemies:
		if typeof(enemy) != TYPE_DICTIONARY:
			continue
		if str(enemy.get("weapon", "")) != "missile":
			continue
		var enemy_position: Vector2 = enemy.get("position", Vector2.INF)
		if position.distance_squared_to(enemy_position) <= TAG_RADIUS_SQ:
			return true
	return false

static func apply_homing_metadata(shot: Dictionary) -> Dictionary:
	var next := shot.duplicate(true)
	var velocity: Vector2 = next.get("velocity", Vector2.DOWN * 150.0)
	next["homing"] = true
	next["homing_speed"] = maxf(1.0, velocity.length())
	next["turn_rate"] = maxf(1.8, float(next.get("turn_rate", 0.0)))
	next["life"] = maxf(5.0, float(next.get("life", 0.0)))
	return next
