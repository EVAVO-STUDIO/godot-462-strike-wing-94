class_name RewardRules
extends RefCounted

const AccuracyRules = preload("res://scripts/accuracy_rules.gd")

static func no_hull_damage_bonus(progression: Dictionary, hull: int, starting_hull: int) -> int:
	if starting_hull <= 0 or hull < starting_hull:
		return 0
	return maxi(0, int(progression.get("no_hull_damage_bonus", 0)))

static func boss_objective_complete(current_boss_id: String, objectives: Array, progress: Dictionary) -> bool:
	if current_boss_id == "":
		return false
	for objective in objectives:
		if str(objective.get("type", "")) != "destroy_enemy":
			continue
		if str(objective.get("enemy_id", "")) != current_boss_id:
			continue
		var required_count := maxi(1, int(objective.get("count", 1)))
		return int(progress.get(str(objective.get("id", "")), 0)) >= required_count
	return false

static func boss_kill_bonus(progression: Dictionary, current_boss_id: String, objectives: Array, progress: Dictionary) -> int:
	if not boss_objective_complete(current_boss_id, objectives, progress):
		return 0
	return maxi(0, int(progression.get("boss_kill_bonus", 0)))

static func extra_success_bonus(progression: Dictionary, hull: int, starting_hull: int, current_boss_id: String, objectives: Array, progress: Dictionary, shots_fired: int = 0, shots_hit: int = 0) -> Dictionary:
	var no_damage := no_hull_damage_bonus(progression, hull, starting_hull)
	var boss := boss_kill_bonus(progression, current_boss_id, objectives, progress)
	var accuracy := AccuracyRules.bonus(progression, shots_fired, shots_hit)
	return {
		"no_damage": no_damage,
		"boss": boss,
		"accuracy": accuracy,
		"accuracy_ratio": AccuracyRules.ratio(shots_fired, shots_hit),
		"total": no_damage + boss + accuracy
	}
