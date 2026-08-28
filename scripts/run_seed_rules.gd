class_name RunSeedRules
extends RefCounted

const BASE_SEED := 940062
const MISSION_STRIDE := 1009

static func mission_seed(mission_index: int) -> int:
	return BASE_SEED + maxi(0, mission_index) * MISSION_STRIDE

static func same_mission_reproducible(first_index: int, second_index: int) -> bool:
	return mission_seed(first_index) == mission_seed(second_index)

static func missions_are_distinct(first_index: int, second_index: int) -> bool:
	if first_index == second_index:
		return false
	return mission_seed(first_index) != mission_seed(second_index)
