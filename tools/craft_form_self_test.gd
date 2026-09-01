extends SceneTree

const ContentCatalog = preload("res://scripts/content_catalog.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")
const AltitudeRules = preload("res://scripts/altitude_rules.gd")

var failures: Array[String] = []

class TransformFixture:
	extends RefCounted
	var status_text := ""
	var status_timer := 0.0

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
	_expect(is_equal_approx(CraftFormRules.TRANSFORM_VISUAL_SECONDS, 0.92), "canonical wing sweep should retain ten near-one-second held exposures")
	var director_script := load("res://scripts/craft_form_director.gd") as Script
	var director: Node = director_script.new()
	var fixture := TransformFixture.new()
	director.set("_transform_timer", CraftFormRules.TRANSFORM_VISUAL_SECONDS)
	director.call("_update_transform_settle", fixture, 0.50)
	_expect(bool(director.call("transform_active")) and int(director.call("transform_ready_serial")) == 0, "configuration should remain mechanically unsettled during the wing sweep")
	director.call("_update_transform_settle", fixture, 0.50)
	_expect(not bool(director.call("transform_active")) and int(director.call("transform_ready_serial")) == 1, "wing sweep completion should publish exactly one ready event")
	_expect(str(fixture.status_text).contains("CONFIGURATION READY"), "settled geometry should publish a clear ready-state annunciation")
	director.call("_update_transform_settle", fixture, 0.50)
	_expect(int(director.call("transform_ready_serial")) == 1, "settled geometry should not repeat its ready event on later frames")
	director.free()

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
	_expect(AltitudeRules.allows_enemy_class("low", "ground"), "low altitude should allow ground threats")
	_expect(AltitudeRules.allows_enemy_class("mid", "sea"), "mid altitude should retain surface/naval threats")
	_expect(not AltitudeRules.allows_enemy_class("high", "ground"), "high altitude should reject normal ground filler")
	_expect(not AltitudeRules.allows_enemy_class("orbital", "sea"), "orbital altitude should reject terrestrial/naval filler")
	_expect(AltitudeRules.allows_enemy_class("orbital", "air"), "orbital altitude should retain air/exo threats")
	_expect(AltitudeRules.allows_enemy_class("orbital", "boss", true), "bosses should remain eligible regardless of ordinary class filter")

func _test_campaign_world() -> void:
	var data = ContentCatalog.load_json("res://data/campaign_world.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "campaign world catalogue should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	var contexts = data.get("mission_context", {})
	_expect(typeof(contexts) == TYPE_DICTIONARY, "campaign-world contexts should be keyed dictionaries")
	var core_missions: Array = ContentCatalog.load_json("res://data/missions.json").get("missions", [])
	var secret_missions: Array = ContentCatalog.load_json("res://data/secret_missions.json").get("missions", [])
	for mission in core_missions:
		_expect(contexts.has(str(mission.get("id", ""))), "core mission should receive campaign-world context: %s" % str(mission.get("id", "")))
	for mission in secret_missions:
		_expect(contexts.has(str(mission.get("id", ""))), "secret sortie should receive campaign-world context: %s" % str(mission.get("id", "")))
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
	var ark: Dictionary = contexts.get("m12_machine_ark", {})
	var ark_transitions: Array = ark.get("altitude_transitions", [])
	_expect(str(ark.get("altitude", "")) == "high", "Machine Ark should begin high before orbital burn")
	_expect(ark_transitions.size() == 1 and int(ark_transitions[0].get("at_seconds", 0)) == 156 and str(ark_transitions[0].get("altitude", "")) == "orbital", "Machine Ark should execute post-rearm orbital burn at 156 seconds")

func _test_source_integration() -> void:
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(director_file != null, "craft form director should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("process_priority = -30"), "craft/altitude context should publish before EncounterDirector")
		_expect(source.contains("_publish_altitude_spawn_profiles(scene)"), "craft controller should publish altitude-filtered filler profiles before main simulation")
		_expect(source.contains("AltitudeRules.allows_enemy_archetype"), "filler filtering should use canonical altitude eligibility rules")
		_expect(source.contains("_try_manual_altitude(scene, direction)"), "craft controller should own manual adjacent-lane changes")
		_expect(source.contains('KEY_PAGEUP') and source.contains('KEY_PAGEDOWN'), "manual altitude controls should use PageUp/PageDown")
		_expect(source.contains('"GEOMETRY LOCK - ALTITUDE TRANSITION"'), "Q transform should be explicitly locked while changing altitude")
		_expect(source.contains('get_node_or_null("/root/PlayerMountDirector")'), "craft primary mounting should delegate to canonical mount owner")
		_expect(source.contains('mounts.call("primary_offsets"'), "primary mount offsets should come from authored mount catalogue")
		_expect(source.contains('mounts.call("bomber_rotary_deployed"'), "bomber nose-gun state should come from authored mount catalogue")
		_expect(source.contains("_capture_altitude_override") and source.contains("--capture-altitude="), "visual QA should expose a deterministic altitude override without changing authored campaign context")
		_expect(source.contains("var allowed: Array = AltitudeRules.BANDS.duplicate()"), "manual altitude selection should accept the canonical runtime Array without a typed-array assignment fault")
	var encounter_file := FileAccess.open("res://scripts/encounter_director.gd", FileAccess.READ)
	_expect(encounter_file != null, "encounter director should be readable")
	if encounter_file != null:
		var source := encounter_file.get_as_text()
		_expect(source.contains("process_priority = -20"), "encounters should run after altitude context and before support/main")
		_expect(source.contains("AltitudeRules.allows_enemy_archetype"), "authored beats should use the same altitude eligibility rule as filler spawning")
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains("_craft_primary_mount_offsets(weapon, count)"), "primary fire should request physical mount offsets")
		_expect(source.contains('"position": player_position + mount_offsets[i]'), "projectiles should originate from fighter/bomber weapon mounts")
	var art_file := FileAccess.open("res://scripts/combat_art_director.gd", FileAccess.READ)
	_expect(art_file != null, "combat art should be readable")
	if art_file != null:
		var source := art_file.get_as_text()
		_expect(source.contains("CraftFormRules.TRANSFORM_VISUAL_SECONDS") and source.contains("TRANSFORM_EXPOSURES := 10"), "wing sweep should use the canonical ten-exposure near-one-second cadence")
		_expect(source.contains("vx94_bomber_v1.png") and source.contains("vx94_transform_03.png"), "bomber art should use the authored attack-form and final mechanical deployment keyframe")
		_expect(not source.contains("_draw_rotary_cannon"), "bomber presentation should not regress to a procedural cannon substitute")
	var transition_file := FileAccess.open("res://scripts/altitude_transition_director.gd", FileAccess.READ)
	var transition_source := transition_file.get_as_text() if transition_file != null else ""
	_expect(transition_source.contains('"CLIMB %s"') and transition_source.contains('"DIVE %s"'), "altitude choice HUD should use device-neutral tactical direction labels")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"'), "altitude transition presentation must remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
