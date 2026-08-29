extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_forms()
	_test_altitudes()
	_test_campaign_world()
	_test_source_integration()
	if failures.is_empty():
		print("Strike Wing craft form/altitude self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_forms() -> void:
	_expect(CraftFormRules.toggle(CraftFormRules.FIGHTER) == CraftFormRules.BOMBER, "fighter should transform into bomber")
	_expect(CraftFormRules.toggle(CraftFormRules.BOMBER) == CraftFormRules.FIGHTER, "bomber should transform into fighter")
	_expect(CraftFormRules.movement_multiplier(CraftFormRules.FIGHTER) > CraftFormRules.movement_multiplier(CraftFormRules.BOMBER), "fighter should be faster than bomber")
	_expect(CraftFormRules.collision_radius_sq(CraftFormRules.FIGHTER) < CraftFormRules.collision_radius_sq(CraftFormRules.BOMBER), "fighter should retain tighter contact profile")
	_expect(CraftFormRules.projectile_hit_radius_sq(CraftFormRules.FIGHTER) < CraftFormRules.projectile_hit_radius_sq(CraftFormRules.BOMBER), "fighter should retain tighter hostile-projectile profile")
	_expect(CraftFormRules.primary_spread_multiplier(CraftFormRules.FIGHTER) < CraftFormRules.primary_spread_multiplier(CraftFormRules.BOMBER), "fighter primary spread should be tighter")
	_expect(CraftFormRules.ground_attack_multiplier(CraftFormRules.BOMBER) > CraftFormRules.ground_attack_multiplier(CraftFormRules.FIGHTER), "bomber should be stronger against surface targets")
	_expect(CraftFormRules.air_attack_multiplier(CraftFormRules.FIGHTER) > CraftFormRules.air_attack_multiplier(CraftFormRules.BOMBER), "fighter should be stronger against air targets")
	_expect(CraftFormRules.support_energy_multiplier(CraftFormRules.BOMBER) < CraftFormRules.support_energy_multiplier(CraftFormRules.FIGHTER), "bomber should run support systems more efficiently")
	_expect(CraftFormRules.TRANSFORM_WEAPON_INTERLOCK > 0.0 and CraftFormRules.TRANSFORM_WEAPON_INTERLOCK < CraftFormRules.TRANSFORM_COOLDOWN, "weapon interlock should be brief and shorter than transform anti-spam cooldown")

func _test_altitudes() -> void:
	_expect(AltitudeRules.BANDS == ["low", "mid", "high", "orbital"], "campaign should expose exactly four ordered altitude bands")
	_expect(AltitudeRules.adjacent_band("low", 1) == "mid", "manual climb should move only one altitude lane")
	_expect(AltitudeRules.adjacent_band("high", -1) == "mid", "manual dive should move only one altitude lane")
	_expect(AltitudeRules.is_adjacent("mid", "high"), "mid/high should be adjacent lanes")
	_expect(not AltitudeRules.is_adjacent("low", "high"), "manual altitude selection must not skip lanes")
	_expect(AltitudeRules.TRANSITION_SECONDS >= 0.8 and AltitudeRules.TRANSITION_SECONDS <= 1.5, "altitude transition should be visible but remain arcade-responsive")
	_expect(AltitudeRules.ground_scale("low") > AltitudeRules.ground_scale("mid") and AltitudeRules.ground_scale("mid") > AltitudeRules.ground_scale("high") and AltitudeRules.ground_scale("high") > AltitudeRules.ground_scale("orbital"), "ground presentation should diminish with altitude")
	_expect(AltitudeRules.supports_form("orbital", "fighter"), "fighter should support orbital operations")
	_expect(not AltitudeRules.supports_form("orbital", "bomber"), "bomber geometry should be unavailable in orbital flight")

func _test_campaign_world() -> void:
	var data = ContentCatalog.load_json("res://data/campaign_world.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "campaign world catalogue should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var contexts = data.get("mission_context", {})
	_expect(typeof(contexts) == TYPE_DICTIONARY and contexts.size() == 12, "all twelve current missions should receive campaign-world context")
	var choice_count := 0
	for mission_id in contexts.keys():
		var context: Dictionary = contexts[mission_id]
		_expect(AltitudeRules.sanitize(str(context.get("altitude", ""))) == str(context.get("altitude", "")), "%s should use a supported initial altitude" % mission_id)
		for window in context.get("altitude_choice_windows", []):
			choice_count += 1
			var bands := AltitudeRules.allowed_manual_bands(window)
			_expect(bands.size() >= 2, "%s manual altitude window should expose at least two lanes" % mission_id)
			_expect(float(window.get("end_seconds", 0.0)) > float(window.get("start_seconds", 0.0)), "%s altitude choice window should have positive duration" % mission_id)
		var last_time := -1.0
		for transition in context.get("altitude_transitions", []):
			var at := float(transition.get("at_seconds", -1.0))
			_expect(at > last_time, "%s altitude transitions should be time ordered" % mission_id)
			last_time = at
	_expect(choice_count >= 7, "campaign should contain multiple optional altitude-lane windows")
	var ark := contexts.get("m12_machine_ark", {})
	var ark_transitions: Array = ark.get("altitude_transitions", [])
	_expect(str(ark.get("altitude", "")) == "high", "Machine Ark should begin high before orbital burn")
	_expect(ark_transitions.size() == 1 and int(ark_transitions[0].get("at_seconds", 0)) == 156 and str(ark_transitions[0].get("altitude", "")) == "orbital", "Machine Ark should execute post-rearm orbital burn at 156 seconds")

func _test_source_integration() -> void:
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(director_file != null, "craft form director should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("_try_manual_altitude(scene, direction)"), "craft controller should own manual adjacent-lane changes")
		_expect(source.contains('KEY_PAGEUP') and source.contains('KEY_PAGEDOWN'), "manual altitude controls should use PageUp/PageDown")
		_expect(source.contains("_begin_altitude_transition"), "scripted and manual altitude changes should share one transition source")
		_expect(source.contains("func primary_mount_offsets"), "craft controller should expose physical weapon mount points")
		_expect(source.contains("func bomber_rotary_deployed"), "craft controller should expose bomber nose rotary deployment")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("_craft_primary_mount_offsets(weapon,count)"), "primary fire should request physical mount offsets")
		_expect(source.contains('"position":player_position+mount_offsets[i]'), "projectiles should originate from fighter/bomber weapon mounts")
	var art_file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(art_file != null, "combat art should be readable")
	if art_file != null:
		var source := art_file.get_as_text()
		_expect(source.contains("TRANSFORM_VISUAL_SECONDS := 0.42"), "wing sweep should remain visibly mechanical")
		_expect(source.contains("_draw_rotary_cannon"), "bomber art should deploy a nose rotary cannon")
		_expect(source.contains("Fighter wing-root cannons") or source.contains("wing-root cannon"), "fighter art should retain wing cannon posture")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"'), "altitude transition presentation must remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
