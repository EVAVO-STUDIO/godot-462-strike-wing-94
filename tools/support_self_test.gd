extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EnergyRules = preload("res://scripts/energy_rules.gd")
const SupportRules = preload("res://scripts/support_rules.gd")
const SupportDirector = preload("res://scripts/support_director.gd")
const TechProgressionRules = preload("res://scripts/tech_progression_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_catalogue()
	_test_selection()
	_test_projectile_geometry()
	_test_point_defence()
	_test_emp_targeting()
	_test_activation_gate()
	_test_generator_efficiency()
	_test_strategic_support()
	_test_wiring()
	if failures.is_empty():
		print("Strike Wing support self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_catalogue() -> void:
	var data = ContentCatalog.load_json("res://data/support_systems.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "support catalogue should load")
	if typeof(data) != TYPE_DICTIONARY: return
	var supports: Array = data.get("supports", [])
	_expect(supports.size() == 7, "support catalogue should expose six conventional/EM systems plus one strategic system")
	var seen: Dictionary = {}
	var previous_cost := -1
	for support in supports:
		var id := str(support.get("id", "")); var kind := SupportRules.support_type(support)
		_expect(id != "" and not seen.has(id), "support IDs should be unique")
		seen[id] = true
		_expect(kind != "", "%s should use a supported tactical type" % id)
		_expect(float(support.get("energy_cost", 0.0)) > 0.0, "%s should consume generator energy" % id)
		_expect(float(support.get("cooldown", 0.0)) > 0.0, "%s should define positive cooldown" % id)
		_expect(int(support.get("cost", 0)) >= previous_cost, "support unlock costs should be monotonic")
		previous_cost = int(support.get("cost", 0))
	for required in ["rockets", "crossfire", "hunter", "defence", "emp", "magnetic"]:
		var found := false
		for support in supports:
			if SupportRules.support_type(support) == required: found = true; break
		_expect(found, "support catalogue missing tactical role: %s" % required)

func _test_selection() -> void:
	_expect(SupportRules.sanitize_unlock(99, 7) == 6, "support unlock should clamp to seven-item catalogue")
	_expect(SupportRules.sanitize_selected(6, 1, 7) == 1, "selected support cannot exceed unlocked tier")
	_expect(SupportRules.cycle_selected(0, 2, 7) == 1, "support cycle should advance within unlocked set")
	_expect(SupportRules.cycle_selected(2, 2, 7) == 0, "support cycle should wrap within unlocked set")

func _test_projectile_geometry() -> void:
	var rockets := SupportRules.projectile_angles({"projectiles":2,"spread_degrees":7.0})
	_expect(rockets.size() == 2 and rockets[0] < 0.0 and rockets[1] > 0.0, "twin rockets should split around forward axis")
	var crossfire := SupportRules.projectile_angles({"projectiles":3,"spread_degrees":34.0})
	_expect(crossfire.size() == 3 and absf(crossfire[1]) < 0.001, "three-shot crossfire should retain centre projectile")

func _test_point_defence() -> void:
	var bullets := [{"position":Vector2(10,0)},{"position":Vector2(30,0)},{"position":Vector2(70,0)},{"position":Vector2(180,0)}]
	var indices := SupportRules.defence_indices(bullets, Vector2.ZERO, {"radius":100.0,"max_targets":2})
	_expect(indices == [1,0], "point defence should return nearest targets in safe reverse-removal order")
	_expect(absf(SupportRules.radius({"radius":999.0}) - 240.0) < 0.001, "electromagnetic field radius should retain hard safety cap")

func _test_emp_targeting() -> void:
	var enemies := [
		{"position":Vector2(20,0),"hp":5,"faction":"autonomous"},
		{"position":Vector2(40,0),"hp":5},
		{"position":Vector2(80,0),"hp":5,"faction":"autonomous"}
	]
	_expect(SupportRules.autonomous_enemy_indices(enemies, Vector2.ZERO, {"radius":120.0,"max_targets":6}) == [0,2], "EMP should select only nearby autonomous targets")

func _test_activation_gate() -> void:
	EnergyRules.set_active_generator({})
	var rockets := {"type":"rockets","energy_cost":16.0,"cooldown":0.55,"unlock_tech_era":"advanced_conventional"}
	_expect(SupportRules.can_activate(16.0, 0.0, rockets), "support should activate at exact energy threshold")
	_expect(not SupportRules.can_activate(15.9, 0.0, rockets), "support should reject insufficient energy")
	_expect(not SupportRules.can_activate(100.0, 0.1, rockets), "support should respect cooldown")

func _test_generator_efficiency() -> void:
	var pulse_core := {"capacity":180.0,"recharge_per_second":50.0,"efficiency_tech_era":"electromagnetic","efficiency_multiplier":0.90}
	var conventional := {"type":"rockets","energy_cost":20.0,"cooldown":1.0,"unlock_tech_era":"advanced_conventional"}
	var emp := {"type":"emp","energy_cost":40.0,"cooldown":5.0,"unlock_tech_era":"electromagnetic"}
	EnergyRules.set_active_generator(pulse_core)
	_expect(absf(SupportRules.energy_cost(conventional) - 20.0) < 0.001, "Pulse Core should not discount older conventional tactical systems")
	_expect(absf(SupportRules.energy_cost(emp) - 36.0) < 0.001, "Pulse Core should reduce matching electromagnetic tactical energy cost")
	EnergyRules.set_active_generator({})

func _test_strategic_support() -> void:
	var data = ContentCatalog.load_json("res://data/support_systems.json")
	var supports: Array = data.get("supports", []) if typeof(data) == TYPE_DICTIONARY else []
	var strategic: Dictionary = {}
	for support in supports:
		if str(support.get("id", "")) == "micro_warhead_rack": strategic = support; break
	_expect(not strategic.is_empty(), "strategic-orbital campaign should include Micro-Warhead Rack")
	_expect(str(strategic.get("unlock_tech_era", "")) == "strategic_orbital", "Micro-Warhead must remain ORB-era hardware")
	_expect(bool(strategic.get("strategic", false)), "Micro-Warhead projectile should carry strategic metadata")
	_expect(float(strategic.get("cooldown", 0.0)) >= 900.0, "Micro-Warhead should be effectively one use per sortie without rearm")
	_expect(int(strategic.get("projectiles", 0)) == 1 and int(strategic.get("damage", 0)) >= 20, "Micro-Warhead should remain one heavy guided penetrator")
	_expect(not TechProgressionRules.can_unlock("strategic_orbital", "directed_energy"), "Micro-Warhead must remain unavailable before Machine Ark")

func _test_wiring() -> void:
	var director := SupportDirector.new(); _expect(director != null, "SupportDirector should instantiate"); director.free()
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign_save.gd should be readable")
	if save_file != null:
		var source := save_file.get_as_text()
		_expect(source.contains("SAVE_VERSION := 5"), "support persistence should remain inside campaign save v5")
		_expect(source.contains('"support_selected"') and source.contains('"support_unlocked"'), "campaign save should persist support state")
	var director_file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(director_file != null, "support director source should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("if phase == 1 and _last_phase != 1:"), "fresh sortie should reset tactical cooldown state")
		_expect(source.contains("_reset_sortie_state()"), "support owner should expose explicit sortie reset")
		_expect(source.contains('"strategic_support": bool(support.get("strategic", false))'), "support projectiles should preserve strategic metadata")
		_expect(source.contains('func rearm_support()'), "Atlas should retain tactical rearm API")
	var cue_file := FileAccess.open("res://scripts/projectile_cue_director.gd", FileAccess.READ)
	_expect(cue_file != null, "projectile cue director should be readable")
	if cue_file != null:
		var source := cue_file.get_as_text()
		_expect(source.contains('bool(shot.get("strategic_support", false))') and source.contains("_draw_strategic_warhead"), "strategic warhead should have dedicated projectile presentation")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
