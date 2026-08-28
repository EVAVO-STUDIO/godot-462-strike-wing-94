class_name ProjectileRules
extends RefCounted

static func enemy_shot_velocity(origin: Vector2, target: Vector2, speed: float) -> Vector2:
	var direction := origin.direction_to(target)
	if direction.length_squared() < 0.001:
		direction = Vector2.DOWN
	return direction * speed

static func pickup_kind_for_roll(roll: float) -> String:
	if roll < 0.10:
		return "shield"
	if roll < 0.16:
		return "repair"
	if roll < 0.21:
		return "bomb"
	if roll < 0.27:
		return "weapon"
	return ""

static func enemy_fire_interval(weapon_id: String, wave: int) -> float:
	var base := 2.2
	match weapon_id:
		"aimed_burst", "twin_burst": base = 1.35
		"missile": base = 1.8
		"cannon", "deck_gun": base = 2.4
		"side_burst": base = 1.65
		_: base = 2.1
	return maxf(0.55, base - float(wave) * 0.035)

static func enemy_projectile_speed(weapon_id: String) -> float:
	match weapon_id:
		"missile": return 125.0
		"cannon", "deck_gun": return 160.0
		"twin_burst": return 205.0
		_: return 185.0
