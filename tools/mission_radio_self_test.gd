extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var radio := root.get_node_or_null("MissionRadioDirector")
	_expect(radio != null, "mission radio presentation should be autoloaded", failures)
	var source := _source("res://scripts/mission_radio_director.gd")
	for token in ["current_briefing", "boss_spawned", "status_text", "egress_active", "BREAK THE MACH GATE", "COASTWATCH", "ORACLE", "SKYWARD", "subtitles_enabled", "RADIO_TX", "RADIO_ALERT", "RX //"]:
		_expect(source.contains(token), "mission radio missing production contract: %s" % token, failures)
	_expect(source.contains("RADIO_STRIP") and source.contains("Rect2(16, 337, 608, 18)"), "combat radio should use a compact authored edge strip instead of a lower-playfield dialogue box", failures)
	_expect(source.contains("func _flight_warning_active()") and source.contains("LOW ALT OVERSPEED") and source.contains("HULL CRITICAL"), "flight-critical warnings should preempt routine radio traffic in the shared status lane", failures)
	_expect(source.contains("func occupies_status_lane") and source.contains("not _message.is_empty() and _subtitles_enabled()"), "visible radio subtitles should publish ownership of the shared lower status lane", failures)
	_expect(source.contains("_capture_time() > INTRO_DELAY + INTRO_SECONDS"), "mid-mission visual QA must not replay the launch briefing", failures)
	_expect(not source.contains("Rect2(18, 263, 292, 43)"), "obsolete oversized combat radio panel should remain removed", failures)
	_expect(not source.contains('scene.set(') and not source.contains("CampaignSave"), "mission radio must remain presentation-only", failures)
	var rules := _source("res://scripts/retro_sfx_rules.gd")
	_expect(rules.contains('"wave":"radio"') and rules.contains("RADIO_TX") and rules.contains("RADIO_ALERT"), "radio events should use bounded original procedural transceiver cues", failures)
	var sfx := _source("res://scripts/retro_sfx_director.gd")
	_expect(sfx.contains("RetroSfxRules.RADIO_TX") and sfx.contains("_radio_gain"), "radio cues should obey the dedicated radio mixer level", failures)
	if failures.is_empty(): print("HYPERSONIC mission radio self-test passed."); quit(0); return
	for failure in failures: push_error(failure)
	quit(1)

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition: failures.append(message)
