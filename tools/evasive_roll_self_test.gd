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
	_expect(art.contains("VX94_EVASIVE_ROLL") and art.contains("VX94_EVASIVE_ROLL_RIGHT") and art.contains("VX94_BOMBER_EVASIVE_ROLL") and art.contains("roll_19.png") and art.contains("roll_right_19.png") and art.contains("bomber_roll_right_19.png") and art.contains("authored_index"), "combat art should use twenty authored volumetric poses for each form and roll direction", failures)
	_expect(not art.contains("edge_profile * inverted"), "evasive-roll art must never regress to flat runtime sprite squashing", failures)
	_expect(art.contains("VX94_ROLL_EXHAUST_ALPHA[authored_index]"), "roll exhaust should disappear behind the fuselage at both edge-on passages", failures)
	for frame_index in range(20):
		var frame := load("res://assets/runtime/craft/vx94/evasive_roll/roll_%02d.png" % frame_index) as Texture2D
		_expect(frame != null and frame.get_size() == Vector2(64,72) and frame.get_image().detect_alpha() != Image.ALPHA_NONE, "roll frame %02d should retain reviewed registered transparent sprite geometry" % frame_index, failures)
		var right_frame := load("res://assets/runtime/craft/vx94/evasive_roll/roll_right_%02d.png" % frame_index) as Texture2D
		_expect(right_frame != null and right_frame.get_size() == Vector2(64,72) and right_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "right roll frame %02d should retain reviewed registered transparent sprite geometry" % frame_index, failures)
		for bomber_prefix in ["bomber_roll", "bomber_roll_right"]:
			var bomber_frame := load("res://assets/runtime/craft/vx94/evasive_roll/%s_%02d.png" % [bomber_prefix,frame_index]) as Texture2D
			_expect(bomber_frame != null and bomber_frame.get_size() == Vector2(64,72) and bomber_frame.get_image().detect_alpha() != Image.ALPHA_NONE, "%s frame %02d should retain reviewed registered transparent sprite geometry" % [bomber_prefix,frame_index], failures)
			if bomber_frame != null and frame != null and frame_index in [0, 5, 7, 10, 12, 15, 16, 19]:
				var fighter_width := frame.get_image().get_used_rect().size.x
				var bomber_width := bomber_frame.get_image().get_used_rect().size.x
				_expect(bomber_width >= fighter_width + 4, "%s frame %02d should preserve a visibly broader bomber projection (%d > %d)" % [bomber_prefix, frame_index, bomber_width, fighter_width], failures)
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/evasive_roll/vx94_evasive_roll_manifest.json"), "directional evasive-roll manifest should exist", failures)
	_expect(FileAccess.file_exists("res://assets/source/craft/vx94/evasive_roll_loadout_v1/manifest.json"), "evasive-roll loadout layers should retain reproducible source evidence", failures)
	var builder := FileAccess.get_file_as_string("res://tools/build_vx94_evasive_roll_art.ps1")
	_expect(builder.contains('-resize "$($Width)x64!"'), "bomber roll generation must author its requested width instead of silently retaining fighter width", failures)
	_expect(art.contains("_draw_evasive_loadout") and art.contains("_roll_primary_cache") and art.contains("roll_cosine"), "evasive rolls should retain mounted weapon and damage identity through authored exposures", failures)
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main_source.contains("--capture-hull-ratio=") and main_source.contains("captured_hull_ratio"), "visual QA should expose deterministic damaged roll states", failures)
	for form in ["fighter", "bomber"]:
		for family in ["ballistic", "needle_rail", "storm_cannon", "plasma_lance"]:
			var layer := load("res://assets/runtime/craft/vx94/gameplay/roll_loadouts/%s_%s.png" % [family, form]) as Texture2D
			_expect(layer != null and layer.get_size() == Vector2(64, 72) and layer.get_image().detect_alpha() != Image.ALPHA_NONE, "roll loadout layer should retain transparent registered geometry: %s/%s" % [family, form], failures)
	_expect(art.contains('_capture_craft_state() in ["evasive-roll", "evasive-roll-bomber"]'), "visual QA should expose deterministic fighter and bomber evasive-roll fixtures", failures)
	var main := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(main.contains("_evasive_collision_multiplier()"), "projectile and contact collision should use the physical roll profile", failures)
	_expect(main.contains("MIN_HIT_PROFILE * EvasiveRollRules.MIN_HIT_PROFILE"), "runtime clamp should preserve the authored 38-percent radius in squared-distance collision space", failures)
	_expect(main.contains("missile_lock_ratio") and main.contains("missile_lock_ready"), "missile interceptors should visibly acquire before launch", failures)
	var hud := FileAccess.get_file_as_string("res://scripts/pixel_ui_director.gd")
	_expect(hud.contains('MISSILE X%d  %d O\'CLOCK  TTI %.1f  CM%02d') and hud.contains("RADAR SPIKE  %02d%%  EVADE  CM%02d"), "compact late-1990s RWR symbology should expose threat, clock bearing, time-to-impact, evasive command and remaining countermeasures", failures)
	if failures.is_empty():
		quit(0)
	else:
		for failure in failures: push_error(failure)
		quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
