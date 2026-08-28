class_name WeaponPickupRules
extends RefCounted

static func temporary_boost_for_indices(permanent_index: int, current_index: int) -> int:
	return maxi(0, current_index - permanent_index)

static func effective_index(permanent_index: int, temporary_boost: int, weapon_count: int) -> int:
	return clampi(permanent_index + maxi(0, temporary_boost), 0, maxi(0, weapon_count - 1))

static func saved_index(permanent_index: int, weapon_count: int) -> int:
	return clampi(permanent_index, 0, maxi(0, weapon_count - 1))
