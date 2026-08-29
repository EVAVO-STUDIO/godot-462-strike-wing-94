class_name AirframeRules
extends RefCounted

static func sanitize_index(index: int, catalog_size: int) -> int:
	return clampi(index, 0, maxi(0, catalog_size - 1))

static func active_frame(catalog: Array, index: int) -> Dictionary:
	if catalog.is_empty():
		return {}
	var safe := sanitize_index(index, catalog.size())
	var frame = catalog[safe]
	return frame if typeof(frame) == TYPE_DICTIONARY else {}

static func hull_capacity(frame: Dictionary, fallback: int = 100) -> int:
	return clampi(int(frame.get("hull_capacity", fallback)), 1, 999)

static func shield_capacity(frame: Dictionary, fallback: int = 100) -> int:
	return clampi(int(frame.get("shield_capacity", fallback)), 0, 999)

static func incoming_damage_multiplier(frame: Dictionary) -> float:
	return clampf(float(frame.get("incoming_damage_multiplier", 1.0)), 0.65, 1.0)

static func frame_name(frame: Dictionary) -> String:
	return str(frame.get("name", "STANDARD AIRFRAME"))

static func capacities_non_decreasing(catalog: Array) -> bool:
	var last_hull := 0
	var last_shield := 0
	for frame in catalog:
		if typeof(frame) != TYPE_DICTIONARY:
			return false
		var hull := hull_capacity(frame, 1)
		var shield := shield_capacity(frame, 0)
		if hull < last_hull or shield < last_shield:
			return false
		last_hull = hull
		last_shield = shield
	return true

static func resistance_non_decreasing(catalog: Array) -> bool:
	var previous := 1.0
	for frame in catalog:
		if typeof(frame) != TYPE_DICTIONARY:
			return false
		var current := incoming_damage_multiplier(frame)
		if current > previous + 0.0001:
			return false
		previous = current
	return true
