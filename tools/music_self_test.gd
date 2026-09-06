extends SceneTree
const ContentCatalog=preload("res://scripts/content_catalog.gd")
const MusicRules=preload("res://scripts/music_rules.gd")
var failures:Array[String]=[]
func _initialize()->void:
	var data=ContentCatalog.load_json("res://data/music_tracks.json");var tracks:=MusicRules.sanitize_tracks(data.get("tracks",[]))
	_expect(tracks.size()==12,"twelve authored HYPERSONIC cues should validate")
	_expect(str(tracks[0].get("id"))=="hangar_signal" and str(tracks[1].get("id"))=="title_vector" and str(tracks[11].get("id"))=="after_action","music cue order should remain canonical")
	_expect(MusicRules.track_id_for(1,0)=="steel_vector" and MusicRules.track_id_for(1,1)=="salt_wake" and MusicRules.track_id_for(1,2)=="furnace_alarm","mercenary sorties should rotate three authored cue identities")
	_expect(MusicRules.track_id_for(1,10)=="dead_factory" and MusicRules.track_id_for(1,11)=="ghost_signal" and MusicRules.track_id_for(1,12)=="machine_pressure","machine-war routing should retain a separate three-cue vocabulary")
	_expect(MusicRules.track_id_for(1,20)=="ark_descent" and MusicRules.track_id_for(1,21)=="black_sky" and MusicRules.track_id_for(1,22)=="thin_blue","BLACK SKY routing should retain a separate three-cue vocabulary")
	_expect(MusicRules.track_id_for(0,12)=="hangar_signal" and MusicRules.track_id_for(2,12)=="after_action","front end and debrief should own separate cues")
	_expect(absf(MusicRules.midi_frequency(69)-440.0)<0.001,"tracker pitch conversion should retain concert reference")
	var director:Node=load("res://scripts/retro_music_director.gd").new();director.set("_tracks",tracks);director.set("_track",tracks[1])
	director.set("_track_id","title_vector");director.call("_load_arrangements")
	_expect(int(director.call("arrangement_count"))==12,"all twelve 32-bar tracker arrangements should be accepted by runtime")
	var title_arrangement:Dictionary=director.get("_arrangements").get("title_vector",{})
	_expect(title_arrangement.get("bars",[]).size()==32,"title cue should retain its full authored arrangement")
	var intro_voice:Dictionary=director.call("_arranged_voice",0);var break_voice:Dictionary=director.call("_arranged_voice",16*16)
	_expect(intro_voice!=break_voice,"runtime should advance beyond one repeated 16-step sketch into authored arrangement sections")
	var energy:=0.0
	for i in range(4096):energy+=absf(float(director.call("_sample_for_clock",i)))
	_expect(energy>80.0 and energy<2400.0,"authored tracker cue should render bounded non-silent PCM")
	director.call("_reset_mastering");var dc_tail:=0.0
	for i in range(12000):dc_tail=float(director.call("_high_pass",1.0))
	_expect(absf(dc_tail)<0.001,"live tracker mastering should reject DC with the reviewed 20 Hz high-pass")
	director.call("_reset_mastering");var alternating_in:=0.0;var alternating_out:=0.0
	for i in range(4096):
		alternating_in=1.0 if i%2==0 else -1.0;alternating_out=float(director.call("_title_soften",alternating_in))
	_expect(absf(alternating_out)<0.76,"title mastering should retain the approved high-frequency shelf reduction")
	director.free()
	var source:=_source("res://scripts/retro_music_director.gd")
	_expect(source.contains("const MIX_RATE:=22050.0") and source.contains("AudioStreamGenerator.new()"),"music runtime should use one bounded 22.05 kHz procedural stream")
	_expect(source.contains("HIGH_PASS_ALPHA") and source.contains("sample=_high_pass(sample)"),"runtime output should use the same light DC cleanup as the screened arrangements")
	_expect(source.contains("TITLE_SHELF") and source.contains('_track_id=="title_vector"'),"runtime title cue should retain its approved softened master")
	_expect(source.contains("_select_live_track") and source.contains("set_mix_levels"),"music runtime should transition by phase and obey its real mixer")
	_expect(source.contains("data/music_arrangements") and source.contains("_arranged_voice") and source.contains("arrangement_step"),"music runtime should synthesize the authored 32-bar arrangements")
	_expect(source.contains('startup_stage<2:wanted=""') and source.contains('startup_stage==2:wanted="title_vector"'),"approved splash should remain silent while the HYPERSONIC reveal owns its title cue")
	_expect(_source("res://project.godot").contains('RetroMusicDirector="*res://scripts/retro_music_director.gd"'),"music runtime should be a canonical project service")
	if failures.is_empty():print("HYPERSONIC tracker music self-test passed.");quit(0);return
	for failure in failures:push_error(failure)
	quit(1)
func _source(path:String)->String:
	var file:=FileAccess.open(path,FileAccess.READ);return file.get_as_text() if file!=null else ""
func _expect(condition:bool,message:String)->void:
	if not condition:failures.append(message)
