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
	_expect(data.get("threat_phases", []).size() >= 3, "campaign world should define mercenary, drone and external threat phases")
	var contexts = data.get("mission_context", {})
	_expect(typeof(contexts) == TYPE_DICTIONARY and contexts.size() >= 9, "all nine current missions should receive campaign-world context")
	for mission_id in contexts.keys():
		var context: Dictionary = contexts[mission_id]
		_expect(AltitudeRules.sanitize(str(context.get("altitude", ""))) == str(context.get("altitude", "")), "%s should use a supported initial altitude" % mission_id)
		_expect(str(context.get("recommended_form", "")) in ["fighter", "bomber"], "%s should recommend a valid craft form" % mission_id)
		var last_time := -1.0
		for transition in context.get("altitude_transitions", []):
			_expect(typeof(transition) == TYPE_DICTIONARY, "%s altitude transition should be a dictionary" % mission_id)
			if typeof(transition) != TYPE_DICTIONARY:
				continue
			var at := float(transition.get("at_seconds", -1.0))
			_expect(at > last_time, "%s altitude transitions should be time ordered" % mission_id)
			_expect(AltitudeRules.sanitize(str(transition.get("altitude", ""))) == str(transition.get("altitude", "")), "%s altitude transition should target supported band" % mission_id)
			last_time = at
	for mission_id in ["m01_coastal_intercept","m02_refinery_run","m03_black_sea","m04_breakwater","m05_furnace_line","m06_black_flag"]:
		_expect(str(contexts.get(mission_id, {}).get("threat_phase", "")) == "mercenary_war", "%s should remain in opening mercenary war" % mission_id)
	for mission_id in ["m07_ghost_sky","m08_machine_furnace","m09_black_horizon"]:
		_expect(str(contexts.get(mission_id, {}).get("threat_phase", "")) == "drone_war", "%s should belong to autonomous drone war" % mission_id)
	_expect(str(contexts.get("m07_ghost_sky", {}).get("altitude", "")) == "high", "Ghost Sky should introduce high-altitude drone combat")
	var black_flag_transitions: Array = contexts.get("m06_black_flag", {}).get("altitude_transitions", [])
	_expect(black_flag_transitions.size() == 2 and str(black_flag_transitions[0].get("altitude", "")) == "low" and str(black_flag_transitions[1].get("altitude", "")) == "mid", "Black Flag should descend for sea-skimming strike and climb for flagship phase")
	var horizon := contexts.get("m09_black_horizon", {})
	_expect(str(horizon.get("altitude", "")) == "high", "Black Horizon should begin at high altitude before orbital breakout")
	var horizon_transitions: Array = horizon.get("altitude_transitions", [])
	_expect(horizon_transitions.size() == 1 and str(horizon_transitions[0].get("altitude", "")) == "orbital", "Black Horizon should transition into orbital combat")
	_expect(str(horizon.get("recommended_form", "")) == "fighter", "orbital command assault should recommend fighter configuration")

func _test_source_integration() -> void:
	var main_file := FileAccess.open("res://scripts/main.gd", FileAccess.READ)
	_expect(main_file != null, "main.gd should be readable")
	if main_file != null:
		var source := main_file.get_as_text()
		_expect(source.contains('_craft_float("movement_multiplier", 1.0)'), "main movement should consume craft form speed")
		_expect(source.contains('_craft_float("primary_spread_multiplier", 1.0)'), "main primary fire should consume craft form spread")
		_expect(source.contains('_target_damage_multiplier(enemy_class)'), "main collision should consume form/altitude target effectiveness")
		_expect(source.contains('_craft_float("collision_radius_sq", 420.0)'), "main contact collision should consume form profile")
		_expect(source.contains('_craft_float("projectile_hit_radius_sq", 120.0)'), "hostile projectile collision should consume the active form hit profile")
		_expect(not source.contains('distance_squared_to(player_position) <= 120.0'), "hostile projectile collision must not revert to fixed prototype radius")
	var director_file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(director_file != null, "craft form director should be readable")
	if director_file != null:
		var source := director_file.get_as_text()
		_expect(source.contains("_apply_due_altitude_transitions(scene)"), "craft controller should own timed altitude transitions")
		_expect(source.contains("if not AltitudeRules.supports_form(altitude, form)"), "altitude transition should force legal craft geometry")
		_expect(source.contains("projectile_hit_radius_sq"), "craft controller should expose hostile-projectile hit profile")
		_expect(source.contains("_apply_weapon_interlock(scene)"), "manual and forced geometry changes should apply weapons interlock")
		_expect(source.contains('scene.set("fire_timer", maxf(float(scene.get("fire_timer")), CraftFormRules.TRANSFORM_WEAPON_INTERLOCK))'), "transform interlock should delay primary firing at the source")
		_expect(source.contains('scene.set("secondary_timer", maxf(float(scene.get("secondary_timer")), CraftFormRules.TRANSFORM_WEAPON_INTERLOCK))'), "transform interlock should delay emergency secondary firing at the source")
	var support_file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(support_file != null, "support_director.gd should be readable")
	if support_file != null:
		var support_source := support_file.get_as_text()
		_expect(support_source.contains('support_energy_multiplier'), "support energy should consume craft form efficiency")
		_expect(support_source.contains('func rearm_support()'), "tanker should have a clean tactical-support rearm API")
	var ui_file := FileAccess.open("res://scripts/pixel_ui_director.gd", FileAccess.READ)
	_expect(ui_file != null, "pixel UI should be readable for tech-era presentation checks")
	if ui_file != null:
		var ui_source := ui_file.get_as_text()
		_expect(ui_source.contains("TECH %s") and ui_source.contains("func _tech_era_name"), "loadout UI should expose full technology era")
		_expect(ui_source.contains('"electromagnetic": return "EM"') and ui_source.contains('"directed_energy": return "DE"') and ui_source.contains('"strategic_orbital": return "ORB"'), "combat HUD should expose compact technology era codes")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		var project_source := project.get_as_text()
		_expect(project_source.contains('CraftFormDirector="*res://scripts/craft_form_director.gd"'), "craft form controller should remain autoloaded")
		_expect(project_source.contains('BattlefieldSupportDirector="*res://scripts/battlefield_support_director.gd"'), "battlefield support controller should remain autoloaded")
		_expect(project_source.contains('StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"'), "strike ordnance controller should remain autoloaded")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
