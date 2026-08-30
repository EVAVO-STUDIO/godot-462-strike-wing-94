class_name EncounterRules
extends RefCounted

const AltitudeRules = preload("res://scripts/altitude_rules.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")

const ALLOWED_PICKUPS := ["", "shield", "repair", "bomb", "weapon"]
const ALLOWED_CONDITIONS := ["", "accuracy_at_least", "score_at_least", "bombs_at_least", "altitude_is", "form_is", "altitude_form"]
const ALLOWED_FORMATIONS := [
	"scatter", "line", "column", "wedge", "reverse_wedge", "echelon_left", "echelon_right",
	"stagger", "split", "pincer", "crossing_attack", "bomber_box", "escort_shell", "hunter_pair",
	"rotating_swarm", "missile_screen", "low_high_layer", "delayed_reinforcement", "pursuit",
	"retreat_bait", "ambush", "feint"
]
const MAX_ENEMIES_PER_BEAT := 12
const MAX_SUPPRESSION_SECONDS := 12.0
const HIGH_INTERCEPT_VALUE_BONUS := 450

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
			"reverse_wedge":
				var rank := int((total - i) / 2)
				var side := -1.0 if i % 2 == 0 else 1.0
				point = Vector2(clampf(0.5 + side * 0.13 * rank, 0.1, 0.9), float(i / 2) * 12.0)
			"echelon_left", "echelon_right":
				var direction := -1.0 if kind == "echelon_left" else 1.0
				point = Vector2(clampf(0.5 + direction * float(i) * 0.1, 0.1, 0.9), float(i) * 11.0)
			"split":
				var rank := int(i / 2)
				point = Vector2(0.18 + float(rank) * 0.07 if i % 2 == 0 else 0.82 - float(rank) * 0.07, float(rank) * 12.0)
			"column":
				point = Vector2(0.5, float(i) * 18.0)
			"stagger":
				var lanes := [0.2, 0.4, 0.6, 0.8]
				point = Vector2(float(lanes[i % lanes.size()]), float(i) * 9.0)
			"pincer":
				var rank := int(i / 2)
				point = Vector2(0.08 + rank * 0.08 if i % 2 == 0 else 0.92 - rank * 0.08, float(rank) * 15.0)
			"crossing_attack":
				var side := -1.0 if i % 2 == 0 else 1.0
				point = Vector2(0.12 if side < 0.0 else 0.88, float(i / 2) * 18.0 + (8.0 if side > 0.0 else 0.0))
			"bomber_box":
				var columns := mini(3, total)
				point = Vector2(0.32 + float(i % columns) * 0.18, float(i / columns) * 18.0)
			"escort_shell":
				if i == 0:
					point = Vector2(0.5, 12.0)
				else:
					var shell_rank := int((i + 1) / 2)
					point = Vector2(0.5 + (-1.0 if i % 2 == 1 else 1.0) * shell_rank * 0.15, float(shell_rank - 1) * 10.0)
			"hunter_pair":
				point = Vector2(0.32 if i % 2 == 0 else 0.68, float(i / 2) * 20.0)
			"rotating_swarm":
				var angle := TAU * float(i) / float(total)
				point = Vector2(0.5 + cos(angle) * 0.3, 18.0 + sin(angle) * 18.0)
			"missile_screen":
				point = Vector2(0.1 if total == 1 else lerpf(0.1, 0.9, float(i) / float(total - 1)), 9.0 if i % 2 == 0 else 0.0)
			"low_high_layer":
				point = Vector2(0.2 + float(i % 4) * 0.2, 28.0 if i % 2 == 0 else 0.0)
			"delayed_reinforcement":
				point = Vector2(0.24 + float(i % 3) * 0.26, float(i) * 24.0)
			"pursuit":
				point = Vector2(0.5 + (-0.08 if i % 2 == 0 else 0.08), float(i) * 22.0)
			"retreat_bait":
				point = Vector2(0.5 if i == 0 else (0.18 if i % 2 == 1 else 0.82), 0.0 if i == 0 else 20.0 + float(i / 2) * 12.0)
			"ambush":
				point = Vector2(0.06 if i % 2 == 0 else 0.94, 36.0 + float(i / 2) * 10.0)
			"feint":
				point = Vector2(0.18 + float(i) * 0.08 if i < maxi(1, total / 2) else 0.88 - float(i - total / 2) * 0.04, float(i) * 9.0)
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

static func is_route_bonus(beat: Dictionary) -> bool:
	return condition_type(beat) in ["altitude_is", "form_is", "altitude_form"]

static func is_low_bomber_route(beat: Dictionary) -> bool:
	if condition_type(beat) != "altitude_form":
		return false
	var condition: Dictionary = beat.get("condition", {})
	return str(condition.get("altitude", "")) == AltitudeRules.LOW and str(condition.get("form", "")) == CraftFormRules.BOMBER

static func is_high_fighter_route(beat: Dictionary) -> bool:
	if condition_type(beat) != "altitude_form":
		return false
	var condition: Dictionary = beat.get("condition", {})
	return str(condition.get("altitude", "")) == AltitudeRules.HIGH and str(condition.get("form", "")) == CraftFormRules.FIGHTER

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
