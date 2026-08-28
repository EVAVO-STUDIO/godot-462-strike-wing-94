extends SceneTree

const RewardRules = preload("res://scripts/reward_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var progression := {
		"no_hull_damage_bonus": 500,
		"boss_kill_bonus": 1500
	}
	var objectives := [{"id":"boss","type":"destroy_enemy","enemy_id":"gunship_alpha","count":1,"required":true}]
	var complete := {"boss":1.0}
	var incomplete := {"boss":0.0}
	_expect(RewardRules.no_hull_damage_bonus(progression, 100, 100) == 500, "undamaged hull should earn authored no-damage bonus")
	_expect(RewardRules.no_hull_damage_bonus(progression, 99, 100) == 0, "damaged hull must not earn no-damage bonus")
	_expect(RewardRules.boss_kill_bonus(progression, "gunship_alpha", objectives, complete) == 1500, "completed boss objective should earn authored boss bonus")
	_expect(RewardRules.boss_kill_bonus(progression, "gunship_alpha", objectives, incomplete) == 0, "incomplete boss objective must not earn boss bonus")
	var combined := RewardRules.extra_success_bonus(progression, 100, 100, "gunship_alpha", objectives, complete)
	_expect(int(combined.get("total", 0)) == 2000, "authored success bonuses should combine without including base mission reward")
	if failures.is_empty():
		print("Strike Wing reward self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
