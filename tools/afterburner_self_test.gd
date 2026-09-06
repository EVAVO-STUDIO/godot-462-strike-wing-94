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
	_expect(source.contains("_afterburner_burn_rate()"), "afterburner should use form/altitude efficiency instead of flat drain")
	_expect(source.contains("AltitudeRules.LOW") and source.contains("AltitudeRules.ORBITAL"), "afterburner burn rate should react to altitude envelope")
	_expect(source.contains("func refuel_afterburner_full()"), "craft should expose explicit tanker refuel API")
	_expect(source.contains('_add_key_action("afterburner", KEY_SHIFT)'), "afterburner should bind to Shift")

func _test_tanker_refuel_wiring() -> void:
	var file := FileAccess.open("res://scripts/support_director.gd", FileAccess.READ)
	_expect(file != null, "support director should be readable for tanker refuel")
	if file == null: return
	var source := file.get_as_text()
	_expect(source.contains('craft.call("refuel_afterburner_full")'), "Atlas rearm should refill afterburner reserve")

func _test_presentation() -> void:
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		var text := project.get_as_text()
		_expect(text.contains('AfterburnerCueDirector="*res://scripts/afterburner_cue_director.gd"'), "afterburner presentation should remain autoloaded")
		_expect(text.contains('RetroSfxDirector="*res://scripts/retro_sfx_director.gd"'), "procedural retro SFX should remain autoloaded")
		_expect(text.contains('AltitudeTransitionDirector="*res://scripts/altitude_transition_director.gd"'), "altitude transition presentation should remain autoloaded")
		_expect(text.contains('PlayerMountDirector="*res://scripts/player_mount_director.gd"'), "canonical mount owner should remain available before audio presentation")

