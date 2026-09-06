extends Node
const SceneContractCache=preload("res://scripts/scene_contract_cache.gd")
const ContentCatalog=preload("res://scripts/content_catalog.gd")
const MusicRules=preload("res://scripts/music_rules.gd")
const MIX_RATE:=22050.0
const HIGH_PASS_ALPHA:=0.994332
const TITLE_SHELF:=[0.8524251,0.2077149,0.08342384,0.05752358,0.08604027]
var _player:AudioStreamPlayer
var _playback:AudioStreamGeneratorPlayback
var _tracks:Array=[]
var _arrangements:Dictionary={}
var _track:Dictionary={}
var _track_id:=""
var _sample_clock:=0
var _noise_state:=0x28A91C3D
var _hp_input:=0.0
var _hp_output:=0.0
var _shelf_x1:=0.0
var _shelf_x2:=0.0
var _shelf_y1:=0.0
var _shelf_y2:=0.0
func _ready()->void:
	var data=ContentCatalog.load_json("res://data/music_tracks.json");_tracks=MusicRules.sanitize_tracks(data.get("tracks",[]) if typeof(data)==TYPE_DICTIONARY else [])
	_load_arrangements()
	if DisplayServer.get_name()=="headless":return
	var generator:=AudioStreamGenerator.new();generator.mix_rate=MIX_RATE;generator.buffer_length=0.18
	_player=AudioStreamPlayer.new();_player.stream=generator;add_child(_player);_apply_saved_mix();_player.play();_playback=_player.get_stream_playback() as AudioStreamGeneratorPlayback
func _process(_delta:float)->void:
	_select_live_track();_fill_buffer()
func set_mix_levels(master_percent:int,music_percent:int)->void:
	var mixed:=float(clampi(master_percent,0,100)*clampi(music_percent,0,100))/10000.0
	if _player!=null:_player.volume_db=-80.0 if mixed<=0.0 else linear_to_db(mixed)
func active_track_id()->String:return _track_id
func track_count()->int:return _tracks.size()
func arrangement_count()->int:return _arrangements.size()
func _load_arrangements()->void:
	_arrangements.clear()
	for track_id in MusicRules.TRACK_IDS:
		var arrangement=ContentCatalog.load_json("res://data/music_arrangements/%s.json" % track_id)
		if typeof(arrangement)!=TYPE_DICTIONARY:continue
		var bars=arrangement.get("bars",[])
		if typeof(bars)!=TYPE_ARRAY or bars.size()!=32:continue
		var valid:=true
		for bar in bars:
			if typeof(bar)!=TYPE_DICTIONARY or not MusicRules.valid_tracker_voice(bar.get("track",{})):
				valid=false;break
		if valid:_arrangements[track_id]=arrangement
func _apply_saved_mix()->void:
	var settings:=get_node_or_null("/root/SettingsDirector")
	set_mix_levels(int(settings.call("master_level")) if settings!=null and settings.has_method("master_level") else 80,int(settings.call("music_level")) if settings!=null and settings.has_method("music_level") else 65)
func _select_live_track()->void:
	var scene:=get_tree().current_scene
	var wanted:="hangar_signal"
	var startup:=get_node_or_null("/root/StartupSequenceDirector")
	if startup!=null and _has_property(startup,"stage"):
		var startup_stage:=int(startup.get("stage"))
		if startup_stage<2:wanted=""
		elif startup_stage==2:wanted="title_vector"
	if scene!=null and _has_property(scene,"phase"):
		if startup==null or not _has_property(startup,"stage") or int(startup.get("stage"))>=3:
			wanted=MusicRules.track_id_for(int(scene.get("phase")),int(scene.get("mission_index")) if _has_property(scene,"mission_index") else 0)
	if wanted==_track_id:return
	if wanted.is_empty():_track={};_track_id="";_sample_clock=0;_reset_mastering();return
	for candidate in _tracks:
		if str(candidate.get("id"))==wanted:_track=candidate;_track_id=wanted;_sample_clock=0;_reset_mastering();return
