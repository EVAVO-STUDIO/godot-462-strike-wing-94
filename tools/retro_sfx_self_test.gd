extends SceneTree

const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")

var failures: Array[String] = []

class EnemyBoomFixture:
	extends RefCounted
	var enemies: Array = []
	var enemy_missiles_launched := 0

func _initialize() -> void:
	_test_voice_map()
	_test_runtime_wiring()
	_test_startup_cues()
	if failures.is_empty():
		print("Strike Wing retro SFX self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_voice_map() -> void:
	_expect(RetroSfxRules.event_for_weapon("twin_cannon_mk1") == RetroSfxRules.FIRE_BALLISTIC, "conventional primaries should use ballistic voice")
	_expect(RetroSfxRules.event_for_weapon("needle_rail") == RetroSfxRules.FIRE_RAIL, "Needle Rail should use kinetic rail voice")
	_expect(RetroSfxRules.event_for_weapon("storm_cannon") == RetroSfxRules.FIRE_STORM, "Storm Cannon should use directed-energy pulse voice")
	_expect(RetroSfxRules.event_for_weapon("plasma_lance") == RetroSfxRules.FIRE_PLASMA, "Plasma Lance should use strategic plasma voice")
	for event_id in [RetroSfxRules.FIRE_BALLISTIC, RetroSfxRules.FIRE_RAIL, RetroSfxRules.FIRE_STORM, RetroSfxRules.FIRE_PLASMA, RetroSfxRules.TRANSFORM, RetroSfxRules.TRANSFORM_READY, RetroSfxRules.AFTERBURNER, RetroSfxRules.SONIC_BOOM, RetroSfxRules.MISSILE_WARNING, RetroSfxRules.MISSILE_LAUNCH, RetroSfxRules.SEEKER_LOCK, RetroSfxRules.COUNTERMEASURE, RetroSfxRules.UI_PURCHASE, RetroSfxRules.UI_SERVICE, RetroSfxRules.REWARD_STINGER, RetroSfxRules.SHIELD_HIT, RetroSfxRules.SHIELD_BREAK, RetroSfxRules.PLAYER_HIT, RetroSfxRules.ALTITUDE_SHIFT]:
		var voice := RetroSfxRules.voice(event_id)
		_expect(RetroSfxRules.valid_voice(voice), "%s should define bounded procedural voice" % event_id)
		_expect(float(voice.get("duration", 9.0)) <= 0.5, "%s should remain a short arcade SFX" % event_id)
		_expect(float(voice.get("gain", 9.0)) <= 0.30, "%s should remain below hard procedural gain cap" % event_id)
	_expect(str(RetroSfxRules.voice(RetroSfxRules.FIRE_RAIL).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.FIRE_PLASMA).get("wave", "")), "rail and plasma should not collapse to the same oscillator identity")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.UI_PURCHASE).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.REWARD_STINGER).get("wave", "")), "sortie-bay confirmation should remain distinct from the mission-clear stinger")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.SHIELD_HIT).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.PLAYER_HIT).get("wave", "")), "field contact should sound materially different from a physical hull strike")
	var cruise := RetroSfxRules.propulsion_bed(false, false, "mid")
	var burn := RetroSfxRules.propulsion_bed(true, false, "mid")
	var high_hypersonic := RetroSfxRules.propulsion_bed(true, true, "high")
	var low_hypersonic_dive := RetroSfxRules.propulsion_bed(true, true, "low", -1)
	_expect(float(burn.get("gain", 0.0)) > float(cruise.get("gain", 0.0)), "afterburner should materially strengthen the continuous propulsion bed")
	_expect(float(high_hypersonic.get("airflow", 0.0)) > float(burn.get("airflow", 0.0)), "hypersonic flight should add sustained high-speed airflow")
	_expect(float(low_hypersonic_dive.get("gain", 0.0)) > float(high_hypersonic.get("gain", 0.0)), "low-altitude hypersonic dives should sound more dangerous than high-altitude cruise")
	_expect(float(low_hypersonic_dive.get("gain", 9.0)) <= 0.10 and float(low_hypersonic_dive.get("airflow", 9.0)) <= 0.85, "continuous propulsion targets should remain bounded below combat SFX")
	var title_bed := RetroSfxRules.title_propulsion_bed()
	_expect(float(title_bed.get("gain", 0.0)) > 0.0 and float(title_bed.get("gain", 9.0)) < float(cruise.get("gain", 0.0)), "title turbine should be audible but more restrained than in-flight propulsion")
	_expect(RetroSfxRules.valid_voice(RetroSfxRules.voice(RetroSfxRules.TITLE_RADAR)), "title radar should define a bounded electronic cue")

