extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const MissionFlowRules = preload("res://scripts/mission_flow_rules.gd")
const ObjectiveRules = preload("res://scripts/objective_rules.gd")
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
	_expect(is_equal_approx(MissionFlowRules.boss_victory_hold_seconds("m01_coastal_intercept", "gunship_alpha"), 2.55), "Coastal Intercept should hold through Gunship Alpha's complete physical breakup")
	_expect(is_equal_approx(MissionFlowRules.COASTAL_EGRESS_CLEAR_SECONDS, 1.35), "successful extraction should retain a visible breakaway beat before debrief")
	_expect(MissionFlowRules.boss_victory_hold_seconds("m02_refinery_run", "armoured_train") == 0.0, "unreviewed mission endings should retain their authored objective flow")
	_expect(MissionFlowRules.requires_hypersonic_egress("m01_coastal_intercept"), "Coastal Intercept should end with the signature hypersonic extraction")
	_expect(not MissionFlowRules.requires_hypersonic_egress("m02_refinery_run"), "later missions should retain their authored endings until individually reviewed")
	_expect(MissionFlowRules.egress_altitude_ready("high") and MissionFlowRules.egress_altitude_ready("orbital"), "high and orbital bands should open the safe egress corridor")
	_expect(not MissionFlowRules.egress_altitude_ready("low") and not MissionFlowRules.egress_altitude_ready("mid"), "low and mid altitude should remain unsafe for command egress")
	_expect(is_equal_approx(MissionFlowRules.advance_egress_lock(0.4, 0.2, "high", true), 0.6), "stable high-altitude hypersonic flight should build egress lock")
	_expect(is_equal_approx(MissionFlowRules.advance_egress_lock(0.4, 0.2, "mid", true), 0.1), "dropping below the safe band should rapidly bleed egress lock")
	var survival_objectives := [{"id":"survive","type":"survive","seconds":150,"required":true}]
	var survival_progress := {"survive":112.0}
	ObjectiveRules.complete_survival(survival_objectives, survival_progress)
	_expect(ObjectiveRules.required_complete(survival_objectives, survival_progress), "command victory should complete the displayed survival contract before the report")
	ObjectiveRules.update_survival(survival_objectives, survival_progress, 113.0)
	_expect(ObjectiveRules.required_complete(survival_objectives, survival_progress), "a completed survival contract must remain monotonic during post-command extraction")
	var egress_objectives := [{"id":"egress","type":"hypersonic_egress","seconds":1.25,"required":true}]
	var egress_progress := ObjectiveRules.make_progress(egress_objectives)
	ObjectiveRules.update_hypersonic_egress(egress_objectives, egress_progress, 0.625)
	_expect(not ObjectiveRules.required_complete(egress_objectives, egress_progress), "partial Mach corridor lock must not complete extraction")
	_expect(ObjectiveRules.progress_text(egress_objectives[0], egress_progress) == "50%", "egress objective should communicate a compact lock percentage")
	ObjectiveRules.update_hypersonic_egress(egress_objectives, egress_progress, 1.25)
	_expect(ObjectiveRules.required_complete(egress_objectives, egress_progress), "full Mach corridor lock should complete extraction")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable for bounded overtime checks")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("BOSS_OVERTIME_LIMIT_SECONDS := 45.0"), "boss overtime should retain hard cap")
		_expect(source.contains("MissionFlowRules.should_hold_overtime"), "main should evaluate boss overtime directly")
		_expect(source.contains("BOSS OVERTIME EXPIRED"), "expired overtime should fail explicitly")
		_expect(source.contains("_capture_mission_index"), "visual QA should be able to launch any authored mission deterministically")
		_expect(source.contains("boss_victory_timer") and source.contains("_begin_boss_victory_hold(destroyed)") and source.contains("ObjectiveRules.complete_survival"), "Mission 1 command kill should retain the breakup before transitioning to a fully completed report")
		_expect(source.contains("_begin_hypersonic_egress") and source.contains("_update_hypersonic_egress"), "Mission 1 command kill should hand control back for a playable hypersonic extraction")
		_expect(source.contains('"--capture-egress" in OS.get_cmdline_user_args()'), "visual QA should expose the playable post-command extraction state")
		_expect(source.contains('"--capture-egress-complete" in OS.get_cmdline_user_args()'), "visual QA should expose the successful Mach-corridor breakaway state")
		_expect(source.contains("egress_completion_timer") and source.contains("player_position.y - delta * 72.0"), "successful extraction should show the VX-94 climbing clear before debrief")
		_expect(source.contains('argument.begins_with("--capture-mission=")'), "mission capture selector should remain command-line isolated")
		_expect(source.contains('argument.begins_with("--capture-result=")') and source.contains("_begin_capture_result"), "mission report visual QA should expose deterministic success and failure fixtures")
		_expect(source.contains('argument.begins_with("--capture-time=")') and source.contains("_begin_capture_gameplay"), "representative mission visual QA should support a bounded mid-mission clock")
		_expect(source.contains('get("ingress_seconds", 0.35)') and source.contains("enemy_spawn_timer = maxf"), "authored mission ingress should suppress unscripted contact without delaying route-positioned encounter beats")
		_expect(source.contains("_random_contact_interval_scale()") and source.contains('get("random_contact_interval_scale", 1.0)'), "mission pacing should support bounded unscripted-contact cadence without altering authored encounter packets")
		_expect(source.contains("_mission_enemy_fire_interval_scale()") and source.contains('get("enemy_fire_interval_scale", 1.0)'), "missions should support bounded hostile volley cadence without weakening authored projectile damage")
	var ui_file := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(ui_file != null and ui_file.get_as_text().contains('scene.get("egress_time_remaining")'), "combat chronometer should change from route time to the live extraction window")
	_expect(ui_file != null and ui_file.get_as_text().contains('scene.get("egress_active")'), "urgent extraction guidance should override stale routine radio occupancy")
	_expect(ui_file != null and ui_file.get_as_text().contains('scene.get("egress_completion_timer")'), "successful extraction confirmation should override stale routine radio occupancy")
	_expect(ui_file != null and ui_file.get_as_text().contains("Rect2(412, 82, 80, 90)"), "sortie inspection panel should present the VX-94 at reviewed hero scale")
	var encounter_file := FileAccess.open("res://scripts/encounter_director.gd", FileAccess.READ)
	_expect(encounter_file != null and encounter_file.get_as_text().contains('scene.get("egress_active")'), "delayed encounter beats must not repopulate the cleared extraction corridor")
	var radio_file := FileAccess.open("res://scripts/mission_radio_director.gd", FileAccess.READ)
	_expect(radio_file != null and radio_file.get_as_text().contains("MACH CORRIDOR OPEN. STRIKE PACKAGE CLEAR."), "successful extraction should replace stale radio traffic with an explicit clear call")
	var missions = ContentCatalog.load_json("res://data/missions.json")
	if typeof(missions) == TYPE_DICTIONARY and not missions.get("missions", []).is_empty():
		var first: Dictionary = missions.get("missions", [])[0]
		_expect(float(first.get("ingress_seconds", 0.0)) >= float(first.get("encounter_beats", [])[0].get("at_seconds", 0.0)), "Coastal Intercept should establish the theatre before random contacts can pre-empt its scout screen")
		_expect(float(first.get("random_contact_interval_scale", 1.0)) >= 1.5, "Coastal Intercept should privilege authored formations over arcade-like background spawn churn")
		_expect(float(first.get("enemy_fire_interval_scale", 1.0)) >= 1.15, "Coastal Intercept should leave a readable novice response window between intact enemy volleys")
		var first_objectives: Array = first.get("objectives", [])
		_expect(first_objectives.any(func(objective: Dictionary) -> bool: return str(objective.get("type", "")) == "hypersonic_egress" and bool(objective.get("required", false))), "Coastal Intercept should author the extraction as a required HUD-visible objective")
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
		_expect(text.contains("ProjectileRules.pickup_kind_for_roll(_difficulty_pickup_roll(mission_rng.randf()))"), "pickup rolls should remain mission-RNG deterministic while respecting difficulty generosity")
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
		_expect(source.contains("func _draw_front_end_command_context") and source.contains("COMBAT ROUTES") and source.contains("TERMINATE SESSION"), "main-menu selections should own responsive command context instead of a static campaign card")
		_expect(source.contains('_identity_text("version"') and source.contains('_identity_text("developer"'), "front-end version and studio credit should remain centralized through ProductIdentity")
		for front_end_asset in ["frame.png", "button_idle.png", "button_selected.png", "cursor.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/menu/front_end/%s" % front_end_asset), "front-end menu sprite should exist: %s" % front_end_asset)
		_expect(source.contains("func _draw_support_links"), "support readiness instrumentation should remain available without permanently crowding the combat field")
		_expect(source.contains('argument.begins_with("--capture-hud=")') and source.contains('["objective", "ingress", "acquisition", "warning", "boss"]'), "visual QA should expose deterministic ingress, objective, acquisition, warning and boss HUD fixtures without mutating simulation")
		_expect(source.contains('_capture_time() > INGRESS_SECONDS') and source.contains('capture_state == "ingress"'), "representative gameplay captures should suppress the launch transient unless ingress is explicitly requested")
		_expect(source.contains('if _capture_hud_state() == "boss"') and source.contains('if _capture_hud_state() == "warning"'), "critical HUD capture fixtures should provide deterministic boss and missile-lock presentation data")
		_expect(source.contains("battlefield sprites must never show through") and source.contains("Rect2(8, 5, 624, 30)"), "permanent HUD fascia should occlude actors until they enter the combat viewport")
		_expect(source.contains("_altitude_choice_active(scene)") and source.contains("occupies_status_lane") and source.contains("AltitudeTransitionDirector"), "only a visible altitude selector or transition should suppress colliding routine status notices")
		_expect(source.contains("_radio_occupies_status_lane()") and source.contains("MissionRadioDirector"), "radio subtitles and transient status should arbitrate one shared lower information lane instead of overprinting")
		_expect(FileAccess.file_exists("res://tools/build_hud_threat_art.ps1"), "threat-annunciator sprites should remain reproducible from their governed SVG source")
		var threat_lock := load("res://assets/runtime/ui/hud/threat_annunciator/lock.png") as Texture2D
		_expect(threat_lock != null and threat_lock.get_image().get_pixel(100,10).a > 0.9, "threat annunciator must retain its smoked backing over detailed terrain")
		for support_link_asset in ["trough.png", "tactical_fill.png", "battlefield_fill.png", "ready.png", "charging.png", "unavailable.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/hud/support_link/%s" % support_link_asset), "support readiness sprite should exist: %s" % support_link_asset)
		_expect(source.contains("MERCENARY WAR") and source.contains("MACHINE WAR") and source.contains("BLACK SKY"), "sortie console should preserve the three canonical campaign sectors")
		for path in ["rail.png", "node_complete.png", "node_current.png", "node_locked.png"]:
			_expect(ResourceLoader.exists("res://assets/runtime/ui/menu/campaign_progress/%s" % path), "campaign progress sprite should exist: %s" % path)
		_expect(source.contains("VX94_FIGHTER") and source.contains("VX94_BOMBER"), "sortie console should retain form-specific aircraft art")
		_expect(source.contains("SORTIE_BAY_BACKDROP") and source.contains("maintenance_bay_v2.png") and source.contains("MAINTENANCE_BAY_ACTIVITY"), "front-end console should use the animated authored maintenance-bay environment")
		var backdrop := load("res://assets/runtime/ui/menu/maintenance_bay_v2.png")
		_expect(backdrop is Texture2D and backdrop.get_size() == Vector2(640,360), "sortie-bay backdrop should retain canonical 640x360 geometry")
		for activity_index in range(4):
			var activity := load("res://assets/runtime/ui/menu/maintenance_bay_activity/activity_%d.png" % activity_index)
			_expect(activity is Texture2D and activity.get_size() == Vector2(640,360) and activity.get_image().detect_alpha() != Image.ALPHA_NONE, "maintenance-bay activity frame should retain transparent registered geometry: %d" % activity_index)
		_expect(source.contains("func _draw_maintenance_bay") and source.contains("_front_end_time * 3.0"), "front-end, sortie and report screens should share held practical-light animation")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/maintenance_bay_v2_manifest.json") and FileAccess.file_exists("res://tools/build_menu_bay_v2.ps1"), "maintenance-bay v2 should retain governed source and deterministic builder")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/menu_ui_asset_manifest.json"), "sortie-menu art manifest should exist")
		for menu_path in ["operations_panel_9slice.png", "operations_screen_9slice.png", "operations_button_9slice.png"]:
			var menu_texture := load("res://assets/runtime/ui/menu/%s" % menu_path)
			_expect(menu_texture is Texture2D, "missing authored menu interface sprite: %s" % menu_path)
		var operations_screen_texture := load("res://assets/runtime/ui/menu/operations_screen_9slice.png") as Texture2D
		var operations_screen_alpha := operations_screen_texture.get_image().get_pixel(16,16).a if operations_screen_texture != null else 1.0
		_expect(operations_screen_alpha >= 0.45 and operations_screen_alpha <= 0.85, "outer operations console should retain a controlled smoked center rather than flattening the maintenance bay")
		_expect(source.contains("UiSpriteRenderer.draw_nine_slice") and source.contains("OPERATIONS_PANEL") and source.contains("OPERATIONS_SCREEN") and source.contains("OPERATIONS_BUTTON"), "sortie console should assemble authored sprite frames instead of flat rectangle chrome")
		var chrome_sizes := {"panel_header_rule":Vector2(16,3), "panel_status_lamp":Vector2(8,8), "report_divider":Vector2(556,5)}
		for asset_name in chrome_sizes:
			var chrome_texture := load("res://assets/runtime/ui/menu/%s.png" % asset_name)
			_expect(chrome_texture is Texture2D and chrome_texture.get_size() == chrome_sizes[asset_name], "operations-console chrome should retain registered geometry: %s" % asset_name)
		_expect(source.contains("PANEL_HEADER_RULE") and source.contains("PANEL_STATUS_LAMP") and source.contains("REPORT_DIVIDER") and source.contains("draw_three_slice_horizontal"), "sortie and report screens should use authored panel chrome sprites")
		var report_sizes := {
			"badge_c": Vector2(80,72), "badge_b": Vector2(80,72), "badge_a": Vector2(80,72), "badge_s": Vector2(80,72), "badge_failure": Vector2(80,72),
			"stat_frame": Vector2(192,52), "accuracy_trough": Vector2(360,14), "accuracy_fill": Vector2(352,6),
			"flight_recorder_complete": Vector2(556,18), "flight_recorder_lost": Vector2(556,18),
		}
		for asset_name in report_sizes:
			var report_texture := load("res://assets/runtime/ui/menu/mission_report/%s.png" % asset_name)
			_expect(report_texture is Texture2D and report_texture.get_size() == report_sizes[asset_name], "mission-report sprite should retain registered geometry: %s" % asset_name)
		_expect(source.contains("REPORT_BADGES") and source.contains("REPORT_FAILURE_BADGE") and source.contains("REPORT_STAT_FRAME") and source.contains("REPORT_ACCURACY_TROUGH") and source.contains("REPORT_ACCURACY_FILL"), "mission report should use authored qualification, failure and instrumentation sprites")
		_expect(source.contains("REPORT_FLIGHT_RECORDER_COMPLETE") and source.contains("REPORT_FLIGHT_RECORDER_LOST"), "mission report should distinguish completed and interrupted flight-recorder tracks")
		_expect(source.contains("REPORT_METRIC_CELL") and source.contains("REPORT_METRIC_ICONS") and source.contains("func _draw_report_metric") and source.contains("func _objective_report"), "mission report should expose sprite-backed sortie telemetry and objective completion")
		var metric_sizes := {"cell":Vector2(128,26), "icon_targets":Vector2(12,12), "icon_damage":Vector2(12,12), "icon_secret":Vector2(12,12), "icon_repair":Vector2(12,12)}
		for asset_name in metric_sizes:
			var metric_texture := load("res://assets/runtime/ui/menu/mission_report/metrics/%s.png" % asset_name)
			_expect(metric_texture is Texture2D and metric_texture.get_size() == metric_sizes[asset_name], "mission-report metric sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/mission_report_metrics_manifest.json"), "mission-report metric source/runtime manifest should exist")
		_expect(source.contains("MISSION COMPLETE") and source.contains("SORTIE FAILED"), "campaign reports should announce their outcome in the primary headline")
		_expect(source.contains("AIRFRAME RECOVERY REQUIRED") and source.contains("ENTER / R RETRY SORTIE"), "failed sorties should use an explicit recovery dossier instead of a success qualification")
		_expect(source.contains("func _sortie_grade") and source.contains('accuracy >= 90') and source.contains('accuracy >= 75') and source.contains('accuracy >= 55'), "mission report should derive its visible strike rating from sortie accuracy")
		_expect(FileAccess.file_exists("res://assets/source/ui/menu/mission_report_manifest.json"), "mission-report source/runtime manifest should exist")
		_expect(not source.contains("draw_line") and not source.contains("rect.grow(-8)"), "primary pixel UI must not regress to primitive panel rules or outline furniture")
		_expect(source.contains("AUTHORIZE LAUNCH"), "sortie console should retain a distinct launch control")
		_expect(PixelFont.GLYPHS.has(">") and PixelFont.GLYPHS.has("<"), "pixel console font should render action chevrons instead of question-mark fallbacks")
		_expect(source.contains("func _draw_console_panel"), "sortie console should retain its late-90s panel hierarchy")
		_expect(source.contains("func _draw_boss"), "pixel UI should own boss HUD")
		_expect(source.contains("active_support_id") and source.contains('"atlas_tanker"'), "objective tracker should yield visual priority during the authored tanker docking set piece")
		_expect(source.contains('var cue := " WEAK" if phase >= 3'), "phase-three boss HUD should retain weak-point cue")
		_expect(source.contains("ThreatWarningRules.warning_text"), "pixel UI should own missile warning")
		_expect(source.contains("HUD_TOP_FRAME") and source.contains("HUD_METER_TROUGH") and source.contains("HUD_BOSS_FRAME") and source.contains("HUD_THREAT_FRAMES"), "gameplay HUD should use authored raster frame and meter families")
		for hud_path in ["top_frame.png", "meter_trough.png", "hull_fill.png", "shield_fill.png", "energy_fill.png", "status_frame.png", "boss_frame.png", "boss_trough.png", "boss_fill.png", "threat_frame.png", "icon_bomb.png", "icon_wave.png", "icon_time.png", "icon_score.png", "afterburner_frame.png", "afterburner_trough.png", "afterburner_fill.png", "stability_trough.png", "stability_fill.png"]:
			_expect(FileAccess.file_exists("res://assets/runtime/ui/hud/%s" % hud_path), "missing authored HUD sprite: %s" % hud_path)
		for primary_meter in ["hull_frame", "shield_frame", "energy_frame", "hull_warning_frame", "shield_warning_frame", "energy_warning_frame"]:
			var meter_texture := load("res://assets/runtime/ui/hud/primary_meter_cluster/%s.png" % primary_meter)
			_expect(meter_texture is Texture2D and meter_texture.get_size() == Vector2(92,25), "primary meter instrument should retain registered geometry: %s" % primary_meter)
		_expect(FileAccess.file_exists("res://tools/build_primary_meter_art.ps1"), "primary meter sprites should remain reproducible from their governed SVG source")
		_expect(source.contains("_draw_primary_meter") and source.contains("HUD_HULL_WARNING_FRAME") and source.contains("HUD_SHIELD_WARNING_FRAME") and source.contains("HUD_ENERGY_WARNING_FRAME"), "hull, shield and generator should use distinct sprite instruments with live warning states")
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
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/top_avionics_fascia_manifest.json"), "top avionics fascia source/runtime manifest should exist")
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/boss_phase_bar_manifest.json"), "boss phase threat-bar source/runtime manifest should exist")
		var threat_sizes := {"tracking":Vector2(280,22), "caution":Vector2(280,22), "lock":Vector2(280,22), "approach_trough":Vector2(82,5), "caution_fill":Vector2(80,3), "lock_fill":Vector2(80,3), "missile_icon":Vector2(12,12)}
		for threat_asset in threat_sizes:
			var threat_texture := load("res://assets/runtime/ui/hud/threat_annunciator/%s.png" % threat_asset)
			_expect(threat_texture is Texture2D and threat_texture.get_size() == threat_sizes[threat_asset], "radar-warning receiver sprite should retain registered geometry: %s" % threat_asset)
		_expect(source.contains("HUD_THREAT_APPROACH_TROUGH") and source.contains("ThreatWarningRules.warning_level") and source.contains("approach_ratio"), "missile annunciator should expose warning state and closure distance through authored instruments")
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/threat_annunciator_manifest.json"), "radar-warning receiver source/runtime manifest should exist")
		for bearing_index in range(12):
			var bearing_texture := load("res://assets/runtime/ui/hud/rwr_aircraft_cues/bearing_%02d.png" % bearing_index)
			_expect(bearing_texture is Texture2D and bearing_texture.get_size() == Vector2(16,16), "aircraft-local RWR bearing sprite should retain registered geometry: %02d" % bearing_index)
		for cue_name in ["spike", "hard_lock", "missile_inbound"]:
			var cue_texture := load("res://assets/runtime/ui/hud/rwr_aircraft_cues/%s.png" % cue_name)
			_expect(cue_texture is Texture2D and cue_texture.get_size() == Vector2(28,28), "aircraft-local RWR state sprite should retain registered geometry: %s" % cue_name)
		_expect(source.contains("func _draw_aircraft_rwr_cue") and source.contains("HUD_RWR_BEARINGS") and source.contains("HUD_RWR_MISSILE_INBOUND"), "missile warnings should place authored clock-bearing and lock-state cues around the aircraft")
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/rwr_aircraft_cue_manifest.json") and FileAccess.file_exists("res://tools/build_rwr_aircraft_cues.ps1"), "aircraft-local RWR cues should retain governed source and deterministic builder")
		for boss_phase in ["phase_1","phase_2","phase_3"]:
			var boss_phase_frame := load("res://assets/runtime/ui/hud/boss_phase_bar/%s.png" % boss_phase)
			var boss_phase_fill := load("res://assets/runtime/ui/hud/boss_phase_bar/%s_fill.png" % boss_phase)
			_expect(boss_phase_frame is Texture2D and boss_phase_frame.get_size() == Vector2(388,28), "boss phase frame should retain exact HUD geometry: %s" % boss_phase)
			_expect(boss_phase_fill is Texture2D and boss_phase_fill.get_size() == Vector2(352,5), "boss phase fill should retain exact HUD geometry: %s" % boss_phase)
		var top_fascia := load("res://assets/runtime/ui/hud/compact_combat_fascia.png")
		_expect(top_fascia is Texture2D and top_fascia.get_size() == Vector2(624,30), "compact avionics fascia should preserve a large clean combat field")
		var notification_frame := load("res://assets/runtime/ui/hud/compact_notification_frame.png")
		_expect(notification_frame is Texture2D and notification_frame.get_size() == Vector2(336,32), "shared notification lane should use compact registered geometry")
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/compact_combat_hud_manifest.json"), "compact combat HUD source/runtime manifest should exist")
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
		var secret_sizes := {"frame":Vector2(320,30), "fx_0":Vector2(320,30), "fx_1":Vector2(320,30), "fx_2":Vector2(320,30), "fx_3":Vector2(320,30)}
		for asset_name in secret_sizes:
			var secret_texture := load("res://assets/runtime/ui/hud/secret_discovery/%s.png" % asset_name)
			_expect(secret_texture is Texture2D and secret_texture.get_size() == secret_sizes[asset_name], "secret-discovery sprite should retain registered geometry: %s" % asset_name)
		_expect(FileAccess.file_exists("res://assets/source/ui/hud/secret_discovery_manifest.json"), "secret-discovery source/runtime manifest should exist")
		_expect(source.contains("var position := Vector2(160, 38)") and source.contains("VECTOR ACQUIRED"), "secret acquisition must stay in the compact top information lane instead of covering combat")
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
	_expect(stores_file != null and stores_file.get_as_text().contains("--capture-stores-schematic"), "visual QA should be able to capture the opened stores schematic deterministically")
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
		for token in ["PROCESS_MODE_ALWAYS", "get_tree().paused = true", "resume_game", "restart_sortie", "return_to_menu", "HYPERSONIC_WORDMARK", "VX94_FIGHTER", "COMMAND_LABELS", "COMMAND_ICONS", "WARNING_FRAME", "OPERATIONS_SCREEN", "_draw_options"]:
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
