extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const SupportRules = preload("res://scripts/support_rules.gd")
const SupportDirector = preload("res://scripts/support_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_catalogue()
	_test_selection()
	_test_projectile_geometry()
	_test_point_defence()
	_test_activation_gate()
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
	if typeof(data) != TYPE_DICTIONARY:
		return
	var supports: Array = data.get("supports", [])
	_expect(supports.size() >= 4, "support catalogue should expose at least four tactical roles")
	var seen: Dictionary = {}
	var previous_cost := -1
	for support in supports:
		var id := str(support.get("id", ""))
		var kind := SupportRules.support_type(support)
		_expect(id != "" and not seen.has(id), "support IDs should be nonblank and unique")
		seen[id] = true
		_expect(kind != "", "%s should use a supported tactical type" % id)
		_expect(float(support.get("energy_cost", 0.0)) > 0.0, "%s should consume generator energy" % id)
		_expect(float(support.get("cooldown", 0.0)) > 0.0, "%s should define positive cooldown" % id)
		_expect(int(support.get("cost", 0)) >= previous_cost, "support unlock costs should be monotonic")
		previous_cost = int(support.get("cost", 0))
	for required in ["rockets", "crossfire", "hunter", "defence"]:
		var found := false
		for support in supports:
			if SupportRules.support_type(support) == required:
				found = true
				break
		_expect(found, "support catalogue missing tactical role: %s" % required)

func _test_selection() -> void:
	_expect(SupportRules.sanitize_unlock(99, 4) == 3, "support unlock should clamp to catalogue")
	_expect(SupportRules.sanitize_selected(3, 1, 4) == 1, "selected support cannot exceed unlocked tier")
	_expect(SupportRules.cycle_selected(0, 2, 4) == 1, "support cycle should advance within unlocked set")
	_expect(SupportRules.cycle_selected(2, 2, 4) == 0, "support cycle should wrap within unlocked set")

func _test_projectile_geometry() -> void:
	var rockets := SupportRules.projectile_angles({"projectiles":2,"spread_degrees":7.0})
	_expect(rockets.size() == 2 and rockets[0] < 0.0 and rockets[1] > 0.0, "twin rockets should split around forward axis")
	var crossfire := SupportRules.projectile_angles({"projectiles":3,"spread_degrees":34.0})
	_expect(crossfire.size() == 3 and absf(crossfire[1]) < 0.001, "three-shot crossfire should retain centre projectile")
	_expect(absf(crossfire[0] + crossfire[2]) < 0.001, "crossfire spread should remain symmetrical")

func _test_point_defence() -> void:
	var bullets := [
		{"position":Vector2(10,0)},
		{"position":Vector2(30,0)},
		{"position":Vector2(70,0)},
		{"position":Vector2(180,0)}
	]
	var indices := SupportRules.defence_indices(bullets, Vector2.ZERO, {"radius":100.0,"max_targets":2})
	_expect(indices == [1,0], "point defence should return nearest targets in safe reverse-removal order")
	_expect(SupportRules.defence_indices(bullets, Vector2.ZERO, {"radius":5.0,"max_targets":6}).is_empty(), "point defence should ignore threats outside radius")

func _test_activation_gate() -> void:
	var rockets := {"type":"rockets","energy_cost":16.0,"cooldown":0.55}
	_expect(SupportRules.can_activate(16.0, 0.0, rockets), "support should activate at exact energy threshold")
	_expect(not SupportRules.can_activate(15.9, 0.0, rockets), "support should reject insufficient energy")
	_expect(not SupportRules.can_activate(100.0, 0.1, rockets), "support should respect cooldown")
	var defence := {"type":"defence","energy_cost":20.0,"cooldown":1.0}
	_expect(not SupportRules.can_activate(100.0, 0.0, defence, false), "point defence should not waste energy without a target")

func _test_wiring() -> void:
	var director := SupportDirector.new()
	_expect(director != null, "SupportDirector should instantiate")
	director.free()
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable for support autoload check")
	if project != null:
		_expect(project.get_as_text().contains("SupportDirector=\"*res://scripts/support_director.gd\""), "SupportDirector must remain autoloaded")
	var save_file := FileAccess.open("res://scripts/campaign_save.gd", FileAccess.READ)
	_expect(save_file != null, "campaign_save.gd should be readable for support persistence check")
	if save_file != null:
		var source := save_file.get_as_text()
		_expect(source.contains("SAVE_VERSION := 4"), "support persistence should use campaign save v4")
		_expect(source.contains('"support_selected"') and source.contains('"support_unlocked"'), "campaign save should persist support selection and unlock state")
		_expect(source.contains("restore_support_state"), "campaign restore should restore support state through public API")
	var ui_file := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(ui_file != null, "pixel_ui_director.gd should be readable for support UI check")
	if ui_file != null:
		var ui_source := ui_file.get_as_text()
		_expect(ui_source.contains("C SUPPORT") and ui_source.contains("V SUPPORT BUY"), "pixel title UI should expose support controls")
		_expect(ui_source.contains("_support_name()"), "pixel HUD should expose selected support identity")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
