extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var attract := root.get_node_or_null("AttractModeDirector")
	_expect(attract != null, "attract mode autoload should exist", failures)
	if attract != null:
		_expect(float(attract.IDLE_SECONDS) >= 20.0, "attract mode should allow the main menu to settle", failures)
		_expect(float(attract.SHOW_SECONDS) >= 12.0, "demonstration should have a complete arcade presentation arc", failures)
	var file := FileAccess.open("res://scripts/attract_mode_director.gd", FileAccess.READ)
	_expect(file != null, "attract mode source should be readable", failures)
	if file != null:
		var source := file.get_as_text()
		for token in ["VX94_FRAMES", "sonic_boom", "afterburner", "MACHINE_ARK", "DEMONSTRATION", "NO CAMPAIGN DATA", "_draw_intercept", "_draw_hypersonic_break", "_draw_boss_engagement", "_draw_return_card"]:
			_expect(source.contains(token), "attract mode missing production cue: %s" % token, failures)
		_expect(not source.contains("CampaignSave") and not source.contains('scene.set('), "attract mode must remain isolated from campaign and game state", failures)
	if failures.is_empty():
		print("HYPERSONIC attract mode self-test passed.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
