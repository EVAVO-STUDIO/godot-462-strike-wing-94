extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const BattlefieldSupportRules = preload("res://scripts/battlefield_support_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_catalog()
	_test_tanker()
	_test_production_art()
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

func _test_production_art() -> void:
	var registered_sizes := {
		"atlas_tanker": Vector2(112,64),
		"rapier_fighter": Vector2(48,28),
		"hammer_bomber": Vector2(64,36),
		"spectre_gunship": Vector2(96,56),
	}
	for family in registered_sizes:
		for frame_index in range(4):
			var frame := load("res://assets/runtime/support/battlefield/%s/%d.png" % [family, frame_index])
			_expect(frame is Texture2D and frame.get_size() == registered_sizes[family], "battlefield support frame should retain registered geometry: %s/%d" % [family, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/support/battlefield_support/battlefield_support_asset_manifest.json"), "battlefield support source/runtime manifest should exist")
	var effect_sizes := {"tanker_hose":Vector2(64,32),"tanker_contact":Vector2(64,64),"tanker_meter_trough":Vector2(80,6),"tanker_meter_fill":Vector2(80,4),"strike_bomb":Vector2(16,32),"tracer":Vector2(64,8),"rail_beam":Vector2(12,64),"orbital_beam":Vector2(12,64),"orbital_impact":Vector2(48,48)}
	for effect_name in effect_sizes:
		var effect := load("res://assets/runtime/support/battlefield/effects/%s.png" % effect_name)
		_expect(effect is Texture2D and effect.get_size() == effect_sizes[effect_name], "support effect should retain registered geometry: %s" % effect_name)
	for prefix in ["impact", "rail_charge"]:
		for frame_index in range(3):
			var frame := load("res://assets/runtime/support/battlefield/effects/%s_%d.png" % [prefix, frame_index])
			_expect(frame is Texture2D and frame.get_size() == Vector2(48,48), "support effect animation should retain registered geometry: %s/%d" % [prefix, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/support/battlefield_support/effect_manifest.json"), "battlefield support effect manifest should exist")

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
		for visual in ["_draw_fighter_sweep", "_draw_bomber_run", "_draw_gunship_fire", "_draw_missile_strike", "_draw_rail_strike", "_draw_orbital_strike"]:
			_expect(source.contains(visual), "allied support presentation missing set piece: %s" % visual)
		_expect(source.contains("_visual_timer = 1.25"), "immediate support set pieces should remain short and readable")
		_expect(source.contains("_priority_target_position(scene)"), "precision support visuals should anchor to a real priority target")
		_expect(source.contains("BattlefieldSupportArtLibrary") and source.contains("_draw_support_craft"), "tanker, fighter, bomber and gunship set pieces should use authored sprite animation")
		_expect(not source.contains("draw_line") and not source.contains("draw_circle") and not source.contains("draw_rect"), "battlefield support effects should not regress to vector line, circle or rectangle programmer art")
		var craft_section_start := source.find("func _draw_tanker")
		var craft_section_end := source.find("func _draw_missile_strike")
		var craft_source := source.substr(craft_section_start, craft_section_end - craft_section_start)
		_expect(not craft_source.contains("draw_colored_polygon") and not craft_source.contains('var body := Color'), "support aircraft bodies should not regress to prototype vector geometry")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('BattlefieldSupportDirector="*res://scripts/battlefield_support_director.gd"'), "battlefield support director should remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
