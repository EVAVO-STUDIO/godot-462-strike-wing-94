class_name MissionStateRules
extends RefCounted

static func starting_hull(campaign: Dictionary, fallback: int = 100) -> int:
	return clampi(int(campaign.get("starting_hull", fallback)), 1, 999)

static func starting_shield(campaign: Dictionary, fallback: int = 100) -> int:
	return clampi(int(campaign.get("starting_shield", fallback)), 0, 999)

static func starting_wave(mission: Dictionary) -> int:
	return maxi(1, int(mission.get("starting_wave", 1)))

static func live_wave(mission: Dictionary, mission_time: float) -> int:
	return starting_wave(mission) + int(maxf(0.0, mission_time) / 20.0)
