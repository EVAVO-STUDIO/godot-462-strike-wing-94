extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var startup := root.get_node_or_null("StartupSequenceDirector")
	_expect(startup != null, "startup sequence autoload should exist", failures)
	if startup != null:
		_expect(float(startup.EVAVO_READABLE_SECONDS) >= 1.0, "EVAVO identity should remain readable before skip", failures)
		_expect(float(startup.BLACK_PAUSE_SECONDS) >= 0.3, "publisher and title sequences should have a black pause", failures)
		_expect(float(startup.TITLE_TOTAL_SECONDS) >= 8.0 and float(startup.TITLE_TOTAL_SECONDS) <= 15.0, "HYPERSONIC title sequence should meet the 8-15 second contract", failures)
	var splash := load("res://assets/runtime/brand/front_door_raw_art_v1/evavo_splash_plate_v1.png")
	_expect(splash is Texture2D and splash.get_size() == Vector2(640,360), "approved EVAVO plate should retain canonical 640x360 geometry", failures)
	var wordmark := load("res://assets/runtime/title/hypersonic_wordmark_v2.png")
	_expect(wordmark is Texture2D and wordmark.get_size() == Vector2(500,64), "HYPERSONIC wordmark should retain reviewed runtime geometry", failures)
	if wordmark is Texture2D:
		var wordmark_image: Image = (wordmark as Texture2D).get_image()
		_expect(wordmark_image.detect_alpha() != Image.ALPHA_NONE and wordmark_image.get_pixel(0,0).a <= 0.01, "HYPERSONIC wordmark should retain a genuinely transparent exterior", failures)
	var manifest_file := FileAccess.open("res://assets/source/title/title_asset_manifest.json", FileAccess.READ)
	_expect(manifest_file != null, "HYPERSONIC title-art manifest should remain readable", failures)
	if manifest_file != null:
		var manifest = JSON.parse_string(manifest_file.get_as_text())
		_expect(typeof(manifest) == TYPE_DICTIONARY and str(manifest.get("status", "")) == "runtime_master_v2_approved", "HYPERSONIC wordmark should remain an approved production master", failures)
		if typeof(manifest) == TYPE_DICTIONARY:
			var master: Dictionary = manifest.get("master", {})
			var acceptance: Dictionary = master.get("acceptance", {})
			_expect(int(acceptance.get("palette_colors", 0)) <= 32, "title master should retain its restrained late-90s palette", failures)
	for frame_path in ["vx94_fighter_v1.png", "vx94_transform_01.png", "vx94_transform_02.png", "vx94_transform_03.png", "vx94_bomber_v1.png"]:
		var craft := load("res://assets/runtime/craft/vx94/%s" % frame_path)
		_expect(craft is Texture2D and craft.get_size() == Vector2(64,72), "VX-94 transform frame %s should retain reviewed 64x72 geometry" % frame_path, failures)
	var source_file := FileAccess.open("res://scripts/startup_sequence_director.gd", FileAccess.READ)
	_expect(source_file != null, "startup sequence source should be readable", failures)
	if source_file != null:
		var source := source_file.get_as_text()
		for token in ["EVAVO_SPLASH", "EVAVO_SPARKLE_FRAMES", "HYPERSONIC_WORDMARK", "VX94_FIGHTER", "VX94_BOMBER", "VX94_TRANSFORM_FRAMES", "TITLE_SKY", "TITLE_CLOUDS", "PersistentEffectArtLibrary", "BLACK_PAUSE", "PRESS FIRE / PRESS START", "_draw_vx94_forms"]:
			_expect(source.contains(token), "startup sequence missing production cue: %s" % token, failures)
		_expect(source.contains("Rect2(70, 42, 500, 64)"), "approved wordmark should retain its canonical title-screen placement", failures)
		_expect(source.contains('identity.call("title_subtitle")'), "title subtitle should remain centralized through ProductIdentity", failures)
		_expect(source.contains("PixelFont.draw_centered(surface, subtitle"), "VX-94 subtitle should remain visually subordinate to the raster wordmark", failures)
		_expect(source.contains('frame_for_ratio("afterburner"'), "title-sequence ignition should use the authored twin-engine compression plume", failures)
		_expect(source.contains("fposmod(-source_y"), "title cloud deck should travel forward with the gameplay world instead of running backward", failures)
		_expect(source.contains("--capture-startup=") and source.contains('"evavo_ident"') and source.contains('"vx94_transform"') and source.contains('"title_prompt"'), "startup presentation should expose deterministic EVAVO, transform and final-title visual fixtures", failures)
		_expect(not source.contains("func _draw_cloud_wisp") and not source.contains("surface.draw_circle(Vector2(320, craft_y"), "title atmosphere should not regress to polygon wisps or a circular engine flare", failures)
	var sfx_source := FileAccess.get_file_as_string("res://scripts/retro_sfx_director.gd")
	_expect(sfx_source.contains("_observe_startup_sequence") and sfx_source.contains("title_propulsion_bed"), "title reveal should include its specified low turbine rumble", failures)
	_expect(sfx_source.contains("TITLE_RADAR") and sfx_source.contains("RetroSfxRules.TRANSFORM") and sfx_source.contains("RetroSfxRules.AFTERBURNER"), "title radar, wing sweep, and ignition audio should be synchronized to the visual sequence", failures)
	if failures.is_empty():
		print("HYPERSONIC startup sequence self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
