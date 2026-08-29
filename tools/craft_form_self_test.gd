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
	_expect(AltitudeRules.ground_scale("low") > AltitudeRules.ground_scale("mid") and AltitudeRules.ground_scale("mid") > AltitudeRules.ground_scale("high") and AltitudeRules.ground_scale("high") > AltitudeRules.ground_scale("orbital"), "ground presentation should diminish with altitude")
	_expect(AltitudeRules.allows_ground_targets("low") and AltitudeRules.allows_ground_targets("mid"), "low/mid should support surface warfare")
	_expect(not AltitudeRules.allows_ground_targets("high") and not AltitudeRules.allows_ground_targets("orbital"), "high/orbital should not use normal ground-target gameplay")
	_expect(AltitudeRules.supports_form("orbital", "fighter"), "fighter should support orbital operations")
	_expect(not AltitudeRules.supports_form("orbital", "bomber"), "bomber geometry should be unavailable in orbital flight")

func _test_campaign_world() -> void:
	var data = ContentCatalog.load_json("res://data/campaign_world.json")
	_expect(typeof(data) == TYPE_DICTIONARY, "campaign world catalogue should load")
	if typeof(data) != TYPE_DICTIONARY:
		return
	_expect(data.get("altitude_bands", []).size() == 4, "campaign world should define four altitude bands")
	var contexts = data.get("mission_context", {})
	_expect(typeof(contexts) == TYPE_DICTIONARY and contexts.size() == 12, "all twelve current missions should receive campaign-world context")
	for mission_id in contexts.keys():
		var context: Dictionary = contexts[mission_id]
		_expect(AltitudeRules.sanitize(str(context.get("altitude", ""))) == str(context.get("altitude", "")), "%s should use a supported initial altitude" % mission_id)
		_expect(str(context.get("recommended_form", "")) in ["fighter", "bomber"], "%s should recommend a valid craft form" % mission_id)
		var last_time := -1.0
		for transition in context.get("altitude_transitions", []):
			var at := float(transition.get("at_seconds", -1.0))
			_expect(at > last_time, "%s altitude transitions should be time ordered" % mission_id)
			_expect(AltitudeRules.sanitize(str(transition.get("altitude", ""))) == str(transition.get("altitude", "")), "%s altitude transition should target supported band" % mission_id)
			last_time = at
	for mission_id in ["m01_coastal_intercept","m02_refinery_run","m03_black_sea","m04_breakwater","m05_furnace_line","m06_black_flag"]:
		_expect(str(contexts.get(mission_id, {}).get("threat_phase", "")) == "mercenary_war", "%s should remain in opening mercenary war" % mission_id)
	for mission_id in ["m07_ghost_sky","m08_machine_furnace","m09_black_horizon","m10_blue_fire","m11_cold_station","m12_machine_ark"]:
		_expect(str(contexts.get(mission_id, {}).get("threat_phase", "")) == "drone_war", "%s should belong to autonomous drone war" % mission_id)
	for mission_id in ["m07_ghost_sky","m08_machine_furnace"]:
		_expect(str(contexts.get(mission_id, {}).get("tech_era", "")) == "electromagnetic", "%s should remain electromagnetic-era drone warfare" % mission_id)
	for mission_id in ["m09_black_horizon","m10_blue_fire","m11_cold_station"]:
		_expect(str(contexts.get(mission_id, {}).get("tech_era", "")) == "directed_energy", "%s should develop the directed-energy era" % mission_id)
	var ark := contexts.get("m12_machine_ark", {})
	_expect(str(ark.get("tech_era", "")) == "strategic_orbital", "Machine Ark should be the first strategic-orbital campaign mission")
	_expect(str(ark.get("altitude", "")) == "high", "Machine Ark should begin in the high atmosphere before its final orbital burn")
	_expect("atlas_tanker" in ark.get("support", []), "Machine Ark should offer a pre-orbit Atlas rearm window")
	var ark_transitions: Array = ark.get("altitude_transitions", [])
	_expect(ark_transitions.size() == 1 and int(ark_transitions[0].get("at_seconds", 0)) == 82 and str(ark_transitions[0].get("altitude", "")) == "orbital", "Machine Ark should execute the authored 82-second final orbital burn")
	var horizon_transitions: Array = contexts.get("m09_black_horizon", {}).get("altitude_transitions", [])
	_expect(horizon_transitions.size() == 1 and str(horizon_transitions[0].get("altitude", "")) == "orbital", "Black Horizon should transition into orbital combat")
	var blue_fire_transitions: Array = contexts.get("m10_blue_fire", {}).get("altitude_transitions", [])
	_expect(blue_fire_transitions.size() == 1 and str(blue_fire_transitions[0].get("altitude", "")) == "orbital", "Blue Fire should climb into orbital phase-array combat")

func _test_source_integration() -> void:
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(director_file != null, "craft form director should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("_apply_due_altitude_transitions(scene)"), "craft controller should own timed altitude transitions")
		_expect(source.contains("_apply_weapon_interlock(scene)"), "geometry changes should apply weapons interlock")
	var environment_file := FileAccess.open("res://scripts/environment_director.gd", FileAccess.READ)
	_expect(environment_file != null, "environment director should be readable")
	if environment_file != null:
		var source := environment_file.get_as_text()
		_expect(source.contains('motif == "orbital" and band == "high"'), "orbital-profile missions should retain cloud-top presentation during a high-altitude lead-in")
		_expect(source.contains("_draw_high_atmosphere_horizon"), "high-atmosphere orbital lead-ins should retain visible atmospheric curvature")
	var support_file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(support_file != null, "support director should be readable")
	if support_file != null:
		_expect(support_file.get_as_text().contains('func rearm_support()'), "Atlas should retain tactical rearm API")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
