extends SceneTree
const BASE:="res://work/tracker_arrangements_v3/"
func _initialize()->void:call_deferred("render_all")
func render_all()->void:
	var index=JSON.parse_string(FileAccess.get_file_as_string(BASE+"index.json"))
	for file in index.plans:
		var plan=JSON.parse_string(FileAccess.get_file_as_string(BASE+file));var director=load("res://scripts/retro_music_director.gd").new()
		var samples_per_bar:float=22050.0*240.0/float(plan.bpm);var count:=int(round(samples_per_bar*plan.bars.size()));var pcm:=PackedByteArray();pcm.resize(count*2);var last_bar:=-1
		for i in count:
			var bar:=mini(int(floor(i/samples_per_bar)),plan.bars.size()-1)
			if bar!=last_bar:director.set("_track",plan.bars[bar].track);last_bar=bar
			var sample:float=director.call("_sample_for_clock",i);pcm.encode_s16(i*2,int(round(sample*32767)))
		var wav:=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.mix_rate=22050;wav.data=pcm
		if wav.save_to_wav(BASE+plan.id+"_raw.wav")!=OK:director.free();quit(1);return
		director.free();print("TRACKER_ARRANGED "+plan.id+" %.3f sec"%(float(count)/22050.0))
	quit()
