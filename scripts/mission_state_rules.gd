class_name MissionStateRules
extends RefCounted

static var _airframe_context: Dictionary = {}

static func set_airframe_context(frame: Dictionary) -> void:
	_airframe_context = frame.duplicate(true)

static func starting_hull(campaign: Dictionary, fallback: int = 100) -> int:
	var base := clampi(int(campaign.get("starting_hull", fallback)), 1, 999)
	return clampi(maxi(base, int(_airframe_context.get("hull_capacity", base))), 1, 999)

static func starting_shield(campaign: Dictionary, fallback: int = 100) -> int:
	var base := clampi(int(campaign.get("starting_shield", fallback)), 0, 999)
	return clampi(maxi(base, int(_airframe_context.get("shield_capacity", base))), 0, 999)

static func starting_wave(mission: Dictionary) -> int:
	return maxi(1, int(mission.get("starting_wave", 1)))

static func live_wave(mission: Dictionary, mission_time: float) -> int:
	return starting_wave(mission) + int(maxf(0.0, mission_time) / 20.0)
