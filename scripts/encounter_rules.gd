class_name EncounterRules
extends RefCounted

const ALLOWED_PICKUPS := ["", "shield", "repair", "bomb", "weapon"]
const ALLOWED_CONDITIONS := ["", "accuracy_at_least", "score_at_least", "bombs_at_least"]
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

static func is_secret(beat: Dictionary) -> bool:
	return bool(beat.get("secret", false))

static func condition_type(beat: Dictionary) -> String:
	var condition = beat.get("condition", {})
	if typeof(condition) != TYPE_DICTIONARY:
		return ""
	var kind := str(condition.get("type", ""))
	return kind if kind in ALLOWED_CONDITIONS else ""

static func condition_met(beat: Dictionary, state: Dictionary) -> bool:
	var condition = beat.get("condition", {})
	if typeof(condition) != TYPE_DICTIONARY or condition.is_empty():
		return true
	var kind := condition_type(beat)
	match kind:
		"accuracy_at_least":
			var fired := maxi(0, int(state.get("shots_fired", 0)))
			var minimum_shots := maxi(1, int(condition.get("minimum_shots", 1)))
			if fired < minimum_shots:
				return false
			var hits := clampi(int(state.get("shots_hit", 0)), 0, fired)
			return float(hits) / float(fired) >= clampf(float(condition.get("value", 1.0)), 0.0, 1.0)
		"score_at_least":
			return int(state.get("score", 0)) >= maxi(0, int(condition.get("value", 0)))
		"bombs_at_least":
			return int(state.get("bombs", 0)) >= maxi(0, int(condition.get("value", 0)))
		_:
			return false

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
		if beat.has("condition") and condition_type(beat) == "":
			return false
		ids[id] = true
		last_time = at
	return true
