extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EncounterRules = preload("res://scripts/encounter_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/missions.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "missions catalogue should load")
	if typeof(data) == TYPE_DICTIONARY:
		var enemy_data = ContentCatalog.load_json("res://data/enemies.json")
		var enemy_ids: Dictionary = {}
		if typeof(enemy_data) == TYPE_DICTIONARY:
			for enemy in enemy_data.get("enemies", []):
				enemy_ids[str(enemy.get("id", ""))] = true
		for mission in data.get("missions", []):
			var beats := EncounterRules.beats_for_mission(mission)
			_expect(beats.size() >= 5, "%s should contain at least five authored encounter beats" % str(mission.get("id", "mission")))
			_expect(EncounterRules.valid_schedule(beats, float(mission.get("duration_seconds", 1.0))), "%s encounter schedule should be ordered, unique and in-bounds" % str(mission.get("id", "mission")))
			var has_reward := false
			var has_quiet_window := false
			var has_secret := false
			var formations: Dictionary = {}
			for beat in beats:
				var enemy_list := EncounterRules.expanded_enemy_ids(beat)
				for enemy_id in enemy_list:
					_expect(enemy_ids.has(enemy_id), "%s encounter references unknown enemy %s" % [str(mission.get("id", "mission")), enemy_id])
				formations[EncounterRules.formation(beat)] = true
				var points := EncounterRules.formation_points(beat, enemy_list.size())
				_expect(points.size() == enemy_list.size(), "%s encounter formation should provide one point per enemy" % str(mission.get("id", "mission")))
				if EncounterRules.reward_pickup(beat) != "":
					has_reward = true
				if EncounterRules.suppression_seconds(beat) >= 2.0:
					has_quiet_window = true
				if EncounterRules.is_secret(beat):
					has_secret = true
					_expect(EncounterRules.condition_type(beat) != "", "%s secret encounter should use supported condition" % str(mission.get("id", "mission")))
			_expect(has_reward, "%s should include an authored recovery/reward beat" % str(mission.get("id", "mission")))
			_expect(has_quiet_window, "%s should include an authored pacing window" % str(mission.get("id", "mission")))
			_expect(has_secret, "%s should include a replayable mastery secret" % str(mission.get("id", "mission")))
			_expect(formations.size() >= 3, "%s should use at least three formation shapes" % str(mission.get("id", "mission")))
	_test_rule_safety()
	_test_secret_conditions()
	_test_formation_geometry()
	if failures.is_empty():
		print("Strike Wing encounter self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_rule_safety() -> void:
	var beat := {"id":"pressure","at_seconds":12.0,"label":"Pressure Wave","enemies":[{"id":"scout_falcon","count":99}],"pickup":"not_real","suppress_random_seconds":99.0}
	_expect(EncounterRules.expanded_enemy_ids(beat).size() == EncounterRules.MAX_ENEMIES_PER_BEAT, "encounter enemy expansion should retain hard cap")
	_expect(EncounterRules.reward_pickup(beat) == "", "unknown encounter pickup should fail closed")
	_expect(EncounterRules.suppression_seconds(beat) == EncounterRules.MAX_SUPPRESSION_SECONDS, "encounter suppression should retain hard cap")
	_expect(EncounterRules.label(beat) == "PRESSURE WAVE", "encounter label should normalize for HUD use")
	var beats := [beat]
	_expect(EncounterRules.due_beat(beats, 0, 11.9).is_empty(), "encounter should not trigger before authored time")
	_expect(not EncounterRules.due_beat(beats, 0, 12.0).is_empty(), "encounter should trigger at authored time")

func _test_secret_conditions() -> void:
	var accuracy := {"secret":true,"condition":{"type":"accuracy_at_least","value":0.75,"minimum_shots":20}}
	_expect(not EncounterRules.condition_met(accuracy, {"shots_fired":1,"shots_hit":1}), "accuracy secret should require meaningful shot sample")
	_expect(EncounterRules.condition_met(accuracy, {"shots_fired":20,"shots_hit":15}), "accuracy secret should unlock at authored threshold")
	_expect(not EncounterRules.condition_met(accuracy, {"shots_fired":20,"shots_hit":14}), "accuracy secret should fail below authored threshold")
	var score := {"secret":true,"condition":{"type":"score_at_least","value":5000}}
	_expect(EncounterRules.condition_met(score, {"score":5000}), "score secret should unlock at threshold")
	_expect(not EncounterRules.condition_met(score, {"score":4999}), "score secret should fail below threshold")
	var bombs := {"secret":true,"condition":{"type":"bombs_at_least","value":2}}
	_expect(EncounterRules.condition_met(bombs, {"bombs":2}), "resource-conservation secret should unlock at threshold")
	_expect(not EncounterRules.condition_met(bombs, {"bombs":1}), "resource-conservation secret should fail below threshold")

func _test_formation_geometry() -> void:
	var wedge := EncounterRules.formation_points({"formation":"wedge"}, 5)
	_expect(wedge.size() == 5 and absf(wedge[0].x - 0.5) < 0.001, "wedge should lead from centre lane")
	_expect(wedge[1].x < 0.5 and wedge[2].x > 0.5, "wedge should alternate left/right wings")
	var split := EncounterRules.formation_points({"formation":"split"}, 4)
	_expect(split[0].x < 0.3 and split[1].x > 0.7, "split formation should attack from both flanks")
	var column := EncounterRules.formation_points({"formation":"column"}, 4)
	_expect(absf(column[0].x - column[3].x) < 0.001 and column[3].y > column[0].y, "column should share lane with vertical spacing")
	var line := EncounterRules.formation_points({"formation":"line"}, 4)
	_expect(line[0].x < 0.2 and line[3].x > 0.8 and line[0].y == 0.0, "line should span most of playfield width")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
