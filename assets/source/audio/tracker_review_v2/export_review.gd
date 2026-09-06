extends SceneTree
func _initialize() -> void:
	call_deferred("export_cues")
func export_cues() -> void:
	var director=load("res://scripts/retro_music_director.gd").new()
	var tracks: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/music_tracks.json"))["tracks"]
	var output:="res://work/audio_review_v2/raw_cues/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var records: Array=[]
	for track in tracks:
		director.set("_track",track)
		director.set("_noise_state",0x28A91C3D)
		var samples:=int(ceil(22050.0*60.0/float(track["bpm"])*8.0))
		var pcm:=PackedByteArray()
		pcm.resize(samples*2)
		var ceiling_count:=0
		for i in samples:
			var value: float=director.call("_sample_for_clock",i)
			if absf(value)>=.71999: ceiling_count+=1
			pcm.encode_s16(i*2,int(round(value*32767.0)))
		var wav:=AudioStreamWAV.new()
		wav.format=AudioStreamWAV.FORMAT_16_BITS
		wav.mix_rate=22050
		wav.stereo=false
		wav.data=pcm
		var result:=wav.save_to_wav(output+str(track["id"])+".wav")
		assert(result==OK)
		records.append({"id":track["id"],"bpm":track["bpm"],"samples":samples,"seconds":float(samples)/22050.0,"synth_ceiling_samples":ceiling_count})
		print("Rendered "+str(track["id"]))
	var report:=FileAccess.open("res://work/audio_review_v2/render_manifest.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"scope":"Actual runtime synthesis, two repetitions of the 16-step pattern, before saved mixer gain; mono equals each channel of runtime dual mono. No loop/export/listening approval.","cues":records},"  "))
	director.free()
	quit()
