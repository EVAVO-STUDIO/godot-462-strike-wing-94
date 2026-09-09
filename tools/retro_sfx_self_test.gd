extends SceneTree

const RetroSfxRules = preload("res://scripts/retro_sfx_rules.gd")
const RetroSfxPriorityRules = preload("res://scripts/retro_sfx_priority_rules.gd")

var failures: Array[String] = []

class EnemyBoomFixture:
	extends RefCounted
	var enemies: Array = []
	var enemy_missiles_launched := 0

func _initialize() -> void:
	_test_voice_map()
	_test_priority_allocator()
	_test_runtime_wiring()
	_test_startup_cues()
	_test_cinematic_cues()
	if failures.is_empty():
		print("HYPERSONIC retro SFX self-test passed.")
		quit(0)
		return
	for failure in failures: push_error(failure)
	quit(1)

func _test_voice_map() -> void:
	_expect(RetroSfxRules.event_for_weapon("twin_cannon_mk1") == RetroSfxRules.FIRE_BALLISTIC, "conventional primaries should use ballistic voice")
	_expect(RetroSfxRules.event_for_weapon("needle_rail") == RetroSfxRules.FIRE_RAIL, "Needle Rail should use kinetic rail voice")
	_expect(RetroSfxRules.event_for_weapon("storm_cannon") == RetroSfxRules.FIRE_STORM, "Storm Cannon should use directed-energy pulse voice")
	_expect(RetroSfxRules.event_for_weapon("plasma_lance") == RetroSfxRules.FIRE_PLASMA, "Plasma Lance should use strategic plasma voice")
	for event_id in [RetroSfxRules.FIRE_BALLISTIC, RetroSfxRules.FIRE_RAIL, RetroSfxRules.FIRE_STORM, RetroSfxRules.FIRE_PLASMA, RetroSfxRules.TRANSFORM, RetroSfxRules.TRANSFORM_READY, RetroSfxRules.AFTERBURNER, RetroSfxRules.SONIC_BOOM, RetroSfxRules.MISSILE_WARNING, RetroSfxRules.MISSILE_LAUNCH, RetroSfxRules.SEEKER_LOCK, RetroSfxRules.COUNTERMEASURE, RetroSfxRules.UI_PURCHASE, RetroSfxRules.UI_SERVICE, RetroSfxRules.REWARD_STINGER, RetroSfxRules.SHIELD_HIT, RetroSfxRules.SHIELD_BREAK, RetroSfxRules.PLAYER_HIT, RetroSfxRules.ALTITUDE_SHIFT, RetroSfxRules.CINEMATIC_ENGINE_IGNITION, RetroSfxRules.CINEMATIC_CATAPULT]:
		var voice := RetroSfxRules.voice(event_id)
		_expect(RetroSfxRules.valid_voice(voice), "%s should define bounded procedural voice" % event_id)
		_expect(float(voice.get("duration", 9.0)) <= 0.5, "%s should remain a short arcade SFX" % event_id)
		_expect(float(voice.get("gain", 9.0)) <= 0.30, "%s should remain below hard procedural gain cap" % event_id)
	_expect(str(RetroSfxRules.voice(RetroSfxRules.FIRE_RAIL).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.FIRE_PLASMA).get("wave", "")), "rail and plasma should not collapse to the same oscillator identity")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.UI_PURCHASE).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.REWARD_STINGER).get("wave", "")), "sortie-bay confirmation should remain distinct from the mission-clear stinger")
	_expect(str(RetroSfxRules.voice(RetroSfxRules.SHIELD_HIT).get("wave", "")) != str(RetroSfxRules.voice(RetroSfxRules.PLAYER_HIT).get("wave", "")), "field contact should sound materially different from a physical hull strike")
	var cruise := RetroSfxRules.propulsion_bed(false, false, "mid")
	var idle := RetroSfxRules.propulsion_bed(false,false,"mid",0,0.0)
	var military := RetroSfxRules.propulsion_bed(false,false,"mid",0,1.0)
	var burn := RetroSfxRules.propulsion_bed(true, false, "mid")
	var high_hypersonic := RetroSfxRules.propulsion_bed(true, true, "high")
	var low_hypersonic_dive := RetroSfxRules.propulsion_bed(true, true, "low", -1)
	_expect(float(burn.get("gain", 0.0)) > float(cruise.get("gain", 0.0)), "afterburner should materially strengthen the continuous propulsion bed")
	_expect(float(military.get("gain",0.0))>float(idle.get("gain",0.0)) and float(military.get("frequency",0.0))>float(idle.get("frequency",0.0)) and float(military.get("airflow",0.0))>float(idle.get("airflow",0.0)), "dry propulsion sound should rise continuously from idle to military power")
	_expect(float(high_hypersonic.get("airflow", 0.0)) > float(burn.get("airflow", 0.0)), "hypersonic flight should add sustained high-speed airflow")
	_expect(float(low_hypersonic_dive.get("gain", 0.0)) > float(high_hypersonic.get("gain", 0.0)), "low-altitude hypersonic dives should sound more dangerous than high-altitude cruise")
	_expect(float(low_hypersonic_dive.get("gain", 9.0)) <= 0.10 and float(low_hypersonic_dive.get("airflow", 9.0)) <= 0.85, "continuous propulsion targets should remain bounded below combat SFX")
	var title_bed := RetroSfxRules.title_propulsion_bed()
	_expect(float(title_bed.get("gain", 0.0)) > 0.0 and float(title_bed.get("gain", 9.0)) < float(cruise.get("gain", 0.0)), "title turbine should be audible but more restrained than in-flight propulsion")
	_expect(RetroSfxRules.valid_voice(RetroSfxRules.voice(RetroSfxRules.TITLE_RADAR)), "title radar should define a bounded electronic cue")
	_expect(RetroSfxPriorityRules.priority(RetroSfxRules.MISSILE_WARNING) > RetroSfxPriorityRules.priority(RetroSfxRules.FIRE_BALLISTIC), "missile warning must outrank routine gunfire")
	_expect(RetroSfxPriorityRules.priority(RetroSfxRules.SHIELD_BREAK) >= RetroSfxPriorityRules.CRITICAL, "shield collapse must be a protected cockpit cue")
	_expect(RetroSfxPriorityRules.priority(RetroSfxRules.RADIO_ALERT) >= RetroSfxPriorityRules.CRITICAL, "priority command radio must be a protected cockpit cue")
	_expect(RetroSfxPriorityRules.priority(RetroSfxRules.CINEMATIC_ENGINE_IGNITION) == RetroSfxPriorityRules.TACTICAL, "carrier ignition should use the tactical voice tier")
	_expect(RetroSfxPriorityRules.priority(RetroSfxRules.CINEMATIC_CATAPULT) == RetroSfxPriorityRules.TACTICAL, "carrier catapult should use the tactical voice tier")
	_expect(RetroSfxPriorityRules.voice_duck(RetroSfxPriorityRules.ROUTINE, true) < 1.0, "critical cues should duck lower-priority voices")
	_expect(RetroSfxPriorityRules.voice_duck(RetroSfxPriorityRules.CRITICAL, true) == 1.0, "critical cues must not duck themselves")

