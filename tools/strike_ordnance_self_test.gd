extends SceneTree

const StrikeOrdnanceRules = preload("res://scripts/strike_ordnance_rules.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_drop_rules()
	_test_damage_roles()
	_test_route_targeting()
	_test_stability()
	_test_rearm()
	_test_source_wiring()
	if failures.is_empty():
		print("Strike Wing strike ordnance self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_drop_rules() -> void:
	_expect(StrikeOrdnanceRules.can_drop("bomber", "low", 1, 0.0), "bomber should drop strike ordnance at low altitude")
	_expect(StrikeOrdnanceRules.can_drop("bomber", "mid", 1, 0.0), "bomber should drop strike ordnance at mid altitude")
	_expect(not StrikeOrdnanceRules.can_drop("fighter", "low", 1, 0.0), "fighter should not use bombing-run ordnance")
	_expect(not StrikeOrdnanceRules.can_drop("bomber", "high", 1, 0.0), "strike ordnance should be unavailable at high altitude")
	_expect(not StrikeOrdnanceRules.can_drop("bomber", "low", 0, 0.0), "empty ordnance rack must block drop")
	_expect(not StrikeOrdnanceRules.can_drop("bomber", "low", 1, 0.1), "drop cooldown must be respected")
	_expect(StrikeOrdnanceRules.blast_radius("low") > StrikeOrdnanceRules.blast_radius("mid"), "low-altitude run should have the stronger strike footprint")

func _test_damage_roles() -> void:
	_expect(StrikeOrdnanceRules.damage_for_target("ground", false, "low") > StrikeOrdnanceRules.damage_for_target("air", false, "low"), "strike bomb should strongly prefer surface targets")
	_expect(StrikeOrdnanceRules.damage_for_target("sea", false, "low") == StrikeOrdnanceRules.damage_for_target("ground", false, "low"), "naval and ground targets should share surface strike role")
	_expect(StrikeOrdnanceRules.damage_for_target("ground", false, "low") > StrikeOrdnanceRules.damage_for_target("ground", false, "mid"), "low-altitude bombing should outperform mid-altitude bombing")
	_expect(StrikeOrdnanceRules.damage_for_target("boss", true, "low") > 0, "boss should take bounded strike damage")

func _test_route_targeting() -> void:
	var player := Vector2(100, 180)
	var projected := StrikeOrdnanceRules.target_point(player, "low")
	var enemies := [
		{"position":projected + Vector2(2, 0),"category":"ground","hp":20},
		{"position":projected + Vector2(18, 0),"category":"ground","hp":20,"strike_priority":true,"route_bonus_id":"low_attack_window"},
		{"position":projected + Vector2(4, 0),"category":"air","hp":20,"strike_priority":true}
	]
	_expect(StrikeOrdnanceRules.assisted_target_index(player, "low", enemies) == 1, "bombing computer should prefer a route-priority surface target over a closer ordinary target")
	var point := StrikeOrdnanceRules.assisted_target_point(player, "low", enemies)
	_expect(point == Vector2(roundf(enemies[1].position.x), roundf(enemies[1].position.y)), "route-priority lock should use the tagged target position")
	_expect(StrikeOrdnanceRules.priority_target_at_point(point, enemies), "route target should expose stronger bombing-computer designation")
	_expect(StrikeOrdnanceRules.route_precision_score(enemies[1], true) == StrikeOrdnanceRules.ROUTE_PRECISION_SCORE, "precision ordnance kill should award bounded route score")
	_expect(StrikeOrdnanceRules.route_precision_score(enemies[1], false) == 0, "route bonus must not award if ordnance did not make the kill")
	_expect(StrikeOrdnanceRules.route_precision_score(enemies[0], true) == 0, "ordinary surface targets must not award route precision score")

func _test_stability() -> void:
	var stability := 0.0
	stability = StrikeOrdnanceRules.update_stability(stability, StrikeOrdnanceRules.STABILITY_SECONDS, true, true, 0.0)
	_expect(stability >= 0.99, "steady low bomber run should reach full bombing-computer stability")
	var stable_delay := StrikeOrdnanceRules.stabilized_impact_delay("low", 1.0)
	_expect(stable_delay < StrikeOrdnanceRules.impact_delay("low"), "stable low run should shorten bomb time-to-impact")
	var stable_radius := StrikeOrdnanceRules.stabilized_aim_radius("low", 1.0)
	_expect(stable_radius < StrikeOrdnanceRules.aim_radius("low"), "stable low run should tighten bombing-computer aim radius")
	_expect(absf(StrikeOrdnanceRules.stabilized_impact_delay("mid", 1.0) - StrikeOrdnanceRules.impact_delay("mid")) < 0.001, "mid-altitude stand-off bombing should not gain low-level stabilization bonus")
	var decayed := StrikeOrdnanceRules.update_stability(1.0, 0.3, true, true, 1.0)
	_expect(decayed < 0.5, "hard lateral maneuvering should bleed bombing-run stability quickly")
	_expect(StrikeOrdnanceRules.update_stability(0.5, 0.2, false, true, 0.0) < 0.5, "leaving low bomber conditions should decay stability")

func _test_rearm() -> void:
	_expect(StrikeOrdnanceRules.rearm(0) == StrikeOrdnanceRules.MAX_ORDNANCE, "full tanker rearm should restore strike rack")
	_expect(StrikeOrdnanceRules.rearm(StrikeOrdnanceRules.MAX_ORDNANCE) == StrikeOrdnanceRules.MAX_ORDNANCE, "strike rack rearm should clamp to maximum")
	_expect(CraftFormRules.projectile_hit_radius_sq("fighter") < CraftFormRules.projectile_hit_radius_sq("bomber"), "fighter should have smaller hostile-projectile profile than bomber")

func _test_source_wiring() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"'), "strike ordnance director should remain autoloaded")
	var encounter := FileAccess.open("res://scripts/encounter_director.gd", FileAccess.READ)
	_expect(encounter != null, "encounter director should be readable")
	if encounter != null:
		var source := encounter.get_as_text()
		_expect(source.contains('enemy["strike_priority"] = true'), "LOW+BMB route enemies should be tagged for bombing-computer priority")
		_expect(source.contains('EncounterRules.is_low_bomber_route(beat)'), "strike-priority tags should originate from authored route conditions")
	var ordnance := FileAccess.open("res://scripts/strike_ordnance_director.gd", FileAccess.READ)
	_expect(ordnance != null, "strike ordnance director should be readable")
	if ordnance != null:
		var source := ordnance.get_as_text()
		_expect(source.contains("ROUTE TARGET"), "route target should receive stronger visual designation")
		_expect(source.contains("PRECISION ROUTE HIT"), "precision route kill should produce player feedback")
		_expect(source.contains("route_precision_score"), "ordnance kill path should award bounded route score")
		_expect(source.contains("_update_attack_run_stability"), "strike owner should maintain low-level attack-run stability")
		_expect(source.contains("STB%03d"), "bombing HUD should expose stabilization percentage")
		_expect(source.contains("stabilized_impact_delay"), "drop timing should consume stabilization rules")
		_expect(source.contains("maxi(1, hp - damage)"), "strike ordnance must remain nonlethal against bosses")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
