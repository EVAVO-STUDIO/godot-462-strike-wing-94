extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var radio := root.get_node_or_null("MissionRadioDirector")
	_expect(radio != null, "mission radio presentation should be autoloaded", failures)
	var source := _source("res://scripts/mission_radio_director.gd")
	for token in ["current_briefing", "boss_spawned", "status_text", "COASTWATCH", "ORACLE", "SKYWARD", "subtitles_enabled", "RADIO_TX", "RADIO_ALERT", "RX //"]:
		_expect(source.contains(token), "mission radio missing production contract: %s" % token, failures)
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
