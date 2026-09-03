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
