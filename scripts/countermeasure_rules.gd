class_name CountermeasureRules
extends RefCounted

const MAX_CHARGES := 4
const COOLDOWN_SECONDS := 0.85
const EFFECT_SECONDS := 0.64
const DECOY_RADIUS := 250.0
const DECOY_TRAIL_DISTANCE := 74.0

static func can_deploy(charges: int, cooldown: float) -> bool:
	return charges > 0 and cooldown <= 0.0

static func decoy_point(player_position: Vector2, serial: int) -> Vector2:
	var side := -1.0 if posmod(serial, 2) == 0 else 1.0
	return player_position + Vector2(side * 34.0, DECOY_TRAIL_DISTANCE)

static func divert_missiles(bullets: Array, player_position: Vector2, decoy: Vector2) -> int:
	var diverted := 0
	for index in range(bullets.size()):
		if typeof(bullets[index]) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = bullets[index]
		if not bool(shot.get("homing", false)):
			continue
		var position: Vector2 = shot.get("position", Vector2.ZERO)
		if position.distance_to(player_position) > DECOY_RADIUS:
			continue
		var velocity: Vector2 = shot.get("velocity", Vector2.DOWN * 150.0)
		var speed := maxf(1.0, float(shot.get("homing_speed", velocity.length())))
		var direction := position.direction_to(decoy)
		if direction.length_squared() < 0.001:
			direction = Vector2.DOWN
		shot["velocity"] = direction * speed
		shot["homing"] = false
		shot["countermeasure_decoyed"] = true
		shot["life"] = minf(float(shot.get("life", 2.0)), 1.35)
		bullets[index] = shot
		diverted += 1
	return diverted
