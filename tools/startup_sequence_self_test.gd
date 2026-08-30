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
	var wordmark := load("res://assets/runtime/title/hypersonic_wordmark_v1.png")
	_expect(wordmark is Texture2D and wordmark.get_size() == Vector2(500,64), "HYPERSONIC wordmark should retain reviewed runtime geometry", failures)
	for form_name in ["fighter", "bomber"]:
		var craft := load("res://assets/runtime/craft/vx94/vx94_%s_v1.png" % form_name)
		_expect(craft is Texture2D and craft.get_size() == Vector2(64,72), "VX-94 %s form should retain reviewed 64x72 geometry" % form_name, failures)
	var source_file := FileAccess.open("res://scripts/startup_sequence_director.gd", FileAccess.READ)
	_expect(source_file != null, "startup sequence source should be readable", failures)
	if source_file != null:
		var source := source_file.get_as_text()
		for token in ["EVAVO_SPLASH", "EVAVO_SPARKLE_FRAMES", "HYPERSONIC_WORDMARK", "VX94_FIGHTER", "VX94_BOMBER", "BLACK_PAUSE", "PRESS FIRE / PRESS START", "_draw_vx94_forms"]:
			_expect(source.contains(token), "startup sequence missing production cue: %s" % token, failures)
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