func _fill_buffer()->void:
	if _playback==null or _track.is_empty():return
	var frames:=_playback.get_frames_available()
	for _i in range(frames):
		var sample:=_sample_for_clock(_sample_clock)
		if _track_id=="title_vector":sample=_title_soften(sample)
		sample=_high_pass(sample);_sample_clock+=1;_playback.push_frame(Vector2(sample,sample))
func _reset_mastering()->void:
	_hp_input=0.0;_hp_output=0.0;_shelf_x1=0.0;_shelf_x2=0.0;_shelf_y1=0.0;_shelf_y2=0.0
func _title_soften(sample:float)->float:
	var output:float=TITLE_SHELF[0]*sample+TITLE_SHELF[1]*_shelf_x1+TITLE_SHELF[2]*_shelf_x2-TITLE_SHELF[3]*_shelf_y1-TITLE_SHELF[4]*_shelf_y2
	_shelf_x2=_shelf_x1;_shelf_x1=sample;_shelf_y2=_shelf_y1;_shelf_y1=output
	return output
func _high_pass(sample:float)->float:
	var output:=HIGH_PASS_ALPHA*(_hp_output+sample-_hp_input)
	_hp_input=sample;_hp_output=output
	return output
func _sample_for_clock(clock:int)->float:
	var seconds:=float(clock)/MIX_RATE;var step_seconds:=60.0/float(_track.get("bpm",120))/4.0;var step_float:=seconds/step_seconds;var arrangement_step:=posmod(int(floor(step_float)),512);var step:=arrangement_step%16;var local:=fposmod(step_float,1.0)
	var voice:=_arranged_voice(arrangement_step)
	var lead_note:=int(voice.get("lead",[])[step]);var bass_note:=int(voice.get("bass",[])[step]);var chord_note:=int(voice.get("root",40))+int(voice.get("chords",[])[step%4])+12
	var lead_env:=minf(1.0,local*18.0)*pow(1.0-local,1.6);var bass_env:=minf(1.0,local*12.0)*(1.0-local*0.72);var arp_gate:=1.0 if fposmod(local*4.0,1.0)<0.46 else 0.0
	var lead:=_pulse(MusicRules.midi_frequency(lead_note),seconds,0.32)*lead_env if lead_note>=0 else 0.0
	var bass:=_saw(MusicRules.midi_frequency(bass_note),seconds)*bass_env if bass_note>=0 else 0.0
	var arp:=sin(seconds*MusicRules.midi_frequency(chord_note)*TAU)*arp_gate*(1.0-local)*0.12
	var kick:=sin(seconds*92.0*TAU/(1.0+local*5.0))*exp(-local*14.0)*0.44 if int(voice.get("kick",[])[step])>0 else 0.0
	var snare:=_noise()*exp(-local*11.0)*0.24 if int(voice.get("snare",[])[step])>0 else 0.0
	return clampf(lead*0.20+bass*0.22+arp+kick+snare,-0.72,0.72)
func _arranged_voice(arrangement_step:int)->Dictionary:
	var arrangement=_arrangements.get(_track_id,{})
	var bars=arrangement.get("bars",[]) if typeof(arrangement)==TYPE_DICTIONARY else []
	if typeof(bars)==TYPE_ARRAY and bars.size()==32:
		var bar=bars[clampi(int(arrangement_step/16),0,31)]
		if typeof(bar)==TYPE_DICTIONARY:
			var voice=bar.get("track",{})
			if MusicRules.valid_tracker_voice(voice):return voice
	return _track
func _pulse(frequency:float,time:float,duty:float)->float:return 1.0 if fposmod(time*frequency,1.0)<duty else -1.0
func _saw(frequency:float,time:float)->float:return fposmod(time*frequency,1.0)*2.0-1.0
func _noise()->float:
	_noise_state=int((1103515245*_noise_state+12345)&0x7fffffff);return float(_noise_state)/1073741823.5-1.0
func _has_property(object:Object,name:String)->bool:
	return SceneContractCache.has_property(object,name)
