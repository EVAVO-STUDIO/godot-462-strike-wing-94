extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")
const MovementPatternRules = preload("res://scripts/movement_pattern_rules.gd")
const PixelFont = preload("res://scripts/pixel_font.gd")
const PixelUiDirector = preload("res://scripts/pixel_ui_director.gd")
const CombatArtDirector = preload("res://scripts/combat_art_director.gd")
const ThreatWarningRules = preload("res://scripts/threat_warning_rules.gd")
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
	_test_pixel_ui()
	_test_combat_art()
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
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for bounded overtime checks")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("BOSS_OVERTIME_LIMIT_SECONDS := 45.0"), "boss overtime should retain hard cap")
		_expect(source.contains("MissionFlowRules.should_hold_overtime"), "main should evaluate boss overtime directly")
		_expect(source.contains("BOSS OVERTIME EXPIRED"), "expired overtime should fail explicitly")
		_expect(source.contains("_capture_mission_index"), "visual QA should be able to launch any authored mission deterministically")
		_expect(source.contains('argument.begins_with("--capture-mission=")'), "mission capture selector should remain command-line isolated")
	_expect(not FileAccess.file_exists("res://scripts/mission_flow_director.gd"), "obsolete mission flow director should remain deleted")

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
		for item in ranges:
			_expect(int(item["min"]) <= next_wave, "%s spawn profiles must not leave a wave gap before %d" % [environment, next_wave])
			next_wave = maxi(next_wave, int(item["max"]) + 1)
		_expect(next_wave >= 100, "%s spawn profiles should cover through wave 99" % environment)

func _test_dedicated_rng_and_fail_closed_spawns() -> void:
	var seed0 := RunSeedRules.mission_seed(0)
	var a := RandomNumberGenerator.new(); var b := RandomNumberGenerator.new()
	a.seed = seed0; b.seed = seed0
	var same := true
	for _i in range(8):
		if a.randi() != b.randi(): same = false; break
	_expect(same, "same mission seed should reproduce dedicated RNG stream")
	var c := RandomNumberGenerator.new(); c.seed = RunSeedRules.mission_seed(1)
	var d := RandomNumberGenerator.new(); d.seed = seed0
	_expect(c.randi() != d.randi(), "different mission seeds should diverge")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for RNG/spawn checks")
	if main_file != null:
		var text := main_file.get_as_text()
		_expect(text.contains("mission_rng := RandomNumberGenerator.new()"), "main should own mission RNG")
		_expect(text.contains("mission_rng.seed = RunSeedRules.mission_seed(mission_index)"), "mission RNG should reseed per mission/retry")
		_expect(text.contains("ProjectileRules.pickup_kind_for_roll(mission_rng.randf())"), "pickup rolls should use mission RNG")
		_expect(text.contains("if allowed_ids.is_empty():\n\t\treturn []"), "missing spawn profile should fail closed")

func _test_movement_patterns() -> void:
	var data = ContentCatalog.load_json("res://data/enemies.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "enemy catalogue should load for movement patterns")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var supported := MovementPatternRules.supported_patterns()
	var seen: Dictionary = {}
	for enemy in data.get("enemies", []):
		if bool(enemy.get("boss", false)): continue
		var pattern := str(enemy.get("pattern", "")); seen[pattern] = true
		_expect(pattern in supported, "unsupported authored movement pattern: %s" % pattern)
	for required in ["sine_dive", "tracking_sweep", "hover_strafe", "road_column", "water_lane", "static", "aggressive_weave"]:
		_expect(seen.has(required), "missing authored movement pattern: %s" % required)
	var base := Vector2(200,100); var player := Vector2(400,200)
	_expect(MovementPatternRules.adjusted_position("tracking_sweep", base, player, 1.0, 1.0, 200.0).x > base.x, "tracking sweep should move toward player")
	_expect(MovementPatternRules.adjusted_position("static", Vector2(240,100), player, 1.0, 1.0, 200.0).x == 200.0, "static placement should lock to anchor")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("position = MovementPatternRules.adjusted_position(") and source.contains("\n\t\t\t\t\tpattern,") and source.contains("\n\t\t\t\t\tplayer_position,"), "main should apply movement directly")
	_expect(not FileAccess.file_exists("res://scripts/movement_pattern_director.gd"), "obsolete movement director should remain deleted")

