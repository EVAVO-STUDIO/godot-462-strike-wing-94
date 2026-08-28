class_name ProjectileRules
extends RefCounted

static func enemy_shot_velocity(origin: Vector2, target: Vector2, speed: float) -> Vector2:
	var direction := origin.direction_to(target)
	if direction.length_squared() < 0.001:
		direction = Vector2.DOWN
	return direction * speed

static func pickup_kind_for_roll(roll: float) -> String:
	if roll < 0.09:
		return "shield"
	if roll < 0.15:
		return "repair"
	if roll < 0.20:
		return "bomb"
	if roll < 0.25:
		return "weapon"
	return ""

static func enemy_fire_interval(weapon_id: String, wave: int) -> float:
	var base := 2.2
	match weapon_id:
		"aimed_burst":
			base = 1.45
		"twin_burst":
			base = 1.25
		"missile":
			base = 2.0
		"cannon":
			base = 2.55
		"deck_gun":
			base = 2.25
		"side_burst":
			base = 1.55
		"single_burst":
			base = 2.05
		_:
			base = 2.1
	var wave_pressure := minf(0.75, float(maxi(0, wave - 1)) * 0.035)
	return maxf(0.52, base - wave_pressure)

static func enemy_projectile_speed(weapon_id: String) -> float:
	match weapon_id:
		"missile":
			return 132.0
		"cannon":
			return 168.0
		"deck_gun":
			return 152.0
		"twin_burst":
			return 212.0
		"side_burst":
			return 198.0
		"aimed_burst":
			return 192.0
		_:
			return 182.0

static func collision_damage(weapon_id: String, boss: bool) -> int:
	var damage := 8
	match weapon_id:
		"missile":
			damage = 13
		"cannon":
			damage = 12
		"deck_gun":
			damage = 10
		"twin_burst":
			damage = 7
		"side_burst":
			damage = 6
		"aimed_burst":
			damage = 9
		_:
			damage = 8
	if boss:
		damage += 5
	return damage

static func danger_rating(weapon_id: String) -> int:
	match weapon_id:
		"missile":
			return 5
		"cannon", "deck_gun":
			return 4
		"twin_burst", "aimed_burst":
			return 3
		"side_burst":
			return 2
		_:
			return 1
