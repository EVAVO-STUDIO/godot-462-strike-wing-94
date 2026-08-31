class_name GameModeRules
extends RefCounted

static func sanitize_modes(value: Variant, mission_ids: Array[String]) -> Array:
	if typeof(value) != TYPE_ARRAY:
		return []
	var result: Array = []
	var seen: Dictionary = {}
	for item in value:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var mode: Dictionary = item
		var id := str(mode.get("id", ""))
		var route: Array = mode.get("missions", [])
		if id.is_empty() or seen.has(id) or route.is_empty():
			continue
		var valid_route := true
		for mission_id in route:
			if not mission_ids.has(str(mission_id)):
				valid_route = false
				break
		if not valid_route:
			continue
		seen[id] = true
		result.append(mode.duplicate(true))
	return result

static func multiplier(mode: Dictionary, key: String) -> float:
	return clampf(float(mode.get(key, 1.0)), 0.5, 3.0)

static func scaled_hp(base_hp: int, mode: Dictionary) -> int:
	return maxi(1, int(ceil(float(maxi(1,base_hp)) * multiplier(mode,"enemy_hp_multiplier"))))

static func scaled_speed(base_speed: float, mode: Dictionary) -> float:
	return maxf(1.0,base_speed * multiplier(mode,"enemy_speed_multiplier"))

static func scaled_score(base_score: int, mode: Dictionary) -> int:
	return maxi(0,int(round(float(maxi(0,base_score)) * multiplier(mode,"score_multiplier"))))
