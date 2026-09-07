class_name ObjectiveRules
extends RefCounted

static func make_progress(objectives: Array) -> Dictionary:
	var result: Dictionary = {}
	for objective in objectives:
		var id := str(objective.get("id", ""))
		if id == "":
			continue
		result[id] = 0.0
	return result

static func register_destroy(objectives: Array, progress: Dictionary, enemy_id: String) -> void:
	for objective in objectives:
		var id := str(objective.get("id", ""))
		var kind := str(objective.get("type", ""))
		if id == "":
			continue
		if kind == "destroy_count":
			progress[id] = float(progress.get(id, 0.0)) + 1.0
		elif kind == "destroy_enemy" and str(objective.get("enemy_id", "")) == enemy_id:
			progress[id] = float(progress.get(id, 0.0)) + 1.0

static func update_survival(objectives: Array, progress: Dictionary, elapsed_seconds: float) -> void:
	for objective in objectives:
		if str(objective.get("type", "")) != "survive":
			continue
		var id := str(objective.get("id", ""))
		if id != "":
			progress[id] = maxf(float(progress.get(id, 0.0)), elapsed_seconds)

static func update_hypersonic_egress(objectives: Array, progress: Dictionary, lock_seconds: float) -> void:
	for objective in objectives:
		if str(objective.get("type", "")) != "hypersonic_egress":
			continue
		var id := str(objective.get("id", ""))
		if id != "":
			progress[id] = maxf(0.0, lock_seconds)

static func complete_survival(objectives: Array, progress: Dictionary) -> void:
	for objective in objectives:
		if str(objective.get("type", "")) != "survive":
			continue
		var id := str(objective.get("id", ""))
		if id != "":
			progress[id] = maxf(float(progress.get(id, 0.0)), float(objective.get("seconds", 0.0)))

static func is_complete(objective: Dictionary, progress: Dictionary) -> bool:
	var id := str(objective.get("id", ""))
	var value := float(progress.get(id, 0.0))
	match str(objective.get("type", "")):
		"survive":
			return value >= float(objective.get("seconds", 0.0))
		"hypersonic_egress":
			return value >= float(objective.get("seconds", 1.0))
		"destroy_count", "destroy_enemy":
			return value >= float(objective.get("count", 1))
		_:
			return false

static func required_complete(objectives: Array, progress: Dictionary) -> bool:
	for objective in objectives:
		if bool(objective.get("required", true)) and not is_complete(objective, progress):
			return false
	return true

static func bonus_credits(objectives: Array, progress: Dictionary) -> int:
	var total := 0
	for objective in objectives:
		if int(objective.get("bonus_credits", 0)) > 0 and is_complete(objective, progress):
			total += int(objective.get("bonus_credits", 0))
	return total

static func progress_text(objective: Dictionary, progress: Dictionary) -> String:
	var id := str(objective.get("id", ""))
	var value := float(progress.get(id, 0.0))
	match str(objective.get("type", "")):
		"survive":
			var target := maxf(1.0, float(objective.get("seconds", 0)))
			return "%d%% ROUTE" % int(roundf(clampf(value / target, 0.0, 1.0) * 100.0))
		"hypersonic_egress":
			return "%d%%" % int(roundf(clampf(value / maxf(0.01, float(objective.get("seconds", 1.0))), 0.0, 1.0) * 100.0))
		"destroy_count", "destroy_enemy":
			return "%d/%d" % [int(value), int(objective.get("count", 1))]
		_:
			return "--"
