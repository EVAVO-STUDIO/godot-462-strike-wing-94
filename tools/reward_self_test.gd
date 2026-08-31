extends SceneTree

const RewardRules = preload("res://scripts/reward_rules.gd")
const AccuracyRules = preload("res://scripts/accuracy_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var progression := {
		"no_hull_damage_bonus": 500,
		"boss_kill_bonus": 1500,
		"accuracy_bonus_threshold": 0.72,
		"accuracy_bonus": 350
	}
	var objectives := [{"id":"boss","type":"destroy_enemy","enemy_id":"gunship_alpha","count":1,"required":true}]
	var complete := {"boss":1.0}
	var incomplete := {"boss":0.0}
	_expect(RewardRules.no_hull_damage_bonus(progression, 100, 100) == 500, "undamaged hull should earn authored no-damage bonus")
	_expect(RewardRules.no_hull_damage_bonus(progression, 99, 100) == 0, "damaged hull must not earn no-damage bonus")
	_expect(RewardRules.boss_kill_bonus(progression, "gunship_alpha", objectives, complete) == 1500, "completed boss objective should earn authored boss bonus")
	_expect(RewardRules.boss_kill_bonus(progression, "gunship_alpha", objectives, incomplete) == 0, "incomplete boss objective must not earn boss bonus")
	_expect(AccuracyRules.ratio(100, 72) >= 0.72, "accuracy ratio should represent confirmed hits over fired projectiles")
	_expect(AccuracyRules.bonus(progression, 100, 71) == 0, "below-threshold accuracy must not earn bonus")
	_expect(AccuracyRules.bonus(progression, 100, 72) == 350, "threshold accuracy should earn authored bonus")
	_expect(AccuracyRules.bonus(progression, 0, 0) == 0, "zero-shot sortie must not earn accuracy bonus")
	var combined := RewardRules.extra_success_bonus(progression, 100, 100, "gunship_alpha", objectives, complete, 100, 72)
	_expect(int(combined.get("total", 0)) == 2350, "authored no-damage, boss and accuracy bonuses should combine without base reward")
	_test_reward_source_ownership()
	if failures.is_empty():
		print("Strike Wing reward self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_reward_source_ownership() -> void:
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for reward ownership checks")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("const RewardRules = preload"), "main should preload shared reward rules")
		_expect(source.contains("func _finish_mission(success: bool"), "mission result source should own payout")
		_expect(source.contains("RewardRules.extra_success_bonus("), "success source should calculate authored extra rewards directly")
		_expect(source.contains("var total_reward := _difficulty_reward(base_reward + objective_bonus + int(extras.get(\"total\", 0)))"), "success source should compose one difficulty-aware total payout")
		_expect(source.contains("func _difficulty_reward"), "campaign risk profile should adjust the composed payout without duplicating credit ownership")
		_expect(source.contains("credits += total_reward"), "success source should apply credits exactly once")
		_expect(source.contains("MISSION COMPLETE  +%d"), "success source should format complete payout result")
		_expect(source.contains("mission_success = success"), "mission result should persist explicit success/failure state for presentation and flow")
		_expect(source.contains("if not mission_success:") and source.contains("_start_mission()"), "confirm on a failed sortie should retry instead of advancing campaign progression")
		_expect(source.contains("shots_fired") and source.contains("shots_hit"), "success payout should consume exact scene accuracy counters")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable for reward autoload checks")
	if project != null:
		_expect(not project.get_as_text().contains("RewardDirector"), "reward result-transition autoload should stay removed")
	_expect(not FileAccess.file_exists("res://scripts/reward_director.gd"), "obsolete reward director file should remain deleted")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
