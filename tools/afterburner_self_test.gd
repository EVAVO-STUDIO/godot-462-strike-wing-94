extends SceneTree

const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")

var failures: Array[String] = []

func _initialize() -> void:
	_test_craft_source()
	_test_tanker_refuel_wiring()
	_test_presentation()
	_test_retro_sfx()
	if failures.is_empty():
		print("Strike Wing afterburner self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_craft_source() -> void:
	var file := FileAccess.open("res://scripts/craft_form_director.gd", FileAccess.READ)
	_expect(file != null, "craft form director should be readable")
	if file == null: return
	var source := file.get_as_text()
	_expect(source.contains("AFTERBURNER_CAPACITY := 8.0"), "afterburner should retain eight-second arcade reserve")
	_expect(source.contains("FIGHTER_AFTERBURNER_MULTIPLIER := 1.35"), "fighter should receive stronger afterburner burst")
	_expect(source.contains("BOMBER_AFTERBURNER_MULTIPLIER := 1.22"), "bomber should retain smaller usable afterburner burst")
	_expect(source.contains('Input.is_action_pressed("afterburner")'), "afterburner fuel should burn only while boost input is held")
	_expect(source.contains("_afterburner_burn_rate()"), "afterburner should use form/altitude efficiency instead of flat drain")
	_expect(source.contains("AltitudeRules.LOW") and source.contains("AltitudeRules.ORBITAL"), "afterburner burn rate should react to altitude envelope")
	_expect(source.contains("afterburner_fuel = AFTERBURNER_CAPACITY"), "fresh sortie should start with full afterburner reserve")
	_expect(source.contains("func refuel_afterburner_full()"), "craft should expose explicit tanker refuel API")
	_expect(source.contains('_add_key_action("afterburner", KEY_SHIFT)'), "afterburner should bind to Shift")

func _test_tanker_refuel_wiring() -> void:
	var file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(file != null, "support director should be readable for tanker refuel")
	if file == null: return
	var source := file.get_as_text()
	_expect(source.contains('get_node_or_null("/root/CraftFormDirector")'), "tactical rearm should resolve craft controller")
	_expect(source.contains('has_method("refuel_afterburner_full")'), "Atlas rearm should detect afterburner refuel API")
	_expect(source.contains('craft.call("refuel_afterburner_full")'), "Atlas rearm should refill afterburner reserve")

func _test_presentation() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		var text := project.get_as_text()
		_expect(text.contains('AfterburnerCueDirector="*res://scripts/afterburner_cue_director.gd"'), "afterburner presentation should remain autoloaded")
		_expect(text.contains('RetroSfxDirector="*res://scripts/retro_sfx_director.gd"'), "procedural retro SFX should remain autoloaded")
	var cue := FileAccess.open("res://scripts/afterburner_cue_director.gd", FileAccess.READ)
	_expect(cue != null, "afterburner cue should be readable")
	if cue != null:
		var source := cue.get_as_text()
		_expect(source.contains('PixelFont.draw_text(surface, "AB"'), "afterburner cue should expose a compact fuel meter")
		_expect(source.contains("func _draw_flame"), "afterburner cue should expose engine flame while active")
		_expect(not source.contains("Label.new()") and not source.contains("ProgressBar.new()"), "afterburner presentation should remain pixel-canvas based")

func _test_retro_sfx() -> void:
	_expect(RetroSfxRules.event_for_weapon("needle_rail") == RetroSfxRules.FIRE_RAIL, "Needle Rail should retain kinetic SFX identity")
	_expect(RetroSfxRules.event_for_weapon("storm_cannon") == RetroSfxRules.FIRE_STORM, "Storm should retain directed-energy SFX identity")
	_expect(RetroSfxRules.event_for_weapon("plasma_lance") == RetroSfxRules.FIRE_PLASMA, "Plasma Lance should retain strategic SFX identity")
	_expect(RetroSfxRules.event_for_projectile({"support":true}, "storm_cannon") == RetroSfxRules.FIRE_SUPPORT, "tactical projectiles should not sound like equipped primary")
	_expect(RetroSfxRules.event_for_projectile({"support":true,"strategic_support":true}, "storm_cannon") == RetroSfxRules.FIRE_STRATEGIC, "strategic projectile should override ordinary support SFX")
	for event_id in [RetroSfxRules.FIRE_BALLISTIC,RetroSfxRules.FIRE_RAIL,RetroSfxRules.FIRE_STORM,RetroSfxRules.FIRE_PLASMA,RetroSfxRules.FIRE_SUPPORT,RetroSfxRules.FIRE_STRATEGIC,RetroSfxRules.TRANSFORM,RetroSfxRules.AFTERBURNER,RetroSfxRules.MISSILE_WARNING,RetroSfxRules.ALTITUDE_SHIFT]:
		_expect(RetroSfxRules.valid_voice(RetroSfxRules.voice(event_id)), "%s should have a bounded procedural voice" % event_id)
	var file := FileAccess.open("res://scripts/retro_sfx_director.gd", FileAccess.READ)
	_expect(file != null, "retro SFX director should be readable")
	if file != null:
		var source := file.get_as_text()
		_expect(source.contains("const MIX_RATE := 22050.0"), "procedural GDScript audio should remain at 22.05 kHz")
		_expect(source.contains("MAX_VOICES := 8"), "procedural voice count should remain bounded")
		_expect(source.contains("ThreatWarningRules.warning_level"), "missile warning SFX should consume the same live threat rules as HUD")
		_expect(source.contains("RetroSfxRules.event_for_projectile"), "shot SFX should inspect projectile metadata")
		_expect(source.contains("get_frames_available()") and source.contains("push_frame"), "SFX should use supported AudioStreamGenerator playback API")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
