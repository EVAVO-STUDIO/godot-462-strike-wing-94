extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")
const MovementPatternDirector = preload("res://scripts/movement_pattern_director.gd")
const BossHudRules = preload("res://scripts/boss_hud_rules.gd")
const BossHudDirector = preload("res://scripts/boss_hud_director.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
const ThreatWarningDirector = preload("res://scripts/threat_warning_director.gd")
const ProjectileCueRules = preload("res://scripts/projectile_cue_rules.gd")
const ProjectileCueDirector = preload("res://scripts/projectile_cue_director.gd")
const RunSeedRules = preload("res://scripts/run_seed_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_overtime()
	_test_spawn_coverage()
	_test_dedicated_rng_and_fail_closed_spawns()
	_test_movement_patterns()
	_test_autoloads()
	_test_boss_hud()
	_test_threat_warning()
	_test_projectile_cues()
	_test_native_missiles()
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

func _test_dedicated_rng_and_fail_closed_spawns() -> void:
	var seed0 := RunSeedRules.mission_seed(0)
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = seed0
	b.seed = seed0
	var same := true
	for _i in range(8):
		if a.randi() != b.randi():
			same = false
			break
	_expect(same, "same mission seed should reproduce the dedicated RNG stream")
	var c := RandomNumberGenerator.new()
	c.seed = RunSeedRules.mission_seed(1)
	var d := RandomNumberGenerator.new()
	d.seed = seed0
	_expect(c.randi() != d.randi(), "different mission seeds should diverge")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for RNG/spawn safety checks")
	if main_file == null:
		return
	var text := main_file.get_as_text()
	_expect(text.contains("mission_rng := RandomNumberGenerator.new()"), "main gameplay should own a dedicated mission RNG")
	_expect(text.contains("mission_rng.seed = RunSeedRules.mission_seed(mission_index)"), "mission RNG should reseed from authored mission seed on launch/retry")
	_expect(text.contains("ProjectileRules.pickup_kind_for_roll(mission_rng.randf())"), "pickup rolls should use mission RNG")
	_expect(text.contains("mission_rng.randi_range(0, candidates.size() - 1)"), "enemy selection should use mission RNG")
	_expect(not text.contains("pickup_kind_for_roll(randf())"), "global randf must not drive pickup rolls")
	_expect(not text.contains("randi() % candidates.size()"), "global randi must not drive enemy selection")
	_expect(text.contains("if allowed_ids.is_empty():\n\t\treturn []"), "missing spawn profile should fail closed directly in main")
	_expect(not text.contains("if allowed_ids.is_empty() or str(item.get"), "spawn candidates must never broaden to every non-boss enemy")

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

func _test_autoloads() -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(file != null, "project.godot should be readable")
	if file == null:
		return
	var text := file.get_as_text()
	_expect(not text.contains("SpawnSafetyDirector"), "redundant spawn safety autoload should stay removed")
	_expect(not text.contains("MissileBehaviorDirector"), "redundant missile behavior autoload should stay removed")
	_expect(text.contains("MovementPatternDirector=\"*res://scripts/movement_pattern_director.gd\""), "movement pattern director must remain autoloaded")
	_expect(text.contains("BossHudDirector=\"*res://scripts/boss_hud_director.gd\""), "boss HUD director must remain autoloaded")
	_expect(text.contains("ThreatWarningDirector=\"*res://scripts/threat_warning_director.gd\""), "threat warning director must remain autoloaded")
	_expect(text.contains("ProjectileCueDirector=\"*res://scripts/projectile_cue_director.gd\""), "projectile cue director must remain autoloaded")

func _test_boss_hud() -> void:
	_expect(absf(BossHudRules.health_ratio(50, 100) - 0.5) < 0.001, "boss HUD health ratio should reflect current/max HP")
	_expect(BossHudRules.health_ratio(-1, 100) == 0.0 and BossHudRules.health_ratio(120, 100) == 1.0, "boss HUD health ratio should clamp safely")
	var text := BossHudRules.hud_text("missile_cruiser", 40, 105, 3)
	_expect(text.contains("MISSILE CRUISER") and text.contains("PHASE 3") and text.contains("40/105") and text.contains("WEAK POINT EXPOSED"), "boss HUD text should expose identity phase HP and phase cue")
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

func _test_projectile_cues() -> void:
	var missile := {"homing":true,"damage":10,"velocity":Vector2(0,180)}
	var cannon := {"homing":false,"damage":16,"velocity":Vector2(0,100)}
	var burst := {"homing":false,"damage":8,"velocity":Vector2(0,220)}
	_expect(ProjectileCueRules.projectile_type(missile) == ProjectileCueRules.TYPE_MISSILE, "homing shot should receive missile cue")
	_expect(ProjectileCueRules.projectile_type(cannon) == ProjectileCueRules.TYPE_CANNON, "heavy or slow shot should receive cannon cue")
	_expect(ProjectileCueRules.projectile_type(burst) == ProjectileCueRules.TYPE_BURST, "fast light shot should receive burst cue")
	_expect(ProjectileCueRules.radius_for(missile) > ProjectileCueRules.radius_for(burst), "missile cue should be visually larger than burst cue")
	_expect(ProjectileCueRules.trail_length_for(missile) > ProjectileCueRules.trail_length_for(cannon), "missile cue should carry longest trail")
	var cue := ProjectileCueDirector.new()
	_expect(cue != null, "projectile cue director should instantiate")
	cue.free()

func _test_native_missiles() -> void:
	var file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(file != null, "main.gd should be readable for native missile checks")
	if file == null:
		return
	var source := file.get_as_text()
	_expect(source.contains("func _make_enemy_shot"), "main should own enemy projectile packet creation")
	_expect(source.contains('shot["homing"] = true'), "native missile packet should set homing flag")
	_expect(source.contains('shot["homing_speed"]'), "native missile packet should preserve homing speed")
	_expect(source.contains('shot["turn_rate"] = 1.8'), "native missile packet should set turn rate")
	_expect(source.contains('shot["life"] = 5.0'), "native missile packet should set finite lifetime")
	_expect(source.contains('var is_missile := weapon_id == "missile"'), "enemy weapon firing should classify missile at source")
	_expect(source.contains("_make_enemy_shot(origin, velocity, damage, is_missile)"), "base missile projectile should receive native homing metadata")
	_expect(source.contains("_make_enemy_shot(origin, velocity.rotated(0.08), damage + 3, true)"), "secondary missile projectile should receive native homing metadata")
	_expect(not FileAccess.file_exists("res://scripts/missile_behavior_director.gd"), "obsolete missile behavior director should remain deleted")
	_expect(not FileAccess.file_exists("res://scripts/missile_behavior_rules.gd"), "obsolete missile behavior rules should remain deleted")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