func _test_priority_allocator() -> void:
	var director_script := load("res://scripts/retro_sfx_director.gd") as Script
	var director: Node = director_script.new()
	var source := FileAccess.get_file_as_string("res://scripts/retro_sfx_director.gd")
	_expect(source.contains('get_node_or_null("/root/RetroMusicDirector") if is_inside_tree() else null'), "critical cue admission should remain legal before scene attachment and during teardown")
	for _index in range(8):
		director.call("_trigger", RetroSfxRules.FIRE_BALLISTIC)
	_expect(director.get("_voices").size() == 8, "routine chatter should fill but not exceed the bounded eight-voice budget")
	director.call("_trigger", RetroSfxRules.MISSILE_WARNING)
	var voices: Array = director.get("_voices")
	_expect(voices.size() == 8, "critical warning admission must preserve the eight-voice cap")
	_expect(_voice_event_count(voices, RetroSfxRules.MISSILE_WARNING) == 1, "missile warning should evict routine chatter rather than being dropped")
	_expect(float(director.get("_critical_duck_timer")) > 0.0, "critical warning should open a bounded duck window")
	director.call("_trigger", RetroSfxRules.FIRE_BALLISTIC)
	voices = director.get("_voices")
	_expect(_voice_event_count(voices, RetroSfxRules.MISSILE_WARNING) == 1, "later routine gunfire must not evict a live missile warning")
	var all_critical: Array = []
	for _index in range(8):
		all_critical.append({"priority":RetroSfxPriorityRules.COMMAND})
	_expect(RetroSfxPriorityRules.eviction_index(all_critical, RetroSfxPriorityRules.ROUTINE, 8) == -2, "routine incoming audio should be rejected when every active slot has protected authority")
	_expect(RetroSfxPriorityRules.eviction_index(all_critical, RetroSfxPriorityRules.COMMAND, 8) == 0, "equal-priority protected cue may replace the oldest protected cue without growing the pool")
	director.free()

