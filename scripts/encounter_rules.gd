class_name EncounterRules
extends RefCounted

const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")

const ALLOWED_PICKUPS := ["", "shield", "repair", "bomb", "weapon"]
const ALLOWED_CONDITIONS := ["", "accuracy_at_least", "score_at_least", "bombs_at_least", "altitude_is", "form_is", "altitude_form"]
const ALLOWED_FORMATIONS := ["scatter", "line", "wedge", "split", "column", "stagger"]
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

static func formation(beat: Dictionary) -> String:
	var value := str(beat.get("formation", "scatter"))
	return value if value in ALLOWED_FORMATIONS else "scatter"

static func formation_points(beat: Dictionary, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var total := clampi(count, 0, MAX_ENEMIES_PER_BEAT)
	if total <= 0:
		return result
	var kind := formation(beat)
	for i in range(total):
		var point := Vector2(0.5, float(i) * 8.0)
		match kind:
			"line":
				point.x = 0.5 if total == 1 else lerpf(0.12, 0.88, float(i) / float(total - 1))
				point.y = 0.0
			"wedge":
				if i == 0:
					point = Vector2(0.5, 0.0)
				else:
					var rank := int((i + 1) / 2)
					var side := -1.0 if i % 2 == 1 else 1.0
					point = Vector2(clampf(0.5 + side * 0.13 * rank, 0.1, 0.9), float(rank) * 12.0)
			"split":
				var rank := int(i / 2)
				point = Vector2(0.18 + float(rank) * 0.07 if i % 2 == 0 else 0.82 - float(rank) * 0.07, float(rank) * 12.0)
			"column":
				point = Vector2(0.5, float(i) * 18.0)
			"stagger":
				var lanes := [0.2, 0.4, 0.6, 0.8]
				point = Vector2(float(lanes[i % lanes.size()]), float(i) * 9.0)
			_:
				var lanes := [0.17, 0.33, 0.5, 0.67, 0.83]
				point = Vector2(float(lanes[(i * 2 + total) % lanes.size()]), float(i) * 7.0)
		result.append(point)
	return result

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
		"altitude_is":
			var required_altitude := str(condition.get("value", AltitudeRules.MID))
			return AltitudeRules.sanitize(required_altitude) == required_altitude and AltitudeRules.sanitize(str(state.get("altitude", AltitudeRules.MID))) == required_altitude
		"form_is":
			var required_form := str(condition.get("value", CraftFormRules.FIGHTER))
			return CraftFormRules.sanitize(required_form) == required_form and CraftFormRules.sanitize(str(state.get("form", CraftFormRules.FIGHTER))) == required_form
		"altitude_form":
			var required_altitude := str(condition.get("altitude", AltitudeRules.MID))
			var required_form := str(condition.get("form", CraftFormRules.FIGHTER))
			if AltitudeRules.sanitize(required_altitude) != required_altitude or CraftFormRules.sanitize(required_form) != required_form:
				return false
			return AltitudeRules.sanitize(str(state.get("altitude", AltitudeRules.MID))) == required_altitude and CraftFormRules.sanitize(str(state.get("form", CraftFormRules.FIGHTER))) == required_form
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
		if beat.has("formation") and str(beat.get("formation", "")) not in ALLOWED_FORMATIONS:
			return false
		ids[id] = true
		last_time = at
	return true
