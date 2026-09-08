extends SceneTree

const ProgressionRules = preload("res://scripts/progression_rules.gd")
const ServiceRules = preload("res://scripts/service_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
const RewardRules = preload("res://scripts/reward_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var campaign_data := _json("res://data/campaign.json")
	var weapons_data := _json("res://data/weapons.json")
	var generators_data := _json("res://data/generators.json")
	var airframes_data := _json("res://data/airframes.json")
	var supports_data := _json("res://data/support_systems.json")
	var difficulty_data := _json("res://data/difficulty_profiles.json")

	var campaign: Dictionary = campaign_data.get("campaign", {})
	var progression: Dictionary = campaign_data.get("progression", {})
	var starting_credits := int(campaign.get("starting_credits", -1))
	var repair_per_hull := int(campaign.get("repair_cost_per_hull", -1))
	var shield_per_point := int(campaign.get("shield_recharge_cost_per_point", -1))

	_expect(starting_credits == 2500, "starting campaign reserve should remain 2500 credits")
	_expect(repair_per_hull == 8, "hull service price should remain 8 credits per point")
	_expect(shield_per_point == 3, "shield recharge price should remain 3 credits per point")
	_expect(ProgressionRules.mission_reward(0) == int(progression.get("mission_complete_bonus", -1)), "runtime zero-score mission reward should match campaign mission_complete_bonus")
	_expect(ProgressionRules.mission_reward(12345) == int(progression.get("mission_complete_bonus", 0)) + 1234, "mission reward should retain integer score/10 progression")

	_expect(ServiceRules.service_cost(100, 100, repair_per_hull) == 0, "full hull should have no service charge")
	_expect(ServiceRules.service_cost(75, 100, repair_per_hull) == 200, "25 missing hull should cost 200 credits")
	_expect(ServiceRules.service_cost(60, 100, shield_per_point) == 120, "40 missing shield should cost 120 credits")
	_expect(ServiceRules.service_cost(1, 100, repair_per_hull) + ServiceRules.service_cost(0, 100, shield_per_point) == 1092, "starting airframe near-loss full-service liability should remain 1092 credits")

	var optional_objectives := [
		{"id":"required","type":"destroy_count","count":1,"required":true,"bonus_credits":250},
		{"id":"optional","type":"destroy_count","count":2,"required":false,"bonus_credits":400}
	]
	var progress := {"required":1.0,"optional":1.0}
	_expect(ObjectiveRules.required_complete(optional_objectives, progress), "required objective completion should not depend on optional objectives")
	_expect(ObjectiveRules.bonus_credits(optional_objectives, progress) == 250, "only completed objective bonuses should be awarded")
	progress["optional"] = 2.0
	_expect(ObjectiveRules.bonus_credits(optional_objectives, progress) == 650, "completed optional objectives should add their authored bonus")

	var reward_probe := RewardRules.extra_success_bonus(
		progression,
		100,
		100,
		"boss_probe",
		[{"id":"boss","type":"destroy_enemy","enemy_id":"boss_probe","count":1,"required":true}],
		{"boss":1.0},
		100,
		75
	)
	_expect(int(reward_probe.get("no_damage", 0)) == int(progression.get("no_hull_damage_bonus", 0)), "no-damage reward should remain data-owned")
	_expect(int(reward_probe.get("boss", 0)) == int(progression.get("boss_kill_bonus", 0)), "boss reward should remain data-owned")
	_expect(int(reward_probe.get("accuracy", 0)) == int(progression.get("accuracy_bonus", 0)), "accuracy reward should remain data-owned")

	_check_cost_ladder("primary weapons", _filter_primary(weapons_data.get("weapons", [])))
	_check_cost_ladder("generators", generators_data.get("generators", []))
	_check_cost_ladder("airframes", airframes_data.get("airframes", []))
	_check_cost_ladder("support systems", supports_data.get("supports", []))

	var first_primary_cost := _first_positive_cost(_filter_primary(weapons_data.get("weapons", [])))
	var first_generator_cost := _first_positive_cost(generators_data.get("generators", []))
	_expect(first_primary_cost == 2600, "first primary purchase should remain the 2600-credit Spread Vulcan")
	_expect(first_generator_cost == 3200, "first generator purchase should remain the 3200-credit Field Coil Mk II")
	_expect(starting_credits < first_primary_cost and starting_credits < first_generator_cost, "fresh campaign should require completing combat before the first major upgrade")

	var profiles: Array = difficulty_data.get("profiles", [])
	_expect(profiles.size() == 4, "economy audit requires all four difficulty reward profiles")
	var reward_multipliers: Array[float] = []
	for profile in profiles:
		if typeof(profile) == TYPE_DICTIONARY:
			reward_multipliers.append(float(profile.get("reward", 0.0)))
	_expect(reward_multipliers == [0.90, 1.00, 1.18, 1.35], "difficulty reward multipliers should remain cadet/combat/veteran/ace = 0.90/1.00/1.18/1.35")

	if failures.is_empty():
		print("HYPERSONIC economy progression self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("missing JSON authority: %s" % path)
		return {}
	var value = JSON.parse_string(file.get_as_text())
	if typeof(value) != TYPE_DICTIONARY:
		failures.append("invalid JSON authority: %s" % path)
		return {}
	return value

func _filter_primary(raw: Variant) -> Array:
	var result: Array = []
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("slot", "")) == "primary":
			result.append(item)
	return result

func _check_cost_ladder(label: String, raw: Variant) -> void:
	if typeof(raw) != TYPE_ARRAY or raw.is_empty():
		failures.append("%s catalogue is empty" % label)
		return
	var previous := -1
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			failures.append("%s contains a non-dictionary entry" % label)
			continue
		var cost := int(item.get("cost", -1))
		if cost < 0:
			failures.append("%s has a negative cost" % label)
		if previous > cost:
			failures.append("%s cost ladder regressed from %d to %d" % [label, previous, cost])
		previous = cost

func _first_positive_cost(raw: Array) -> int:
	for item in raw:
		if typeof(item) == TYPE_DICTIONARY and int(item.get("cost", 0)) > 0:
			return int(item.get("cost", 0))
	return -1

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
