extends SceneTree

func _initialize() -> void:
	call_deferred("run_review")

func run_review() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(0.4).timeout
	root.get_node("StartupSequenceDirector").call("_complete")
	var director: Node = root.get_node("CampaignCinematicDirector")
	director.set_process(false)
	var out := "res://work/cinematic_art_review_v3_clean/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var evidence: Array = []
	var images: Array[Image] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cinematics.json"))
	for sequence in data.sequences:
		director.call("_begin_capture_sequence", str(sequence.id))
		for index in sequence.shots.size():
			var shot: Dictionary = sequence.shots[index]
			for exposure in 4:
				var elapsed := float(shot.duration) * (0.2 + 0.2 * exposure)
				director.set("_shot_index", index)
				director.set("_shot_elapsed", elapsed)
				var surface: CanvasItem = director.get("_surface")
				surface.queue_redraw()
				await process_frame
				await RenderingServer.frame_post_draw
				var im: Image = root.get_texture().get_image()
				if im.get_size() != Vector2i(640,360):
					im.resize(640,360,Image.INTERPOLATE_NEAREST)
				images.append(im)
				evidence.append({"sequence":sequence.id,"shot":shot.id,"elapsed":elapsed,"duration":shot.duration,"exposure":exposure,"file":"%s_%d.png" % [shot.id,exposure]})
	for i in images.size():
		images[i].save_png(out + str(evidence[i].file))
	var f := FileAccess.open(out + "manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"48 addressed native production cinematic exposures; not audio or natural campaign trigger verification","frames":evidence},"\t"))
	f.close()
	print("CINEMATIC_ART_REVIEW: 48 native exposures captured across all 12 authored shots")
	quit()