func _test_retro_sfx() -> void:
	_expect(RetroSfxRules.event_for_primary("twin_cannon_mk1", true) == RetroSfxRules.FIRE_ROTARY, "bomber conventional gun should use rotary SFX")
	_expect(RetroSfxRules.event_for_primary("twin_cannon_mk1", false) == RetroSfxRules.FIRE_BALLISTIC, "fighter conventional gun should retain sharper ballistic SFX")
	_expect(RetroSfxRules.event_for_weapon("needle_rail") == RetroSfxRules.FIRE_RAIL, "Needle Rail should retain kinetic SFX identity")
	_expect(RetroSfxRules.event_for_weapon("storm_cannon") == RetroSfxRules.FIRE_STORM, "Storm should retain directed-energy SFX identity")
	_expect(RetroSfxRules.event_for_weapon("plasma_lance") == RetroSfxRules.FIRE_PLASMA, "Plasma Lance should retain strategic SFX identity")
	_expect(RetroSfxRules.altitude_event(1) == RetroSfxRules.ALTITUDE_CLIMB, "climb should have rising transition voice")
	_expect(RetroSfxRules.altitude_event(-1) == RetroSfxRules.ALTITUDE_DIVE, "dive should have falling transition voice")
	for event_id in [RetroSfxRules.FIRE_BALLISTIC,RetroSfxRules.FIRE_ROTARY,RetroSfxRules.FIRE_RAIL,RetroSfxRules.FIRE_STORM,RetroSfxRules.FIRE_PLASMA,RetroSfxRules.FIRE_SUPPORT,RetroSfxRules.FIRE_STRATEGIC,RetroSfxRules.TRANSFORM,RetroSfxRules.AFTERBURNER,RetroSfxRules.MISSILE_WARNING,RetroSfxRules.ALTITUDE_CLIMB,RetroSfxRules.ALTITUDE_DIVE,RetroSfxRules.HIT,RetroSfxRules.EXPLOSION,RetroSfxRules.BOSS_EXPLOSION,RetroSfxRules.SHIELD_HIT,RetroSfxRules.SHIELD_BREAK,RetroSfxRules.PLAYER_HIT]:
		_expect(RetroSfxRules.valid_voice(RetroSfxRules.voice(event_id)), "%s should have a bounded procedural voice" % event_id)
	var file := FileAccess.open("res://scripts/retro_sfx_director.gd", FileAccess.READ)
	_expect(file != null, "retro SFX director should be readable")
	if file != null:
		var source := file.get_as_text()
		_expect(source.contains("const MIX_RATE := 22050.0"), "procedural GDScript audio should remain at 22.05 kHz")
		_expect(source.contains("ROTARY_RETRIGGER_SECONDS := 0.09"), "bomber rotary should use bounded retrigger gate instead of stacking one-shot voices")
		_expect(source.contains('event_id == RetroSfxRules.FIRE_ROTARY'), "rotary retrigger gate should apply only to bomber rotary voice")
		_expect(source.contains('get_node_or_null("/root/PlayerMountDirector")'), "rotary SFX should identify deployment through canonical mount owner")
		_expect(source.contains('mounts.call("bomber_rotary_deployed"'), "audio should use the same bomber rotary mount contract as art")
		_expect(source.contains("ThreatWarningRules.warning_level"), "missile warning SFX should consume the same live threat rules as HUD")
	var cue_file := FileAccess.open("res://scripts/afterburner_cue_director.gd", FileAccess.READ)
	if cue_file != null:
		var cue_source := cue_file.get_as_text()
		_expect(cue_source.contains("PROPULSION_HYPERSONIC") and cue_source.contains("hypersonic_charge_ratio") and cue_source.contains("PROPULSION_RESERVE_LOW"), "propulsion HUD should expose authored fuel, spool and latched-speed states")
		_expect(cue_source.contains('"MACH" if hypersonic') and cue_source.contains('"GEOM" if burning else "THR"') and cue_source.contains("throttle * 100.0"), "compact propulsion HUD should expose throttle, geometry spool and distinct Mach states")
		_expect(cue_source.contains("LOWER_LEFT_KEEP_OUT") and cue_source.contains("640.0 - LOWER_HUD_MARGIN - float(frame.get_width())"), "propulsion instrument should move to the opposite lower corner before the VX-94 can occlude it")
		_expect(cue_source.contains('"hypersonic_blue_plume"') and cue_source.contains("ENGINE_MOUNTS") and cue_source.contains("propulsion_bank_frame_index"), "hypersonic thrust should use paired blue plumes registered to both engine outlets across bank poses")
		_expect(cue_source.contains('"hypersonic_engine_burst"') and cue_source.contains('"hypersonic_engine_ring"') and cue_source.contains("ENGINE_BURST_FRAME_ENDS") and not cue_source.contains("draw_circle"), "hypersonic entry should use authored engine burst and circular pressure-ring sequences")
		_expect(cue_source.contains("_flash_scale()") and cue_source.contains("reduced_flashes"), "hypersonic pressure cues should honor reduced-flashes accessibility")
	for index in 4:
		var plume := load("res://assets/runtime/effects/persistent/hypersonic_blue_plume/%d.png" % index)
		_expect(plume is Texture2D and plume.get_size() == Vector2(16,40), "blue plume should retain registered 16x40 canvas: %d" % index)
	for index in 6:
		var burst := load("res://assets/runtime/effects/persistent/hypersonic_engine_burst/%d.png" % index)
		_expect(burst is Texture2D and burst.get_size() == Vector2(112,40), "engine burst should retain registered 112x40 canvas: %d" % index)
	for propulsion_asset in ["normal","burning","reserve_low","hypersonic_latched"]:
		var propulsion_frame := load("res://assets/runtime/ui/hud/propulsion_instrument/%s.png" % propulsion_asset)
		_expect(propulsion_frame is Texture2D and propulsion_frame.get_size() == Vector2(196,13), "propulsion instrument state should retain registered geometry: %s" % propulsion_asset)
	for propulsion_fill in ["fuel_fill","charge_fill"]:
		var fill_texture := load("res://assets/runtime/ui/hud/propulsion_instrument/%s.png" % propulsion_fill)
		_expect(fill_texture is Texture2D and fill_texture.get_size() == Vector2(64,4), "propulsion instrument fill should retain registered geometry: %s" % propulsion_fill)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
