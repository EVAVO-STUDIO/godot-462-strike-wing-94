class_name SpawnSafetyRules
extends RefCounted

const SENTINEL_ENEMY_ID := "__spawn_blocked__"

static func has_matching_profile(profiles: Array, environment: String, wave: int) -> bool:
	for profile in profiles:
		if typeof(profile) != TYPE_DICTIONARY:
			continue
		if str(profile.get("environment", "")) != environment:
			continue
		if wave >= int(profile.get("min_wave", 1)) and wave <= int(profile.get("max_wave", 99)):
			var ids = profile.get("enemy_ids", [])
			return typeof(ids) == TYPE_ARRAY and not ids.is_empty()
	return false

static func sentinel_profile(environment: String, wave: int) -> Dictionary:
	return {
		"id": "runtime_spawn_block",
		"environment": environment,
		"min_wave": wave,
		"max_wave": wave,
		"enemy_ids": [SENTINEL_ENEMY_ID]
	}