func _voice_event_count(voices: Array, event_id: String) -> int:
	var count := 0
	for voice in voices:
		if typeof(voice) == TYPE_DICTIONARY and str(voice.get("event_id", "")) == event_id:
			count += 1
	return count

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
		_expect(source.contains("RetroSfxPriorityRules.eviction_index") and source.contains("_critical_duck_timer"), "voice admission should preserve critical cockpit cues under dense combat")
		_expect(source.contains("RetroSfxPriorityRules.voice_duck") and source.contains("RetroSfxPriorityRules.propulsion_duck"), "critical cues should temporarily duck routine procedural chatter and propulsion")
		_expect(source.contains("_noise_state"), "noise voice should use deterministic local noise state rather than global RNG")
		_expect(source.contains("afterburner_active") and source.contains("MISSILE"), "SFX observer should cover afterburner and missile-warning events")
		_expect(source.contains("transform_ready_serial") and source.contains("RetroSfxRules.TRANSFORM_READY"), "mechanical settle should receive a distinct ready latch after the actuator sweep")
		_expect(source.contains("_observe_enemy_hypersonic_boom") and source.contains('enemy.get("hypersonic_boom_age"') and source.contains("_enemy_boom_latched"), "enemy interceptor shockwaves should trigger one bounded sonic boom per pursuit break")
		_expect(source.contains("_observe_enemy_missile_launch") and source.contains("enemy_missiles_launched") and source.contains("MISSILE_LAUNCH"), "enemy missiles should use a distinct launch voice driven by an authoritative launch counter")
		_expect(source.contains("_update_propulsion_target") and source.contains("_propulsion_target_gain") and source.contains("_propulsion_phase"), "gameplay should sustain a smoothed procedural propulsion bed instead of relying on ignition one-shots")
		_expect(source.contains("_propulsion_phase_right") and source.contains("_propulsion_rumble_phase") and source.contains("_propulsion_airflow_filtered"), "twin-engine propulsion should retain separated turbine phases, compressor rumble and filtered airflow")
		_expect(source.contains("Vector2(sample_left,sample_right)"), "propulsion should retain restrained twin-engine stereo separation instead of collapsing to a mono oscillator")
		_expect(source.contains("_observe_startup_sequence") and source.contains("RetroSfxRules.title_propulsion_bed()"), "HYPERSONIC reveal should own a restrained continuous turbine bed")
		_expect(source.contains('craft.call("throttle_ratio")') and source.contains("transition_direction,throttle"), "runtime propulsion audio should consume the same throttle command as route speed")
		_expect(source.contains("title_elapsed >= 0.45") and source.contains("TITLE_RADAR"), "title reveal should time its subtle radar cue to the moving cloud exposure")
		_expect(source.contains("title_elapsed >= 3.15") and source.contains("title_elapsed >= 3.72"), "title mechanical sweep and ignition sounds should match their authored visual beats")
	var priority_source := FileAccess.get_file_as_string("res://scripts/retro_sfx_priority_rules.gd")
	_expect(priority_source.contains("LOWER_PRIORITY_DUCK_GAIN") and priority_source.contains("eviction_index"), "audio priority policy should remain separate, deterministic and bounded")
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

func _test_cinematic_cues() -> void:
	var director_script := load("res://scripts/retro_sfx_director.gd") as Script
	var director: Node = director_script.new()
	var deck := {"active":true,"sequence_id":"sector_i_carrier_launch","shot_index":0,"bed":{"gain":0.032,"frequency":54.0,"airflow":0.16},"cue":RetroSfxRules.CINEMATIC_ENGINE_IGNITION}
	_expect(bool(director.call("_observe_cinematic_audio_state", deck)), "active cinematic audio should suppress gameplay observation")
	_expect(director.get("_voices").size() == 1, "carrier deck should queue one engine ignition cue")
	_expect(is_equal_approx(float(director.get("_propulsion_target_gain")), 0.032), "carrier deck should engage its authored turbine bed")
	director.call("_observe_cinematic_audio_state", deck)
	_expect(director.get("_voices").size() == 1, "holding one cinematic shot should not retrigger its cue")
	var airborne := {"active":true,"sequence_id":"sector_i_carrier_launch","shot_index":2,"bed":{"gain":0.048,"frequency":78.0,"airflow":0.34},"cue":RetroSfxRules.CINEMATIC_CATAPULT}
	director.call("_observe_cinematic_audio_state", airborne)
	_expect(director.get("_voices").size() == 2, "airborne cut should queue one catapult-release cue")
	_expect(str(director.get("_voices")[1].get("event_id", "")) == RetroSfxRules.CINEMATIC_CATAPULT, "airborne cue should retain its distinct catapult identity")
	_expect(not bool(director.call("_observe_cinematic_audio_state", {"active":false})), "inactive cinematic state should return control to gameplay observation")
	_expect(str(director.get("_last_cinematic_audio_key")) == "", "leaving a cinematic should clear its cue latch")
	director.free()

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
