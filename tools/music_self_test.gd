extends SceneTree
const ContentCatalog=preload("res://scripts/content_catalog.gd")
const MusicRules=preload("res://scripts/music_rules.gd")
var failures:Array[String]=[]
func _initialize()->void:
	var data=ContentCatalog.load_json("res://data/music_tracks.json");var tracks:=MusicRules.sanitize_tracks(data.get("tracks",[]))
	_expect(tracks.size()==6,"six authored HYPERSONIC cues should validate")
	_expect(str(tracks[0].get("id"))=="hangar_signal" and str(tracks[1].get("id"))=="title_vector" and str(tracks[5].get("id"))=="after_action","music cue order should remain canonical")
	_expect(MusicRules.track_id_for(1,0)=="steel_vector" and MusicRules.track_id_for(1,10)=="machine_pressure" and MusicRules.track_id_for(1,20)=="black_sky","campaign sectors should own distinct music identities")
	_expect(MusicRules.track_id_for(0,12)=="hangar_signal" and MusicRules.track_id_for(2,12)=="after_action","front end and debrief should own separate cues")
	_expect(absf(MusicRules.midi_frequency(69)-440.0)<0.001,"tracker pitch conversion should retain concert reference")
	var director:Node=load("res://scripts/retro_music_director.gd").new();director.set("_tracks",tracks);director.set("_track",tracks[1])
	var energy:=0.0
	for i in range(4096):energy+=absf(float(director.call("_sample_for_clock",i)))
	_expect(energy>80.0 and energy<2400.0,"authored tracker cue should render bounded non-silent PCM")
	director.free()
	var source:=_source("res://scripts/retro_music_director.gd")
	_expect(source.contains("const MIX_RATE:=22050.0") and source.contains("AudioStreamGenerator.new()"),"music runtime should use one bounded 22.05 kHz procedural stream")
	_expect(source.contains("_select_live_track") and source.contains("set_mix_levels"),"music runtime should transition by phase and obey its real mixer")
	_expect(source.contains('startup_stage<2:wanted=""') and source.contains('startup_stage==2:wanted="title_vector"'),"approved splash should remain silent while the HYPERSONIC reveal owns its title cue")
	_expect(_source("res://project.godot").contains('RetroMusicDirector="*res://scripts/retro_music_director.gd"'),"music runtime should be a canonical project service")
	if failures.is_empty():print("HYPERSONIC tracker music self-test passed.");quit(0);return
	for failure in failures:push_error(failure)
	quit(1)
func _source(path:String)->String:
	var file:=FileAccess.open(path,FileAccess.READ);return file.get_as_text() if file!=null else ""
func _expect(condition:bool,message:String)->void:
	if not condition:failures.append(message)
