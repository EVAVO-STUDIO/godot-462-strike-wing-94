extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const SupportRules = preload("res://scripts/support_rules.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_era_order()
	_test_support_gates()
	_test_emp_resistance()
	_test_source_wiring()
	if failures.is_empty():
		print("Strike Wing tech progression self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_era_order() -> void:
	_expect(TechProgressionRules.era_order("advanced_conventional") < TechProgressionRules.era_order("electromagnetic"), "electromagnetic era should follow advanced conventional")
	_expect(TechProgressionRules.era_order("electromagnetic") < TechProgressionRules.era_order("directed_energy"), "directed energy should follow electromagnetic")
	_expect(TechProgressionRules.era_order("directed_energy") < TechProgressionRules.era_order("strategic_orbital"), "strategic orbital should remain late era")
	_expect(not TechProgressionRules.can_unlock("electromagnetic", "advanced_conventional"), "early campaign must not buy electromagnetic systems")
	_expect(TechProgressionRules.can_unlock("electromagnetic", "electromagnetic"), "electromagnetic era should unlock matching technology")
	_expect(TechProgressionRules.can_unlock("advanced_conventional", "strategic_orbital"), "later eras should retain earlier technology")

func _test_support_gates() -> void:
	var data = ContentCatalog.load_json("res://data/support_systems.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "support catalogue should load for tech gates")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var supports: Array = data.get("supports", [])
	var emp := _support_for_id(supports, "emp_disruptor")
	var magnetic := _support_for_id(supports, "magnetic_screen")
	_expect(str(emp.get("unlock_tech_era", "")) == "electromagnetic", "EMP should unlock in electromagnetic era")
	_expect(str(magnetic.get("unlock_tech_era", "")) == "electromagnetic", "magnetic screen should unlock in electromagnetic era")
	for id in ["twin_rocket_pods","crosswind_cannons","hunter_rack","point_defence_pod"]:
		_expect(str(_support_for_id(supports, id).get("unlock_tech_era", "")) == "advanced_conventional", "%s should remain early-era hardware" % id)

func _test_emp_resistance() -> void:
	var enemies_data = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(enemies_data) == TYPE_DICTIONARY, "enemy catalogue should load for EMP resistance")
	if typeof(enemies_data) != TYPE_DICTIONARY:
		return
	var enemies: Array = enemies_data.get("enemies", [])
	var scout := _enemy_for_id(enemies, "drone_scout")
	var sentry := _enemy_for_id(enemies, "orbital_sentry")
	var core := _enemy_for_id(enemies, "orbital_command_node")
	var scout_res := SupportRules.emp_resistance(scout)
	var sentry_res := SupportRules.emp_resistance(sentry)
	var core_res := SupportRules.emp_resistance(core)
	_expect(scout_res < sentry_res and sentry_res < core_res, "autonomous EMP resistance should escalate into orbital threats")
	_expect(SupportRules.emp_effective_duration(3.0, scout_res) > SupportRules.emp_effective_duration(3.0, core_res), "higher EMP resistance should shorten disruption")
	_expect(SupportRules.emp_speed_scale(scout_res) < SupportRules.emp_speed_scale(core_res), "higher EMP resistance should retain more movement")
	_expect(SupportRules.emp_resistance({"emp_resistance":99.0}) <= 0.95, "EMP resistance must retain a hard upper bound")

func _test_source_wiring() -> void:
	var support := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(support != null, "support director should be readable")
	if support != null:
		var source := support.get_as_text()
		_expect(source.contains("TechProgressionRules.can_unlock"), "support purchase should enforce tech era gate")
		_expect(source.contains("TECH LOCK -"), "tech lock should be communicated in title shop")
		_expect(source.contains("SupportRules.emp_resistance(enemy)"), "EMP runtime should consume authored resistance")
		_expect(source.contains("emp_slow_scale"), "EMP runtime should preserve resistance-adjusted slow scale")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('ElectromagneticCueDirector="*res://scripts/electromagnetic_cue_director.gd"'), "electromagnetic cue overlay should remain active")

func _support_for_id(items: Array, id: String) -> Dictionary:
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == id:
			return item
	return {}

func _enemy_for_id(items: Array, id: String) -> Dictionary:
	for item in items:
		if typeof(item) == TYPE_DICTIONARY and str(item.get("id", "")) == id:
			return item
	return {}

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
