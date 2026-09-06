extends SceneTree
func _initialize() -> void:
	call_deferred("render_arrangement")
func render_arrangement() -> void:
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://work/audio_review_v2/steel_vector_arrangement.json"))
	var director=load("res://scripts/retro_music_director.gd").new()
	var samples_per_bar:=22050.0*240.0/float(plan["bpm"])
	var count:=int(round(samples_per_bar*plan["bars"].size()))
	var pcm:=PackedByteArray()
	pcm.resize(count*2)
	var last_bar:=-1
	for i in count:
		var bar:=mini(int(floor(i/samples_per_bar)),plan["bars"].size()-1)
		if bar!=last_bar:
			director.set("_track",plan["bars"][bar]["track"])
			last_bar=bar
		var sample:float=director.call("_sample_for_clock",i)
		pcm.encode_s16(i*2,int(round(sample*32767)))
	var wav:=AudioStreamWAV.new()
	wav.format=AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate=22050
	wav.data=pcm
	assert(wav.save_to_wav("res://work/audio_review_v2/steel_vector_arrangement_raw.wav")==OK)
	print("Rendered 32-bar original-motif arrangement, %.3f seconds." % (float(count)/22050.0))
	director.free()
	quit()
