class_name ThreatWarningRules
extends RefCounted

const DANGER_RADIUS := 150.0
const CAUTION_RADIUS := 260.0

static func homing_count(bullets: Array) -> int:
	var count := 0
	for shot in bullets:
		if typeof(shot) == TYPE_DICTIONARY and bool(shot.get("homing", false)):
			count += 1
	return count

static func nearest_homing_distance(bullets: Array, player_position: Vector2) -> float:
	var nearest := INF
	for shot in bullets:
		if typeof(shot) != TYPE_DICTIONARY or not bool(shot.get("homing", false)):
			continue
		var position: Vector2 = shot.get("position", Vector2.ZERO)
		nearest = minf(nearest, position.distance_to(player_position))
	return nearest

static func nearest_homing(bullets: Array, player_position: Vector2) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance := INF
	for shot in bullets:
		if typeof(shot) != TYPE_DICTIONARY or not bool(shot.get("homing", false)):
			continue
		var position: Vector2 = shot.get("position", Vector2.ZERO)
		var distance := position.distance_to(player_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = shot
	return nearest

static func clock_bearing(source: Vector2, target: Vector2) -> int:
	var relative := source - target
	if relative.length_squared() <= 0.001:
		return 12
	var clockwise := fposmod(atan2(relative.x, -relative.y), TAU)
	var clock := posmod(int(round(clockwise / TAU * 12.0)), 12)
	return 12 if clock == 0 else clock

static func time_to_impact(shot: Dictionary, player_position: Vector2) -> float:
	var position: Vector2 = shot.get("position", Vector2.ZERO)
	var velocity: Vector2 = shot.get("velocity", Vector2.ZERO)
	var to_player := player_position - position
	var closing_speed := velocity.dot(to_player.normalized()) if to_player.length_squared() > 0.001 else velocity.length()
	return to_player.length() / maxf(1.0, closing_speed)

static func warning_level(distance: float, count: int) -> int:
	if count <= 0 or is_inf(distance):
		return 0
	if distance <= DANGER_RADIUS:
		return 2
	if distance <= CAUTION_RADIUS:
		return 1
	return 0

static func warning_text(distance: float, count: int) -> String:
	var level := warning_level(distance, count)
	if level == 2:
		return "MISSILE LOCK  %d INBOUND  %03d" % [count, int(round(distance))]
	if level == 1:
		return "MISSILE WARNING  %d  %03d" % [count, int(round(distance))]
	if count > 0:
		return "MISSILES TRACKING  %d" % count
	return ""
