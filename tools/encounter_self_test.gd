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
			_expect(beats.size() >= 4, "%s should contain at least four authored encounter beats" % str(mission.get("id", "mission")))
			_expect(EncounterRules.valid_schedule(beats, float(mission.get("duration_seconds", 1.0))), "%s encounter schedule should be ordered, unique and in-bounds" % str(mission.get("id", "mission")))
			var has_reward := false
			var has_quiet_window := false
			for beat in beats:
				for enemy_id in EncounterRules.expanded_enemy_ids(beat):
					_expect(enemy_ids.has(enemy_id), "%s encounter references unknown enemy %s" % [str(mission.get("id", "mission")), enemy_id])
				if EncounterRules.reward_pickup(beat) != "":
					has_reward = true
				if EncounterRules.suppression_seconds(beat) >= 2.0:
					has_quiet_window = true
			_expect(has_reward, "%s should include an authored recovery/reward beat" % str(mission.get("id", "mission")))
			_expect(has_quiet_window, "%s should include an authored pacing window" % str(mission.get("id", "mission")))
	_test_rule_safety()
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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
