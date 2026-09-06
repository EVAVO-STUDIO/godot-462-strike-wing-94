class_name RouteProgressRules
extends RefCounted

# Authored route timestamps are expressed as the distance covered in one second
# at cruise power. This preserves the existing mission data while allowing
# throttle, afterburner and hypersonic flight to change when geography and
# spatial encounters are reached.
static func advance(current_progress: float, delta: float, world_speed_multiplier: float) -> float:
	return maxf(0.0, current_progress) + maxf(0.0, delta) * maxf(0.0, world_speed_multiplier)

static func reached(progress: float, authored_route_second: float) -> bool:
	return maxf(0.0, progress) + 0.0001 >= maxf(0.0, authored_route_second)

static func boss_gate(mission_duration: float, arrival_ratio: float = 0.72) -> float:
	return maxf(0.0, mission_duration) * clampf(arrival_ratio, 0.0, 1.0)

static func boss_gate_for_mission(mission: Dictionary) -> float:
	var gate := boss_gate(float(mission.get("duration_seconds", 150.0)))
	for beat in mission.get("encounter_beats", []):
		if typeof(beat) != TYPE_DICTIONARY or bool(beat.get("secret", false)):
			continue
		gate = maxf(gate, float(beat.get("at_seconds", 0.0)) + 8.0)
	return gate

static func route_length(mission: Dictionary) -> float:
	var nominal := maxf(0.0, float(mission.get("duration_seconds", 150.0)))
	if str(mission.get("boss_id", "")).is_empty():
		return nominal
	return maxf(nominal, boss_gate_for_mission(mission) + 24.0)

static func remaining_travel_seconds(progress: float, distance: float, speed: float) -> float:
	return maxf(0.0, distance - progress) / maxf(0.01, speed)
