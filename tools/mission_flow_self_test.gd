extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")
const MovementPatternDirector = preload("res://scripts/movement_pattern_director.gd")
const BossHudRules = preload("res://scripts/boss_hud_rules.gd")
const BossHudDirector = preload("res://scripts/boss_hud_director.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const ThreatWarningDirector = preload("res://scripts/threat_warning_director.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_overtime()
	_test_spawn_coverage()
	_test_movement_patterns()
	_test_movement_autoload()
	_test_boss_hud()
	_test_threat_warning()
	if failures.is_empty():
		print("Strike Wing mission flow self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_overtime() -> void:
	var objectives := [{"id":"boss","type":"destroy_enemy","enemy_id":"gunship_alpha","count":1,"required":true}]
	var incomplete := {"boss":0}
	var complete := {"boss":1}
	var live_boss := [{"id":"gunship_alpha","boss":true,"hp":20}]
	var dead_boss := [{"id":"gunship_alpha","boss":true,"hp":0}]
	_expect(MissionFlowRules.should_hold_overtime("gunship_alpha", objectives, incomplete, live_boss), "live required boss should hold mission in overtime")
	_expect(not MissionFlowRules.should_hold_overtime("gunship_alpha", objectives, complete, live_boss), "completed boss objective must not hold overtime")
	_expect(not MissionFlowRules.should_hold_overtime("gunship_alpha", objectives, incomplete, dead_boss), "dead boss must not hold overtime")
	var pre := MissionFlowRules.safe_pre_frame_time(149.99, 150.0, 0.016)
	_expect(pre + 0.016 < 150.0, "overtime pre-frame clamp must keep scene timer below failure threshold")

func _test_spawn_coverage() -> void:
	var data = ContentCatalog.load_json("res://data/spawn_profiles.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "spawn profile catalogue should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var profiles: Array = data.get("profiles", [])
	var environments: Dictionary = {}
	for profile in profiles:
		environments[str(profile.get("environment", ""))] = true
	for environment in environments.keys():
		var ranges: Array = []
		for profile in profiles:
			if str(profile.get("environment", "")) == str(environment):
				ranges.append({"min":int(profile.get("min_wave", 1)), "max":int(profile.get("max_wave", 0))})
		ranges.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["min"]) < int(b["min"]))
		var next_wave := 1
		for range in ranges:
			_expect(int(range["min"]) <= next_wave, "%s spawn profiles must not leave a wave gap before %d" % [environment, next_wave])
			next_wave = maxi(next_wave, int(range["max"]) + 1)
		_expect(next_wave >= 100, "%s spawn profiles should cover through wave 99" % environment)

func _test_movement_patterns() -> void:
	var data = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "enemy catalogue should load for movement patterns")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var supported := MovementPatternRules.supported_patterns()
	var seen: Dictionary = {}
	for enemy in data.get("enemies", []):
		if bool(enemy.get("boss", false)):
			continue
		var pattern := str(enemy.get("pattern", ""))
		seen[pattern] = true
		_expect(pattern in supported, "unsupported authored movement pattern: %s" % pattern)
	for required in ["sine_dive", "tracking_sweep", "hover_strafe", "road_column", "water_lane", "static", "aggressive_weave"]:
		_expect(seen.has(required), "missing authored movement pattern: %s" % required)
	var base := Vector2(200, 100)
	var player := Vector2(400, 200)
	_expect(MovementPatternRules.adjusted_position("tracking_sweep", base, player, 1.0, 1.0, 200.0).x > base.x, "tracking sweep should move toward player")
	_expect(MovementPatternRules.adjusted_position("hover_strafe", base, player, 1.0, 1.0, 200.0).y < base.y, "hover strafe should resist downward travel")
	_expect(MovementPatternRules.adjusted_position("road_column", Vector2(240,100), player, 1.0, 1.0, 200.0).x < 240.0, "road column should return toward lane anchor")
	_expect(MovementPatternRules.adjusted_position("static", Vector2(240,100), player, 1.0, 1.0, 200.0).x == 200.0, "static emplacement should lock to anchor")
	_expect(MovementPatternRules.clamp_x(Vector2(999,100), 36.0, 604.0).x == 604.0, "movement clamp should retain playfield bounds")
	var director := MovementPatternDirector.new()
	_expect(director != null, "movement pattern director should instantiate")
	director.free()

func _test_movement_autoload() -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(file != null, "project.godot should be readable")
	if file == null:
		return
	var text := file.get_as_text()
	_expect(text.contains("MovementPatternDirector=\"*res://scripts/movement_pattern_director.gd\""), "movement pattern director must remain autoloaded")
	_expect(text.contains("BossHudDirector=\"*res://scripts/boss_hud_director.gd\""), "boss HUD director must remain autoloaded")
	_expect(text.contains("ThreatWarningDirector=\"*res://scripts/threat_warning_director.gd\""), "threat warning director must remain autoloaded")

func _test_boss_hud() -> void:
	_expect(absf(BossHudRules.health_ratio(50, 100) - 0.5) < 0.001, "boss HUD health ratio should reflect current/max HP")
	_expect(BossHudRules.health_ratio(-1, 100) == 0.0 and BossHudRules.health_ratio(120, 100) == 1.0, "boss HUD health ratio should clamp safely")
	var text := BossHudRules.hud_text("missile_cruiser", 40, 105, 3)
	_expect(text.contains("MISSILE CRUISER") and text.contains("PHASE 3") and text.contains("40/105"), "boss HUD text should expose identity phase and HP")
	var hud := BossHudDirector.new()
	_expect(hud != null, "boss HUD director should instantiate")
	hud.free()

func _test_threat_warning() -> void:
	var bullets := [
		{"position":Vector2(100,0),"homing":true},
		{"position":Vector2(300,0),"homing":true},
		{"position":Vector2(10,0),"homing":false}
	]
	_expect(ThreatWarningRules.homing_count(bullets) == 2, "threat warning should count only homing shots")
	var nearest := ThreatWarningRules.nearest_homing_distance(bullets, Vector2.ZERO)
	_expect(absf(nearest - 100.0) < 0.01, "threat warning should use nearest homing projectile distance")
	_expect(ThreatWarningRules.warning_level(nearest, 2) == 2, "close homing projectile should trigger danger level")
	_expect(ThreatWarningRules.warning_text(nearest, 2).contains("MISSILE LOCK"), "danger warning should clearly telegraph missile lock")
	_expect(ThreatWarningRules.warning_text(INF, 0) == "", "no homing shots should produce no warning")
	var warning := ThreatWarningDirector.new()
	_expect(warning != null, "threat warning director should instantiate")
	warning.free()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
