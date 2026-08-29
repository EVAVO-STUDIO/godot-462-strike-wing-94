class_name MissionFlowRules
extends RefCounted

static func required_boss_incomplete(current_boss_id: String, objectives: Array, progress: Dictionary) -> bool:
	if current_boss_id == "":
		return false
	for objective in objectives:
		if not bool(objective.get("required", true)):
			continue
		if str(objective.get("type", "")) != "destroy_enemy":
			continue
		if str(objective.get("enemy_id", "")) != current_boss_id:
			continue
		var required_count := maxi(1, int(objective.get("count", 1)))
		return int(progress.get(str(objective.get("id", "")), 0)) < required_count
	return false

static func should_hold_overtime(current_boss_id: String, objectives: Array, progress: Dictionary, enemies: Array) -> bool:
	if not required_boss_incomplete(current_boss_id, objectives, progress):
		return false
	for enemy in enemies:
		if typeof(enemy) == TYPE_DICTIONARY and bool(enemy.get("boss", false)) and str(enemy.get("id", "")) == current_boss_id and int(enemy.get("hp", 0)) > 0:
			return true
	return false
