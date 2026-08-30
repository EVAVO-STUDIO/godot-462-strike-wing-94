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
		_expect(source.contains("layer = 30"), "pixel UI should render as the production interface layer")
		_expect(source.contains("PixelFont.draw_centered"), "pixel UI should use bitmap glyph renderer")
		_expect(source.contains("HYPERSONIC_WORDMARK"), "sortie console should use the approved title art master")
		_expect(source.contains("_sortie_order_header(mission_index)"), "sortie console should identify the real campaign mission")
		_expect(source.contains("_draw_campaign_progress(surface, mission_index"), "sortie console should communicate thirty-mission campaign progress")
		_expect(source.contains("_draw_front_end(surface, scene, front_end)"), "title sequence should resolve into a distinct front-end menu before sortie operations")
		_expect(source.contains('_identity_text("version"') and source.contains('_identity_text("developer"'), "front-end version and studio credit should remain centralized through ProductIdentity")
		for front_end_asset in ["frame.png", "button_idle.png", "button_selected.png", "cursor.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/menu/front_end/%s" % front_end_asset), "front-end menu sprite should exist: %s" % front_end_asset)
		_expect(source.contains("_draw_support_links(surface)"), "combat HUD should expose tactical and battlefield support readiness")
		for support_link_asset in ["trough.png", "tactical_fill.png", "battlefield_fill.png", "ready.png", "charging.png", "unavailable.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/hud/support_link/%s" % support_link_asset), "support readiness sprite should exist: %s" % support_link_asset)
		_expect(source.contains("MERCENARY WAR") and source.contains("MACHINE WAR") and source.contains("BLACK SKY"), "sortie console should preserve the three canonical campaign sectors")
		for path in ["rail.png", "node_complete.png", "node_current.png", "node_locked.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/menu/campaign_progress/%s" % path), "campaign progress sprite should exist: %s" % path)
		_expect(source.contains("VX94_FIGHTER") and source.contains("VX94_BOMBER"), "sortie console should retain form-specific aircraft art")
		_expect(source.contains("SORTIE_BAY_BACKDROP") and source.contains("sortie_bay_backdrop_v1.png"), "sortie console should use the authored maintenance-bay environment")
		var backdrop := load("res://assets/runtime/ui/menu/sortie_bay_backdrop_v1.png")
		_expect(backdrop is Texture2D and backdrop.get_size() == Vector2(640,360), "sortie-bay backdrop should retain canonical 640x360 geometry")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/menu_ui_asset_manifest.json"), "sortie-menu art manifest should exist")
		for menu_path in ["operations_panel_9slice.png", "operations_screen_9slice.png", "operations_button_9slice.png"]:
			var menu_texture := load("res://assets/runtime/ui/menu/%s" % menu_path)
			_expect(menu_texture is Texture2D, "missing authored menu interface sprite: %s" % menu_path)
		_expect(source.contains("UiSpriteRenderer.draw_nine_slice") and source.contains("OPERATIONS_PANEL") and source.contains("OPERATIONS_SCREEN") and source.contains("OPERATIONS_BUTTON"), "sortie console should assemble authored sprite frames instead of flat rectangle chrome")
		var chrome_sizes := {"panel_header_rule":Vector2(16,3), "panel_status_lamp":Vector2(8,8), "report_divider":Vector2(556,5)}
		for asset_name in chrome_sizes:
			var chrome_texture := load("res://assets/runtime/ui/menu/%s.png" % asset_name)
			_expect(chrome_texture is Texture2D and chrome_texture.get_size() == chrome_sizes[asset_name], "operations-console chrome should retain registered geometry: %s" % asset_name)
		_expect(source.contains("PANEL_HEADER_RULE") and source.contains("PANEL_STATUS_LAMP") and source.contains("REPORT_DIVIDER") and source.contains("draw_three_slice_horizontal"), "sortie and report screens should use authored panel chrome sprites")
		var report_sizes := {
			"badge_c": Vector2(80,72), "badge_b": Vector2(80,72), "badge_a": Vector2(80,72), "badge_s": Vector2(80,72), "badge_failure": Vector2(80,72),
			"stat_frame": Vector2(192,52), "accuracy_trough": Vector2(360,14), "accuracy_fill": Vector2(352,6),
		}
		for asset_name in report_sizes:
			var report_texture := load("res://assets/runtime/ui/menu/mission_report/%s.png" % asset_name)
			_expect(report_texture is Texture2D and report_texture.get_size() == report_sizes[asset_name], "mission-report sprite should retain registered geometry: %s" % asset_name)
		_expect(source.contains("REPORT_BADGES") and source.contains("REPORT_FAILURE_BADGE") and source.contains("REPORT_STAT_FRAME") and source.contains("REPORT_ACCURACY_TROUGH") and source.contains("REPORT_ACCURACY_FILL"), "mission report should use authored qualification, failure and instrumentation sprites")
		_expect(source.contains("REPORT_METRIC_CELL") and source.contains("REPORT_METRIC_ICONS") and source.contains("func _draw_report_metric") and source.contains("func _objective_report"), "mission report should expose sprite-backed sortie telemetry and objective completion")
		var metric_sizes := {"cell":Vector2(128,26), "icon_targets":Vector2(12,12), "icon_damage":Vector2(12,12), "icon_secret":Vector2(12,12), "icon_repair":Vector2(12,12)}
		for asset_name in metric_sizes:
			var metric_texture := load("res://assets/runtime/ui/menu/mission_report/metrics/%s.png" % asset_name)
			_expect(metric_texture is Texture2D and metric_texture.get_size() == metric_sizes[asset_name], "mission-report metric sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/mission_report_metrics_manifest.json"), "mission-report metric source/runtime manifest should exist")
		_expect(source.contains("SORTIE FAILURE") and source.contains("AIRFRAME RECOVERY REQUIRED") and source.contains("ENTER / R RETRY SORTIE"), "failed sorties should use an explicit recovery dossier instead of a success qualification")
		_expect(source.contains("func _sortie_grade") and source.contains('accuracy >= 90') and source.contains('accuracy >= 75') and source.contains('accuracy >= 55'), "mission report should derive its visible strike rating from sortie accuracy")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/mission_report_manifest.json"), "mission-report source/runtime manifest should exist")
		_expect(not source.contains("draw_line") and not source.contains("rect.grow(-8)"), "primary pixel UI must not regress to primitive panel rules or outline furniture")
		_expect(source.contains("AUTHORIZE LAUNCH"), "sortie console should retain a distinct launch control")
		_expect(PixelFont.GLYPHS.has(">") and PixelFont.GLYPHS.has("<"), "pixel console font should render action chevrons instead of question-mark fallbacks")
		_expect(source.contains("func _draw_console_panel"), "sortie console should retain its late-90s panel hierarchy")
		_expect(source.contains("func _draw_boss"), "pixel UI should own boss HUD")
		_expect(source.contains('var cue := " WEAK" if phase >= 3'), "phase-three boss HUD should retain weak-point cue")
		_expect(source.contains("ThreatWarningRules.warning_text"), "pixel UI should own missile warning")
		_expect(source.contains("HUD_TOP_FRAME") and source.contains("HUD_METER_TROUGH") and source.contains("HUD_BOSS_FRAME") and source.contains("HUD_THREAT_FRAME"), "gameplay HUD should use authored raster frame and meter families")
		for hud_path in ["top_frame.png", "meter_trough.png", "hull_fill.png", "shield_fill.png", "energy_fill.png", "status_frame.png", "boss_frame.png", "boss_trough.png", "boss_fill.png", "threat_frame.png", "icon_bomb.png", "icon_wave.png", "icon_time.png", "icon_score.png", "afterburner_frame.png", "afterburner_trough.png", "afterburner_fill.png", "stability_trough.png", "stability_fill.png"]:
			_expect(FileAccess.file_exists("res://assets/runtime/ui/hud/%s" % hud_path), "missing authored HUD sprite: %s" % hud_path)
		_expect(source.contains("FLIGHT_STATE_FRAME") and source.contains("ALTITUDE_STATES") and source.contains("FORM_STATES") and source.contains("TECH_STATES") and source.contains("func _draw_flight_state"), "flight state should use authored altitude, geometry and technology sprites")
		var flight_state_sizes := {
			"frame": Vector2(148,16), "altitude_rail": Vector2(24,12),
			"altitude_low": Vector2(24,12), "altitude_mid": Vector2(24,12), "altitude_high": Vector2(24,12), "altitude_orbital": Vector2(24,12),
			"form_fighter": Vector2(24,12), "form_bomber": Vector2(24,12),
			"tech_conventional": Vector2(24,12), "tech_em": Vector2(24,12), "tech_directed": Vector2(24,12), "tech_orbital": Vector2(24,12),
		}
		for asset_name in flight_state_sizes:
			var state_texture := load("res://assets/runtime/ui/hud/flight_state/%s.png" % asset_name)
			_expect(state_texture is Texture2D and state_texture.get_size() == flight_state_sizes[asset_name], "flight-state sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/flight_state_manifest.json"), "flight-state source/runtime manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/ui/hud_asset_manifest.json"), "gameplay HUD production manifest should exist")
		_expect(source.contains("MISSION_INGRESS_FRAME") and source.contains("OBJECTIVE_REQUIRED") and source.contains("OBJECTIVE_BONUS") and source.contains("INGRESS_SECONDS") and source.contains("func _draw_mission_ingress"), "mission launch should use the timed authored ingress-card family")
		var ingress_sizes := {"frame":Vector2(408,46), "objective_required":Vector2(12,12), "objective_bonus":Vector2(12,12)}
		for asset_name in ingress_sizes:
			var ingress_texture := load("res://assets/runtime/ui/hud/mission_ingress/%s.png" % asset_name)
			_expect(ingress_texture is Texture2D and ingress_texture.get_size() == ingress_sizes[asset_name], "mission-ingress sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/mission_ingress_manifest.json"), "mission-ingress source/runtime manifest should exist")
		_expect(source.contains("OBJECTIVE_TRACKER_FRAME") and source.contains("func _draw_objective_tracker") and source.contains("func _tracked_objective") and source.contains("ObjectiveRules.is_complete"), "live sorties should retain a sprite-backed tracker that advances across incomplete required and bonus objectives")
		var tracker_sizes := {"frame":Vector2(360,28), "trough":Vector2(332,5), "required_fill":Vector2(330,3), "bonus_fill":Vector2(330,3)}
		for asset_name in tracker_sizes:
			var tracker_texture := load("res://assets/runtime/ui/hud/objective_tracker/%s.png" % asset_name)
			_expect(tracker_texture is Texture2D and tracker_texture.get_size() == tracker_sizes[asset_name], "objective-tracker sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/objective_tracker_manifest.json"), "objective-tracker source/runtime manifest should exist")
		_expect(source.contains("SECRET_DISCOVERY_FRAME") and source.contains("SECRET_DISCOVERY_FX") and source.contains("func _draw_secret_discovery") and source.contains('status.begins_with("SECRET - ")'), "mastery secrets should use a distinct sprite-animated encrypted-vector panel")
		var secret_sizes := {"frame":Vector2(400,52), "fx_0":Vector2(400,52), "fx_1":Vector2(400,52), "fx_2":Vector2(400,52), "fx_3":Vector2(400,52)}
		for asset_name in secret_sizes:
			var secret_texture := load("res://assets/runtime/ui/hud/secret_discovery/%s.png" % asset_name)
			_expect(secret_texture is Texture2D and secret_texture.get_size() == secret_sizes[asset_name], "secret-discovery sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/secret_discovery_manifest.json"), "secret-discovery source/runtime manifest should exist")
		_expect(not source.contains("PanelContainer.new()") and not source.contains("Label.new()") and not source.contains("ProgressBar.new()"), "primary pixel HUD must not use modern widget chrome")
	var intel_file := FileAccess.open("res://scripts/mission_intel_director.gd", FileAccess.READ)
	_expect(intel_file != null and intel_file.get_as_text().contains("layer = 31"), "mission intelligence overlay should render above the layer-30 sortie console")
	_expect(intel_file != null and intel_file.get_as_text().contains("UiSpriteRenderer.draw_nine_slice"), "mission intelligence overlay should use authored operations-console sprites")
	if intel_file != null:
		var intel_source := intel_file.get_as_text()
		_expect(intel_source.contains("INTEL_ROW_FRAME") and intel_source.contains("INTEL_ICONS") and intel_source.contains("INTEL_READY_LAMP"), "mission intelligence should assemble the authored tactical-dossier sprite family")
		_expect(intel_source.contains("DOSSIER COMPLETE") and intel_source.contains("_row_color"), "mission intelligence should expose readiness and category hierarchy")
		_expect(intel_source.contains("_sortie_front_end(scene)"), "mission intelligence hotkey should remain hidden outside sortie operations")
	var intel_sizes := {
		"icon_threat":Vector2(16,16), "icon_envelope":Vector2(16,16), "icon_profile":Vector2(16,16), "icon_lanes":Vector2(16,16),
		"icon_routes":Vector2(16,16), "icon_boss":Vector2(16,16), "icon_allied":Vector2(16,16), "icon_advice":Vector2(16,16),
		"row_frame":Vector2(480,20), "ready_lamp":Vector2(12,12),
	}
	for asset_name in intel_sizes:
		var intel_texture := load("res://assets/runtime/ui/menu/mission_intel/%s.png" % asset_name)
		_expect(intel_texture is Texture2D and intel_texture.get_size() == intel_sizes[asset_name], "mission-intelligence sprite should retain registered geometry: %s" % asset_name)
	_expect(FileAccess.file_exists("res://assets/source/ui/menu/mission_intel_manifest.json"), "mission-intelligence source/runtime manifest should exist")
	var stores_file := FileAccess.open("res://scripts/loadout_schematic_director.gd", FileAccess.READ)
	_expect(stores_file != null and stores_file.get_as_text().contains("layer = 32"), "stores schematic should render above the sortie console and mission intelligence")
	_expect(stores_file != null and stores_file.get_as_text().contains("UiSpriteRenderer.draw_nine_slice"), "stores schematic should use authored operations-console sprites")
	_expect(stores_file != null and stores_file.get_as_text().contains("_sortie_front_end(scene)"), "stores hotkey should remain hidden outside sortie operations")
	_expect(not FileAccess.file_exists("res://scripts/boss_hud_director.gd"), "obsolete boss HUD widget director should remain deleted")
	_expect(not FileAccess.file_exists("res://scripts/threat_warning_director.gd"), "obsolete threat widget director should remain deleted")
	var main_ui_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_ui_file != null and not main_ui_file.get_as_text().contains("draw_string("), "main simulation scene must not retain a hidden default-font duplicate UI")
	if main_ui_file != null:
		var main_ui_source := main_ui_file.get_as_text()
		_expect(main_ui_source.contains('get_node_or_null("/root/PauseDirector")'), "gameplay cancel should route through the tactical pause controller")
		for telemetry_token in ["targets_destroyed += 1", "damage_taken +=", "mission_reward_earned = total_reward", "repair_cost = ServiceRules.service_cost"]:
			_expect(main_ui_source.contains(telemetry_token), "sortie report telemetry should remain bound to authoritative runtime events: %s" % telemetry_token)
	var pause_file := FileAccess.open("res://scripts/pause_director.gd", FileAccess.READ)
	_expect(pause_file != null, "pause director should exist")
	if pause_file != null:
		var pause_source := pause_file.get_as_text()
		for token in ["PROCESS_MODE_ALWAYS", "get_tree().paused = true", "resume_game", "restart_sortie", "HYPERSONIC_WORDMARK", "VX94_FIGHTER", "CONTROL_ROW", "CONTROL_ICONS", "OPERATIONS_SCREEN", "OPERATIONS_BUTTON"]:
			_expect(pause_source.contains(token), "tactical pause presentation missing token: %s" % token)
		_expect(not pause_source.contains("Label.new()") and not pause_source.contains("Button.new()") and not pause_source.contains("PanelContainer.new()"), "tactical pause must stay inside the authored pixel-console sprite language")
	var project_file := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project_file != null and project_file.get_as_text().contains('PauseDirector="*res://scripts/pause_director.gd"'), "pause controller should remain an always-available autoload")

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
	_expect(source.contains("PICKUP_ANIMATION_FRAMES") and source.contains("_draw_pickups"), "combat art should own animated recovery-pod presentation")
	for pickup_kind in ["shield", "repair", "bomb", "weapon"]:
		for frame_index in range(4):
			_expect(FileAccess.file_exists("res://assets/runtime/effects/pickups/%s_%d.png" % [pickup_kind, frame_index]), "missing authored pickup frame %s %d" % [pickup_kind, frame_index])
	_expect(FileAccess.file_exists("res://assets/source/effects/pickups/pickup_asset_manifest.json"), "pickup production manifest should exist")
	var main_art_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_art_file != null and not main_art_file.get_as_text().contains('draw_rect(Rect2(q.x - 5, q.y - 5, 10, 10)'), "main simulation scene must not retain generic pickup-square presentation")
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
