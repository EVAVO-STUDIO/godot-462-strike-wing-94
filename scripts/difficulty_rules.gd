class_name DifficultyRules
extends RefCounted

const IDS := ["cadet", "combat", "veteran", "ace"]

static func sanitize_profiles(raw: Variant) -> Array:
	var profiles: Array = []
	if typeof(raw) != TYPE_ARRAY: return profiles
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY: continue
		var id := str(item.get("id", "")).to_lower()
		if not id in IDS: continue
		var profile: Dictionary = item.duplicate(true)
		profile["id"] = id
		profile["name"] = str(profile.get("name", id)).to_upper()
		for key in ["enemy_hp","enemy_speed","spawn_interval","fire_interval","projectile_speed","elite_hp","elite_value","boss_interval","pickup_rate","reward"]:
			profile[key] = clampf(float(profile.get(key, 1.0)), 0.5, 1.5)
		profile["elite_chance"] = clampf(float(profile.get("elite_chance", 0.0)), 0.0, 0.75)
		profile["telegraph_seconds"] = clampf(float(profile.get("telegraph_seconds", 0.9)), 0.45, 1.5)
		profiles.append(profile)
	profiles.sort_custom(func(a: Dictionary,b: Dictionary): return IDS.find(str(a.get("id"))) < IDS.find(str(b.get("id"))))
	return profiles

static func scaled(base: float, profile: Dictionary, key: String) -> float:
	return base * float(profile.get(key, 1.0))

static func elite_index(candidate_count: int, roll: float, profile: Dictionary) -> int:
	if candidate_count <= 1 or roll >= float(profile.get("elite_chance", 0.0)): return -1
	return clampi(int(floor(float(candidate_count) * 0.55)), 0, candidate_count - 1)
