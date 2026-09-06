extends SceneTree
const Rules=preload("res://scripts/retro_sfx_rules.gd")
const Director=preload("res://scripts/retro_sfx_director.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
	var synth:=Director.new()
	var out:="res://work/sfx_review_v3/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var rows:Array=[]
	var script:Script=load("res://scripts/retro_sfx_rules.gd")
	var constants:=script.get_script_constant_map()
	for key in constants:
		if typeof(constants[key])!=TYPE_STRING:continue
		var id:=str(constants[key]);var spec:=Rules.voice(id)
		if not Rules.valid_voice(spec):continue
		var radio:=id in [Rules.MISSILE_WARNING,Rules.ALTITUDE_SHIFT,Rules.ALTITUDE_CLIMB,Rules.ALTITUDE_DIVE,Rules.RADIO_TX,Rules.RADIO_ALERT]
		var duration:=float(spec.duration);var rate:=22050
		var count:=int(ceil((duration+.1)*rate));var pcm:=PackedByteArray();pcm.resize(count*2)
		var phase:=0.0;synth.set("_noise_state",0x1345ABCD)
		for i in count:
			var elapsed:=float(i)/rate;var sample:=0.0
			# Runtime consumes one noise value for propulsion before each voice.
			synth.call("_noise_sample")
			if elapsed<duration:
				var t:=elapsed/duration
				phase=fposmod(phase+lerpf(float(spec.frequency),float(spec.end_frequency),t)/rate,1.0)
				sample=float(synth.call("_wave_sample",str(spec.wave),phase,t))*float(spec.gain)*(.8 if radio else .75)*pow(1.0-t,2)
			pcm.encode_s16(i*2,int(round(clampf(sample,-.85,.85)*32767)))
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=rate;wav.stereo=false;wav.data=pcm
		var result:=wav.save_to_wav(out+id+".wav");assert(result==OK)
		rows.append({"id":id,"spec":spec,"mix_gain":.8 if radio else .75,"filename":id+".wav"})
	var file:=FileAccess.open(out+"manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify({"scope":"Isolated runtime SFX voices at configured 75% SFX/80% radio gain, before master gain; no propulsion bed, polyphony or music.","events":rows},"\t"));file.close()
	synth.free();print("SFX_REVIEW_RENDERED ",rows.size()," runtime event voices");quit()