func _test_autoloads() -> void:
	var file := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(file != null, "project.godot should be readable")
	if file == null: return
	var text := file.get_as_text()
	for obsolete in ["SpawnSafetyDirector", "MissileBehaviorDirector", "MissionStateDirector", "BombGuardDirector", "MissionFlowDirector", "MovementPatternDirector", "BossHudDirector", "ThreatWarningDirector"]:
		_expect(not text.contains(obsolete), "obsolete autoload should stay removed: %s" % obsolete)
	_expect(text.contains("EncounterDirector=\"*res://scripts/encounter_director.gd\""), "encounter director must remain autoloaded")
	_expect(text.contains("PixelUiDirector=\"*res://scripts/pixel_ui_director.gd\""), "pixel UI director must remain autoloaded")
	_expect(text.contains("CombatArtDirector=\"*res://scripts/combat_art_director.gd\""), "combat art director must remain autoloaded")
	_expect(text.contains("ProjectileCueDirector=\"*res://scripts/projectile_cue_director.gd\""), "projectile cue director must remain autoloaded")

func _test_pixel_ui() -> void:
	_expect(PixelFont.text_width("ABC", 1, 1) == 11.0, "bitmap font width should be deterministic")
	_expect(PixelFont.text_width("A", 2, 1) == 6.0, "bitmap font should scale on integer pixels")
	var ui := PixelUiDirector.new()
	_expect(ui != null, "pixel UI director should instantiate")
	ui.free()
	var source_file := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(source_file != null, "pixel_ui_director.gd should be readable")
	if source_file != null:
		var source := source_file.get_as_text()
		_expect(source.contains("layer = 30"), "pixel UI should render above prototype scene HUD")
		_expect(source.contains("PixelFont.draw_centered"), "pixel UI should use bitmap glyph renderer")
		_expect(source.contains("HYPERSONIC_WORDMARK"), "sortie console should use the approved title art master")
		_expect(source.contains("VX94_FIGHTER") and source.contains("VX94_BOMBER"), "sortie console should retain form-specific aircraft art")
		_expect(source.contains("SORTIE_BAY_BACKDROP") and source.contains("sortie_bay_backdrop_v1.png"), "sortie console should use the authored maintenance-bay environment")
		var backdrop := load("res://assets/runtime/ui/menu/sortie_bay_backdrop_v1.png")
		_expect(backdrop is Texture2D and backdrop.get_size() == Vector2(640,360), "sortie-bay backdrop should retain canonical 640x360 geometry")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/menu_ui_asset_manifest.json"), "sortie-menu art manifest should exist")
		for menu_path in ["operations_panel_9slice.png", "operations_screen_9slice.png", "operations_button_9slice.png"]:
			var menu_texture := load("res://assets/runtime/ui/menu/%s" % menu_path)
			_expect(menu_texture is Texture2D, "missing authored menu interface sprite: %s" % menu_path)
		_expect(source.contains("UiSpriteRenderer.draw_nine_slice") and source.contains("OPERATIONS_PANEL") and source.contains("OPERATIONS_SCREEN") and source.contains("OPERATIONS_BUTTON"), "sortie console should assemble authored sprite frames instead of flat rectangle chrome")
		_expect(source.contains("AUTHORIZE LAUNCH"), "sortie console should retain a distinct launch control")
		_expect(source.contains("func _draw_console_panel"), "sortie console should retain its late-90s panel hierarchy")
		_expect(source.contains("func _draw_boss"), "pixel UI should own boss HUD")
		_expect(source.contains('var cue := " WEAK" if phase >= 3'), "phase-three boss HUD should retain weak-point cue")
		_expect(source.contains("ThreatWarningRules.warning_text"), "pixel UI should own missile warning")
		_expect(source.contains("HUD_TOP_FRAME") and source.contains("HUD_METER_TROUGH") and source.contains("HUD_BOSS_FRAME") and source.contains("HUD_THREAT_FRAME"), "gameplay HUD should use authored raster frame and meter families")
		for hud_path in ["top_frame.png", "meter_trough.png", "hull_fill.png", "shield_fill.png", "energy_fill.png", "status_frame.png", "boss_frame.png", "boss_trough.png", "boss_fill.png", "threat_frame.png", "icon_bomb.png", "icon_wave.png", "icon_time.png", "icon_score.png", "afterburner_frame.png", "afterburner_trough.png", "afterburner_fill.png", "stability_trough.png", "stability_fill.png"]:
			_expect(FileAccess.file_exists("res://assets/runtime/ui/hud/%s" % hud_path), "missing authored HUD sprite: %s" % hud_path)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud_asset_manifest.json"), "gameplay HUD production manifest should exist")
		_expect(not source.contains("PanelContainer.new()") and not source.contains("Label.new()") and not source.contains("ProgressBar.new()"), "primary pixel HUD must not use modern widget chrome")
	var intel_file := FileAccess.open("res://scripts/mission_intel_director.gd", FileAccess.READ)
	_expect(intel_file != null and intel_file.get_as_text().contains("layer = 31"), "mission intelligence overlay should render above the layer-30 sortie console")
	_expect(intel_file != null and intel_file.get_as_text().contains("UiSpriteRenderer.draw_nine_slice"), "mission intelligence overlay should use authored operations-console sprites")
	var stores_file := FileAccess.open("res://scripts/loadout_schematic_director.gd", FileAccess.READ)
	_expect(stores_file != null and stores_file.get_as_text().contains("layer = 32"), "stores schematic should render above the sortie console and mission intelligence")
	_expect(stores_file != null and stores_file.get_as_text().contains("UiSpriteRenderer.draw_nine_slice"), "stores schematic should use authored operations-console sprites")
	_expect(not FileAccess.file_exists("res://scripts/boss_hud_director.gd"), "obsolete boss HUD widget director should remain deleted")
	_expect(not FileAccess.file_exists("res://scripts/threat_warning_director.gd"), "obsolete threat widget director should remain deleted")

