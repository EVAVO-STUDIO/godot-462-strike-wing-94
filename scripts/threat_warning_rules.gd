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
