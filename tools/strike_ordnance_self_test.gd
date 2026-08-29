extends SceneTree

const StrikeOrdnanceRules = preload("res://scripts/strike_ordnance_rules.gd")
const CraftFormRules = preload("res://scripts/craft_form_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_drop_rules()
	_test_damage_roles()
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

func _test_rearm() -> void:
	_expect(StrikeOrdnanceRules.rearm(0) == StrikeOrdnanceRules.MAX_ORDNANCE, "full tanker rearm should restore strike rack")
	_expect(StrikeOrdnanceRules.rearm(StrikeOrdnanceRules.MAX_ORDNANCE) == StrikeOrdnanceRules.MAX_ORDNANCE, "strike rack rearm should clamp to maximum")
	_expect(CraftFormRules.projectile_hit_radius_sq("fighter") < CraftFormRules.projectile_hit_radius_sq("bomber"), "fighter should have smaller hostile-projectile profile than bomber")

func _test_source_wiring() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null and project.get_as_text().contains('StrikeOrdnanceDirector="*res://scripts/strike_ordnance_director.gd"'), "strike ordnance director should remain autoloaded")
	var support := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(support != null, "support director should be readable")
	if support != null:
		var source := support.get_as_text()
		_expect(source.contains('get_node_or_null("/root/StrikeOrdnanceDirector")') and source.contains('strike.call("rearm_full")'), "Atlas tactical rearm path should also refill strike ordnance")
	var ordnance := FileAccess.open("res://scripts/strike_ordnance_director.gd", FileAccess.READ)
	_expect(ordnance != null, "strike ordnance director should be readable")
	if ordnance != null:
		var source := ordnance.get_as_text()
		_expect(source.contains("KEY_E"), "E should remain the bombing-run control")
		_expect(source.contains("maxi(1, hp - damage)"), "strike ordnance must remain nonlethal against bosses")
		_expect(source.contains('PixelFont.draw_text(surface, "E BOMB %d"'), "bombing-run ordnance count should use pixel HUD presentation")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
