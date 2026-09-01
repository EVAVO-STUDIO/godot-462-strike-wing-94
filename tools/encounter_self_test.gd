extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const EncounterRules = preload("res://scripts/encounter_rules.gd")
const InterceptRouteRules = preload("res://scripts/intercept_route_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	var data = ContentCatalog.load_json("res://data/missions.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "missions catalogue should load")
	if typeof(data) == TYPE_DICTIONARY:
		_expect(int(data.get("schema_version", 0)) >= 9, "mission schema should include altitude-route authoring")
		var enemy_data = ContentCatalog.load_json("res://data/enemies.json")
		var enemy_ids: Dictionary = {}
		if typeof(enemy_data) == TYPE_DICTIONARY:
			for enemy in enemy_data.get("enemies", []): enemy_ids[str(enemy.get("id", ""))] = true
		var route_ids := {"low_attack_window":false,"high_intercept_route":false,"low_bomber_route":false,"high_hunter_route":false}
		for mission in data.get("missions", []):
			var beats := EncounterRules.beats_for_mission(mission)
			_expect(beats.size() >= 5, "%s should contain at least five authored encounter beats" % str(mission.get("id", "mission")))
			_expect(EncounterRules.valid_schedule(beats, float(mission.get("duration_seconds", 1.0))), "%s encounter schedule should be ordered, unique and in-bounds" % str(mission.get("id", "mission")))
			var has_reward := false
			var has_quiet_window := false
			var has_secret := false
			var formations: Dictionary = {}
			for beat in beats:
				var beat_id := str(beat.get("id", ""))
				if route_ids.has(beat_id):
					route_ids[beat_id] = true
					_expect(EncounterRules.condition_type(beat) == "altitude_form", "%s should remain an altitude+form route bonus" % beat_id)
				var enemy_list := EncounterRules.expanded_enemy_ids(beat)
				for enemy_id in enemy_list: _expect(enemy_ids.has(enemy_id), "%s encounter references unknown enemy %s" % [str(mission.get("id", "mission")), enemy_id])
				formations[EncounterRules.formation(beat)] = true
				_expect(EncounterRules.formation_points(beat, enemy_list.size()).size() == enemy_list.size(), "%s encounter formation should provide one point per enemy" % str(mission.get("id", "mission")))
				if EncounterRules.reward_pickup(beat) != "": has_reward = true
				if EncounterRules.suppression_seconds(beat) >= 2.0: has_quiet_window = true
				if EncounterRules.is_secret(beat):
					has_secret = true
					_expect(EncounterRules.condition_type(beat) != "", "%s secret encounter should use supported condition" % str(mission.get("id", "mission")))
			_expect(has_reward, "%s should include an authored recovery/reward beat" % str(mission.get("id", "mission")))
			_expect(has_quiet_window, "%s should include an authored pacing window" % str(mission.get("id", "mission")))
			_expect(has_secret, "%s should include a replayable mastery secret" % str(mission.get("id", "mission")))
			_expect(formations.size() >= 3, "%s should use at least three formation shapes" % str(mission.get("id", "mission")))
		for route_id in route_ids.keys(): _expect(bool(route_ids[route_id]), "missing altitude-route bonus beat %s" % route_id)
	_test_rule_safety()
	_test_secret_conditions()
	_test_route_conditions()
	_test_intercept_chain()
	_test_formation_geometry()
	_test_route_runtime_wiring()
	if failures.is_empty():
		print("Strike Wing encounter self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_rule_safety() -> void:
	var beat := {"id":"pressure","at_seconds":12.0,"label":"Pressure Wave","enemies":[{"id":"scout_falcon","count":99}],"pickup":"not_real","suppress_random_seconds":99.0}
	_expect(EncounterRules.expanded_enemy_ids(beat).size() == EncounterRules.MAX_ENEMIES_PER_BEAT, "encounter enemy expansion should retain hard cap")
	_expect(EncounterRules.reward_pickup(beat) == "", "unknown encounter pickup should fail closed")
	_expect(EncounterRules.suppression_seconds(beat) == EncounterRules.MAX_SUPPRESSION_SECONDS, "encounter suppression should retain hard cap")

func _test_secret_conditions() -> void:
	var accuracy := {"secret":true,"condition":{"type":"accuracy_at_least","value":0.75,"minimum_shots":20}}
	_expect(not EncounterRules.condition_met(accuracy, {"shots_fired":1,"shots_hit":1}), "accuracy secret should require meaningful shot sample")
	_expect(EncounterRules.condition_met(accuracy, {"shots_fired":20,"shots_hit":15}), "accuracy secret should unlock at authored threshold")
	var score := {"secret":true,"condition":{"type":"score_at_least","value":5000}}
	_expect(EncounterRules.condition_met(score, {"score":5000}), "score secret should unlock at threshold")
	var bombs := {"secret":true,"condition":{"type":"bombs_at_least","value":2}}
	_expect(EncounterRules.condition_met(bombs, {"bombs":2}), "resource-conservation secret should unlock at threshold")

func _test_route_conditions() -> void:
	_expect("altitude_is" in EncounterRules.ALLOWED_CONDITIONS and "form_is" in EncounterRules.ALLOWED_CONDITIONS and "altitude_form" in EncounterRules.ALLOWED_CONDITIONS, "route condition grammar should remain explicit")
	var altitude := {"secret":true,"condition":{"type":"altitude_is","value":"high"}}
	_expect(EncounterRules.condition_met(altitude, {"altitude":"high","form":"fighter"}), "altitude route should unlock in matching lane")
	_expect(not EncounterRules.condition_met(altitude, {"altitude":"mid","form":"fighter"}), "altitude route should fail in different lane")
	var form := {"secret":true,"condition":{"type":"form_is","value":"bomber"}}
	_expect(EncounterRules.condition_met(form, {"altitude":"low","form":"bomber"}), "form route should unlock in matching configuration")
	var low_bomber := {"secret":true,"condition":{"type":"altitude_form","altitude":"low","form":"bomber"}}
	_expect(EncounterRules.condition_met(low_bomber, {"altitude":"low","form":"bomber"}), "combined route should require both lane and form")
	_expect(EncounterRules.is_low_bomber_route(low_bomber), "LOW+BMB route should be classified for bombing-computer priority")
	var high_fighter := {"secret":true,"condition":{"type":"altitude_form","altitude":"high","form":"fighter"}}
	_expect(EncounterRules.is_high_fighter_route(high_fighter), "HIGH+FTR route should be classified for interception priority")
	_expect(EncounterRules.HIGH_INTERCEPT_VALUE_BONUS > 0 and EncounterRules.HIGH_INTERCEPT_VALUE_BONUS <= 600, "high-route value bonus should stay bounded")
	_expect(not EncounterRules.condition_met({"condition":{"type":"altitude_is","value":"hyperspace"}}, {"altitude":"mid"}), "invalid altitude condition should fail closed")
	_expect(not EncounterRules.condition_met({"condition":{"type":"form_is","value":"mech"}}, {"form":"fighter"}), "invalid form condition should fail closed")

func _test_intercept_chain() -> void:
	_expect(InterceptRouteRules.CHAIN_SECONDS >= 1.5 and InterceptRouteRules.CHAIN_SECONDS <= 3.0, "intercept chain should be brief and arcade-readable")
	_expect(InterceptRouteRules.MAX_CHAIN <= 6, "intercept chain display must remain bounded")
	_expect(InterceptRouteRules.next_chain(0, 0.0, true) == 1, "first confirmed intercept should start chain")
	_expect(InterceptRouteRules.next_chain(2, 1.0, true) == 3, "rapid confirmed intercept should extend chain")
	_expect(InterceptRouteRules.next_chain(InterceptRouteRules.MAX_CHAIN, 1.0, true) == InterceptRouteRules.MAX_CHAIN, "chain should retain hard cap")
	_expect(InterceptRouteRules.likely_destroyed(Vector2(100,120), 900), "marked target disappearance with score gain inside playfield can count as presentation intercept")
	_expect(not InterceptRouteRules.likely_destroyed(Vector2(100,350), 900), "target leaving bottom of playfield must not count as intercept")
	_expect(not InterceptRouteRules.likely_destroyed(Vector2(100,120), 0), "disappearance without score gain must not count as intercept")

func _test_formation_geometry() -> void:
	for required in ["reverse_wedge", "echelon_left", "echelon_right", "pincer", "crossing_attack", "bomber_box", "escort_shell", "hunter_pair", "rotating_swarm", "missile_screen", "low_high_layer", "delayed_reinforcement", "pursuit", "retreat_bait", "ambush", "feint"]:
		_expect(required in EncounterRules.ALLOWED_FORMATIONS, "authored formation language missing %s" % required)
		_expect(EncounterRules.formation_points({"formation":required}, 8).size() == 8, "%s should provide one point per combatant" % required)
	var wedge := EncounterRules.formation_points({"formation":"wedge"}, 5)
	_expect(wedge.size() == 5 and absf(wedge[0].x - 0.5) < 0.001, "wedge should lead from centre lane")
	var split := EncounterRules.formation_points({"formation":"split"}, 4)
	_expect(split[0].x < 0.3 and split[1].x > 0.7, "split formation should attack from both flanks")
	var pincer := EncounterRules.formation_points({"formation":"pincer"}, 6)
	_expect(pincer[0].x < 0.15 and pincer[1].x > 0.85, "pincer should establish opposing edge attacks")
	var box := EncounterRules.formation_points({"formation":"bomber_box"}, 6)
	_expect(box[0].y == box[1].y and box[3].y > box[0].y, "bomber box should use disciplined rows")
	var shell := EncounterRules.formation_points({"formation":"escort_shell"}, 5)
	_expect(absf(shell[0].x - 0.5) < 0.001 and shell[1].x < 0.5 and shell[2].x > 0.5, "escort shell should protect a centre principal")

func _test_route_runtime_wiring() -> void:
	var director := FileAccess.open("res://scripts/encounter_director.gd", FileAccess.READ)
	_expect(director != null, "encounter director should be readable")
	if director != null:
		var source := director.get_as_text()
		_expect(source.contains('"--capture-secret"') and source.contains("capture_secret"), "secret-route visual QA should expose a deterministic due-beat fixture")
		_expect(source.contains('enemy["strike_priority"] = true'), "LOW+BMB route should tag surface strike-priority targets")
		_expect(source.contains('enemy["intercept_priority"] = true'), "HIGH+FTR route should tag air intercept-priority targets")
		_expect(source.contains("HIGH_INTERCEPT_VALUE_BONUS"), "high-route target packet should carry bounded extra core combat value")
		_expect(source.contains('scene.set("secrets_discovered"') and source.contains("EncounterRules.is_secret(beat)"), "triggered mastery secrets should feed authoritative sortie telemetry")
		_expect(source.contains("discovered_secret_ids") and source.contains('var stable_id := "%s:%s"'), "triggered mastery secrets should persist stable mission-and-vector identities")
	var cue := FileAccess.open("res://scripts/intercept_route_director.gd", FileAccess.READ)
	_expect(cue != null, "intercept route director should be readable")
	if cue != null:
		var source := cue.get_as_text()
		_expect(source.contains("INTERCEPT CHAIN" ) or source.contains("InterceptRouteRules.label"), "high-route presentation should expose rapid-intercept chain")
		_expect(source.contains("TARGET_FRAME") and source.contains("CLOSURE_FILL") and source.contains("CHAIN_FILL"), "intercept routes should use authored target and timing sprites")
		_expect(not source.contains("draw_line") and not source.contains("draw_rect"), "intercept route presentation should not regress to vector brackets or bars")
		_expect(source.contains("_chain_timer") and source.contains("_last_score"), "intercept chain should remain presentation-derived without mutating score")
		_expect(not source.contains('scene.set("score"'), "intercept presentation must not own score mutation")
	var intercept_sizes := {"target_frame":Vector2(32,32),"closure_trough":Vector2(16,3),"closure_fill":Vector2(16,3),"chain_trough":Vector2(84,4),"chain_fill":Vector2(84,4)}
	for asset_name in intercept_sizes:
		var texture := load("res://assets/runtime/ui/hud/intercept_route/%s.png" % asset_name)
		_expect(texture is Texture2D and texture.get_size() == intercept_sizes[asset_name], "intercept HUD sprite should retain registered geometry: %s" % asset_name)
	_expect(FileAccess.file_exists("res://assets/source/ui/hud/intercept_route_manifest.json"), "intercept route source/runtime manifest should exist")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('InterceptRouteDirector="*res://scripts/intercept_route_director.gd"'), "intercept route presentation should remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
