class_name EncounterRules
extends RefCounted

const ALLOWED_PICKUPS := ["", "shield", "repair", "bomb", "weapon"]
const MAX_ENEMIES_PER_BEAT := 12
const MAX_SUPPRESSION_SECONDS := 12.0

static func beats_for_mission(mission: Dictionary) -> Array:
	var beats = mission.get("encounter_beats", [])
	return beats if typeof(beats) == TYPE_ARRAY else []

static func due_beat(beats: Array, next_index: int, mission_time: float) -> Dictionary:
	if next_index < 0 or next_index >= beats.size():
		return {}
	var beat = beats[next_index]
	if typeof(beat) != TYPE_DICTIONARY:
		return {}
	if mission_time + 0.0001 < maxf(0.0, float(beat.get("at_seconds", 0.0))):
		return {}
	return beat

static func expanded_enemy_ids(beat: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var entries = beat.get("enemies", [])
	if typeof(entries) != TYPE_ARRAY:
		return result
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id := str(entry.get("id", ""))
		if id == "":
			continue
		var count := clampi(int(entry.get("count", 1)), 1, MAX_ENEMIES_PER_BEAT)
		for _i in range(count):
			if result.size() >= MAX_ENEMIES_PER_BEAT:
				return result
			result.append(id)
	return result

static func suppression_seconds(beat: Dictionary) -> float:
	return clampf(float(beat.get("suppress_random_seconds", 0.0)), 0.0, MAX_SUPPRESSION_SECONDS)

static func reward_pickup(beat: Dictionary) -> String:
	var kind := str(beat.get("pickup", ""))
	return kind if kind in ALLOWED_PICKUPS else ""

static func label(beat: Dictionary) -> String:
	return str(beat.get("label", "ENCOUNTER")).strip_edges().to_upper()

static func valid_schedule(beats: Array, duration_seconds: float) -> bool:
	var last_time := -1.0
	var ids: Dictionary = {}
	for beat in beats:
		if typeof(beat) != TYPE_DICTIONARY:
			return false
		var id := str(beat.get("id", ""))
		var at := float(beat.get("at_seconds", -1.0))
		if id == "" or ids.has(id) or at < 0.0 or at >= duration_seconds or at <= last_time:
			return false
		if expanded_enemy_ids(beat).is_empty() and reward_pickup(beat) == "":
			return false
		ids[id] = true
		last_time = at
	return true