func _test_combat_art() -> void:
	var art := CombatArtDirector.new()
	_expect(art != null, "combat art director should instantiate")
	art.free()
	var file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(file != null, "combat art director should be readable")
	if file == null: return
	var source := file.get_as_text()
	for token in ["VX94_GAMEPLAY_FORMS", "VX94_FIGHTER_BANK", "VX94_BOMBER_BANK", "MERCENARY_AIR_SPRITES", "MERCENARY_GROUND_SPRITES", "MERCENARY_SEA_SPRITES", "MACHINE_AIR_SPRITES", "MACHINE_GROUND_SPRITES", "ORBITAL_AIR_SPRITES", "BOSS_PHASE_OVERLAYS", "has_production_art", "_report_missing_art", "layer = 12"]:
		_expect(source.contains(token), "combat art presentation missing token: %s" % token)
	_expect(not source.contains("func _draw_air") and not source.contains("func _draw_ground") and not source.contains("func _draw_sea") and not source.contains("func _draw_autonomous"), "combat art should not retain generic vector fallbacks")
	_expect(not source.contains("PanelContainer.new()") and not source.contains("Label.new()"), "combat art should remain canvas/pixel presentation")

func _test_threat_warning() -> void:
	var bullets := [{"position":Vector2(100,0),"homing":true},{"position":Vector2(300,0),"homing":true},{"position":Vector2(10,0),"homing":false}]
	_expect(ThreatWarningRules.homing_count(bullets) == 2, "warning should count only homing shots")
	var nearest := ThreatWarningRules.nearest_homing_distance(bullets, Vector2.ZERO)
	_expect(absf(nearest - 100.0) < 0.01, "warning should use nearest homing distance")
	_expect(ThreatWarningRules.warning_level(nearest, 2) == 2, "close missile should trigger danger level")
	_expect(ThreatWarningRules.warning_text(nearest, 2).contains("MISSILE LOCK"), "danger text should clearly telegraph missile lock")
	_expect(ThreatWarningRules.warning_text(INF, 0) == "", "no homing shots should produce no warning")

func _test_projectile_cues() -> void:
	var missile := {"homing":true,"damage":10,"velocity":Vector2(0,180)}
	var cannon := {"homing":false,"damage":16,"velocity":Vector2(0,100)}
	var burst := {"homing":false,"damage":8,"velocity":Vector2(0,220)}
	_expect(ProjectileCueRules.projectile_type(missile) == ProjectileCueRules.TYPE_MISSILE, "homing shot should get missile cue")
	_expect(ProjectileCueRules.projectile_type(cannon) == ProjectileCueRules.TYPE_CANNON, "heavy/slow shot should get cannon cue")
	_expect(ProjectileCueRules.projectile_type(burst) == ProjectileCueRules.TYPE_BURST, "fast light shot should get burst cue")
	var cue := ProjectileCueDirector.new(); _expect(cue != null, "projectile cue director should instantiate"); cue.free()

func _test_native_missiles() -> void:
	var file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(file != null, "main.gd should be readable for native missile checks")
	if file == null: return
	var source := file.get_as_text()
	for token in ["func _make_enemy_shot", 'shot["homing"] = true', 'shot["homing_speed"]', 'shot["turn_rate"] = 1.8', 'shot["life"] = 5.0', 'var is_missile := weapon_id == "missile"']:
		_expect(source.contains(token), "native missile path missing token: %s" % token)
	_expect(not FileAccess.file_exists("res://scripts/missile_behavior_director.gd"), "obsolete missile behavior director should remain deleted")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
