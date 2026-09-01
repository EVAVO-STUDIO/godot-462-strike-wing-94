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
	for event_id in [RetroSfxRules.FIRE_BALLISTIC, RetroSfxRules.FIRE_RAIL, RetroSfxRules.FIRE_STORM, RetroSfxRules.FIRE_PLASMA, RetroSfxRules.TRANSFORM, RetroSfxRules.TRANSFORM_READY, RetroSfxRules.AFTERBURNER, RetroSfxRules.SONIC_BOOM, RetroSfxRules.MISSILE_WARNING, RetroSfxRules.MISSILE_LAUNCH, RetroSfxRules.UI_PURCHASE, RetroSfxRules.UI_SERVICE, RetroSfxRules.REWARD_STINGER, RetroSfxRules.SHIELD_HIT, RetroSfxRules.SHIELD_BREAK, RetroSfxRules.PLAYER_HIT, RetroSfxRules.ALTITUDE_SHIFT]:
		var voice := RetroSfxRules.voice(event_id)
		_expect(RetroSfxRules.valid_voice(voice), "%s should define bounded procedural voice" % event_id)
		_expect(float(voice.get("duration", 9.0)) <= 0.5, "%s should remain a short arcade SFX" % event_id)
		_expect(float(voice.get("gain", 9.0)) <= 0.30, "%s should remain below hard procedural gain cap" % event_id)
	_expect(str(RetroSfxRules.voice(RetroSfxRules.FIRE_RAIL).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.FIRE_PLASMA).get("wave", "")), "rail and plasma should not collapse to the same oscillator identity")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.UI_PURCHASE).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.REWARD_STINGER).get("wave", "")), "sortie-bay confirmation should remain distinct from the mission-clear stinger")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.SHIELD_HIT).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.PLAYER_HIT).get("wave", "")), "field contact should sound materially different from a physical hull strike")

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

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
