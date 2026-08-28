class_name AccuracyRules
extends RefCounted

static func ratio(shots_fired: int, shots_hit: int) -> float:
	if shots_fired <= 0:
		return 0.0
	return clampf(float(maxi(0, shots_hit)) / float(shots_fired), 0.0, 1.0)

static func bonus(progression: Dictionary, shots_fired: int, shots_hit: int) -> int:
	var threshold := clampf(float(progression.get("accuracy_bonus_threshold", 1.0)), 0.0, 1.0)
	if shots_fired <= 0 or ratio(shots_fired, shots_hit) < threshold:
		return 0
	return maxi(0, int(progression.get("accuracy_bonus", 0)))