func _test_runtime_wiring() -> void:
	var director_script := load("res://scripts/retro_sfx_director.gd") as Script
	var director: Node = director_script.new()
	var fixture := EnemyBoomFixture.new()
	fixture.enemy_missiles_launched = 2
	director.call("_observe_enemy_missile_launch", fixture)
	_expect(director.get("_voices").size() == 1, "enemy missile salvo should queue one distinct launch voice")
	director.call("_observe_enemy_missile_launch", fixture)
	_expect(director.get("_voices").size() == 1, "observing the same launch serial should not duplicate its voice")
	fixture.enemy_missiles_launched = 4
	director.call("_observe_enemy_missile_launch", fixture)
	_expect(director.get("_voices").size() == 2, "later missile salvos should trigger a new launch voice")
	fixture.enemies = [{"hypersonic_boom_age":0.01}]
	director.call("_observe_enemy_hypersonic_boom", fixture)
	_expect(director.get("_voices").size() == 3, "fresh enemy pursuit break should queue one sonic boom")
	director.call("_observe_enemy_hypersonic_boom", fixture)
	_expect(director.get("_voices").size() == 3, "one enemy shockwave should not retrigger on successive render frames")
	fixture.enemies = [{"hypersonic_boom_age":1.0}]
	director.call("_observe_enemy_hypersonic_boom", fixture)
	fixture.enemies = [{"hypersonic_boom_age":0.01}]
	director.call("_observe_enemy_hypersonic_boom", fixture)
	_expect(director.get("_voices").size() == 4, "later interceptor pursuit break should be able to trigger a new sonic boom")
	director.free()
	var file := FileAccess.open("res://scripts/retro_sfx_director.gd", FileAccess.READ)
	_expect(file != null, "retro SFX director should be readable")
	if file != null:
		var source := file.get_as_text()
		_expect(source.contains("const MIX_RATE := 22050.0"), "GDScript procedural audio should remain at 22.05 kHz")
		_expect(source.contains("AudioStreamGenerator.new()"), "retro SFX should use Godot procedural generator")
		_expect(source.contains("get_frames_available()") and source.contains("push_frame"), "procedural playback should use supported generator buffer API")
		_expect(source.contains("MAX_VOICES := 8"), "procedural audio voice count should stay bounded")
		_expect(source.contains("_noise_state"), "noise voice should use deterministic local noise state rather than global RNG")
		_expect(source.contains("afterburner_active") and source.contains("MISSILE"), "SFX observer should cover afterburner and missile-warning events")
		_expect(source.contains("transform_ready_serial") and source.contains("RetroSfxRules.TRANSFORM_READY"), "mechanical settle should receive a distinct ready latch after the actuator sweep")
		_expect(source.contains("_observe_enemy_hypersonic_boom") and source.contains('enemy.get("hypersonic_boom_age"') and source.contains("_enemy_boom_latched"), "enemy interceptor shockwaves should trigger one bounded sonic boom per pursuit break")
		_expect(source.contains("_observe_enemy_missile_launch") and source.contains("enemy_missiles_launched") and source.contains("MISSILE_LAUNCH"), "enemy missiles should use a distinct launch voice driven by an authoritative launch counter")
		_expect(source.contains("_update_propulsion_target") and source.contains("_propulsion_target_gain") and source.contains("_propulsion_phase"), "gameplay should sustain a smoothed procedural propulsion bed instead of relying on ignition one-shots")
		_expect(source.contains("_observe_startup_sequence") and source.contains("RetroSfxRules.title_propulsion_bed()"), "HYPERSONIC reveal should own a restrained continuous turbine bed")
		_expect(source.contains("title_elapsed >= 0.45") and source.contains("TITLE_RADAR"), "title reveal should time its subtle radar cue to the moving cloud exposure")
		_expect(source.contains("title_elapsed >= 3.15") and source.contains("title_elapsed >= 3.72"), "title mechanical sweep and ignition sounds should match their authored visual beats")
	var project := FileAccess.open("res://project.godot", FileAccess.READ)
	_expect(project != null, "project.godot should be readable")
	if project != null:
		_expect(project.get_as_text().contains('RetroSfxDirector="*res://scripts/retro_sfx_director.gd"'), "procedural SFX owner should remain autoloaded")
	var gameplay_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(gameplay_source.contains("var enemy_missiles_launched := 0") and gameplay_source.contains("_register_enemy_missile_launch(2)"), "ordinary interceptor missile pairs should advance the authoritative launch counter")
	_expect(gameplay_source.contains("RetroSfxRules.UI_PURCHASE") and gameplay_source.contains("RetroSfxRules.UI_SERVICE") and gameplay_source.contains("RetroSfxRules.REWARD_STINGER"), "weapon, generator, servicing and mission-clear transactions should publish authored audio feedback")
	var airframe_source := FileAccess.get_file_as_string("res://scripts/airframe_director.gd")
	var support_source := FileAccess.get_file_as_string("res://scripts/support_director.gd")
	_expect(airframe_source.contains("RetroSfxRules.UI_PURCHASE") and support_source.contains("RetroSfxRules.UI_PURCHASE"), "airframe and tactical-system purchases should share the sortie-bay confirmation language")

func _test_startup_cues() -> void:
	var director_script := load("res://scripts/retro_sfx_director.gd") as Script
	var director: Node = director_script.new()
	director.call("_observe_startup_state", 2, 0.50)
	_expect(float(director.get("_propulsion_target_gain")) > 0.0, "HYPERSONIC reveal should engage the low turbine bed")
	_expect(director.get("_voices").size() == 1, "first title exposure should queue one radar cue")
	director.call("_observe_startup_state", 2, 3.20)
	_expect(director.get("_voices").size() == 2, "wing motion should queue one mechanical sweep cue")
	director.call("_observe_startup_state", 2, 3.80)
	director.call("_observe_startup_state", 2, 3.80)
	_expect(director.get("_voices").size() == 3, "engine flare should queue one ignition cue without retriggering")
	director.call("_observe_startup_state", 0, 0.0)
	_expect(is_zero_approx(float(director.get("_propulsion_target_gain"))), "approved EVAVO splash should remain free of the HYPERSONIC turbine bed")
	director.free()

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
