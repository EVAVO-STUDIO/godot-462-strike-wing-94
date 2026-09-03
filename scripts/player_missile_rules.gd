class_name PlayerMissileRules
extends RefCounted

const MAX_MISSILES := 4
const LOCK_SECONDS := 0.88
const COOLDOWN_SECONDS := 0.72
const MAX_RANGE := 330.0
const MAX_LATERAL := 128.0
const MIN_FORWARD := 24.0
const MISSILE_SPEED := 285.0
const TURN_RATE := 4.8
const DAMAGE := 22
const LIFE_SECONDS := 4.2

static func is_valid_target(enemy: Dictionary, player_position: Vector2) -> bool:
	if int(enemy.get("hp", 0)) <= 0:
		return false
	var category := str(enemy.get("category", "air"))
	if category != "air" and not bool(enemy.get("boss", false)):
		return false
	var offset: Vector2 = enemy.get("position", Vector2.ZERO) - player_position
	return offset.y <= -MIN_FORWARD and offset.length() <= MAX_RANGE and absf(offset.x) <= MAX_LATERAL

static func target_score(enemy: Dictionary, player_position: Vector2) -> float:
	var offset: Vector2 = enemy.get("position", Vector2.ZERO) - player_position
	return offset.length() + absf(offset.x) * 0.72 - (42.0 if bool(enemy.get("boss", false)) else 0.0)

static func acquire_index(enemies: Array, player_position: Vector2, preferred_uid: int = -1) -> int:
	for index in range(enemies.size()):
		if typeof(enemies[index]) == TYPE_DICTIONARY and int(enemies[index].get("target_uid", -2)) == preferred_uid and is_valid_target(enemies[index], player_position):
			return index
	var result := -1
	var best := INF
	for index in range(enemies.size()):
		if typeof(enemies[index]) != TYPE_DICTIONARY or not is_valid_target(enemies[index], player_position):
			continue
		var score := target_score(enemies[index], player_position)
		if score < best:
			best = score
			result = index
	return result

static func steer_velocity(velocity: Vector2, origin: Vector2, target: Vector2, delta: float) -> Vector2:
	var speed := maxf(MISSILE_SPEED, velocity.length())
	var current := velocity.angle() if velocity.length_squared() > 0.001 else Vector2.UP.angle()
	var desired := (target - origin).angle()
	var next := current + clampf(wrapf(desired - current, -PI, PI), -TURN_RATE * delta, TURN_RATE * delta)
	return Vector2.RIGHT.rotated(next) * speed
