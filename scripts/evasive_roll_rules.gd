class_name EvasiveRollRules
extends RefCounted

const FIGHTER_DURATION := 0.68
const BOMBER_DURATION := 0.82
const RECOVERY_SECONDS := 1.10
const FIGHTER_DISPLACEMENT := 78.0
const BOMBER_DISPLACEMENT := 58.0
const MIN_HIT_PROFILE := 0.38

static func duration(form: String) -> float:
	return BOMBER_DURATION if form == "bomber" else FIGHTER_DURATION

static func displacement(form: String) -> float:
	return BOMBER_DISPLACEMENT if form == "bomber" else FIGHTER_DISPLACEMENT

static func travel_ratio(progress: float) -> float:
	return sin(clampf(progress, 0.0, 1.0) * PI * 0.5)

static func collision_multiplier(progress: float) -> float:
	var edge_on := sin(clampf(progress, 0.0, 1.0) * PI)
	return lerpf(1.0, MIN_HIT_PROFILE, edge_on)
