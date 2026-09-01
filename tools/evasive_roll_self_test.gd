extends SceneTree

const EvasiveRollRules = preload("res://scripts/evasive_roll_rules.gd")

func _init() -> void:
	var failures: Array[String] = []
	_expect(is_equal_approx(EvasiveRollRules.FIGHTER_DURATION, 0.68), "fighter roll should be a short committed seven-tenths-second manoeuvre", failures)
	_expect(EvasiveRollRules.BOMBER_DURATION > EvasiveRollRules.FIGHTER_DURATION, "deployed bomber geometry should roll more slowly", failures)
	_expect(EvasiveRollRules.displacement("fighter") > EvasiveRollRules.displacement("bomber"), "fighter should break farther laterally", failures)
	var edge_on_squared := EvasiveRollRules.collision_multiplier(0.5)
	_expect(is_equal_approx(sqrt(edge_on_squared), EvasiveRollRules.MIN_HIT_PROFILE), "edge-on roll should physically narrow the radius to 38 percent in squared-distance collision space", failures)
	_expect(edge_on_squared > 0.0, "evasive roll should narrow collision without granting invulnerability", failures)
	_expect(is_equal_approx(EvasiveRollRules.collision_multiplier(0.0), 1.0) and is_equal_approx(EvasiveRollRules.collision_multiplier(1.0), 1.0), "normal hit profile should return at both roll endpoints", failures)
	var art := FileAccess.get_file_as_string("res://scripts/combat_art_director.gd")
	_expect(art.contains("VX94_EVASIVE_ROLL") and art.contains("roll_19.png") and art.contains("authored_index"), "combat art should use all twenty authored volumetric roll poses", failures)
	_expect(not art.contains("edge_profile * inverted"), "evasive-roll art must never regress to flat runtime sprite squashing", failures)
	for frame_index in range(20):
		var frame := load("res://assets/runtime/craft/vx94/evasive_roll/roll_%02d.png" % frame_index) as Texture2D
		_expect(frame != null and frame.get_size() == Vector2(64,72) and frame.get_image().detect_alpha() != Image.ALPHA_NONE, "roll frame %02d should retain reviewed registered transparent sprite geometry" % frame_index, failures)
	_expect(art.contains('_capture_craft_state() == "evasive-roll"'), "visual QA should expose a deterministic evasive-roll fixture", failures)
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main.contains("_evasive_collision_multiplier()"), "projectile and contact collision should use the physical roll profile", failures)
	_expect(main.contains("MIN_HIT_PROFILE * EvasiveRollRules.MIN_HIT_PROFILE"), "runtime clamp should preserve the authored 38-percent radius in squared-distance collision space", failures)
	_expect(main.contains("missile_lock_ratio") and main.contains("missile_lock_ready"), "missile interceptors should visibly acquire before launch", failures)
	var hud := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	_expect(hud.contains("RWR  MSL") and hud.contains("TTI %.1f") and hud.contains("RWR  SPIKE"), "compact late-1990s RWR symbology should expose spike, bearing and time-to-impact", failures)
	if failures.is_empty():
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
