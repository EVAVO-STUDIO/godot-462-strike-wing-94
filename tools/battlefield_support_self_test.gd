extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const BattlefieldSupportRules = preload("res://scripts/battlefield_support_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_catalog()
	_test_tanker()
	_test_source_contract()
	if failures.is_empty():
		print("Strike Wing battlefield support self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_catalog() -> void:
	var data = ContentCatalog.load_json("res://data/battlefield_support.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "battlefield support catalogue should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var supports: Array = data.get("supports", [])
	_expect(supports.size() >= 7, "allied support catalogue should contain tanker, squadrons and strategic support")
	var atlas := BattlefieldSupportRules.support_for_id(supports, "atlas_tanker")
	_expect(not atlas.is_empty() and str(atlas.get("type", "")) == "tanker_rearm", "Atlas tanker should use tanker_rearm behavior")
	_expect(BattlefieldSupportRules.altitude_allowed(atlas, "mid") and BattlefieldSupportRules.altitude_allowed(atlas, "high"), "Atlas tanker should support mid/high altitude")
	_expect(not BattlefieldSupportRules.altitude_allowed(atlas, "low") and not BattlefieldSupportRules.altitude_allowed(atlas, "orbital"), "Atlas tanker should not appear in low/orbital envelope")
	var ids := BattlefieldSupportRules.allowed_ids({"support":["rapier_flight","atlas_tanker","rapier_flight"]})
	_expect(ids == ["rapier_flight","atlas_tanker"], "mission support list should preserve order and remove duplicates")

func _test_tanker() -> void:
	var tanker := Vector2(320, 82)
	var hose := BattlefieldSupportRules.tanker_hose_point(tanker)
	_expect(hose.y > tanker.y, "tanker hose point should trail behind the aircraft")
	_expect(BattlefieldSupportRules.tanker_connected(hose, tanker), "player at hose point should connect")
	_expect(not BattlefieldSupportRules.tanker_connected(hose + Vector2(50,0), tanker), "player outside tanker radius should not connect")
	var progress := BattlefieldSupportRules.tanker_progress(0.0, true, 2.0)
	_expect(absf(progress - 2.0) < 0.001, "connected tanker progress should accumulate")
	progress = BattlefieldSupportRules.tanker_progress(progress, false, 1.0)
	_expect(absf(progress - 1.5) < 0.001, "broken tanker hookup should decay gradually rather than reset instantly")
	_expect(BattlefieldSupportRules.tanker_complete(BattlefieldSupportRules.TANKER_REQUIRED_SECONDS), "full authored hookup duration should complete tanker rearm")
	_expect(BattlefieldSupportRules.tanker_restore(90.0, 100.0, 32.0, 1.0) == 100.0, "tanker restore should clamp at system maximum")

func _test_source_contract() -> void:
	var file := FileAccess.open("res://scripts/battlefield_support_director.gd", FileAccess.READ)
	_expect(file != null, "battlefield_support_director.gd should be readable")
	if file != null:
		var source := file.get_as_text()
		_expect(source.contains('KEY_B') and source.contains('KEY_F'), "battlefield support should expose cycle/call controls")
		_expect(source.contains('BattlefieldSupportRules.tanker_connected'), "tanker runtime should use shared hookup rules")
		_expect(source.contains('TANKER REARM COMPLETE'), "successful tanker hookup should communicate completion")
		_expect(source.contains('support_director.call("rearm_support")'), "tanker should reset tactical support cooldown")
		_expect(source.contains('applied = mini(applied, maxi(0, hp - 1))'), "battlefield support strikes must remain nonlethal to bosses")
		_expect(source.contains('scene.call("_register_destroy", enemy)'), "support kills should register mission objectives")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('BattlefieldSupportDirector="*res://scripts/battlefield_support_director.gd"'), "battlefield support director should remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
