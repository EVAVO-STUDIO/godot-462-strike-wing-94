extends SceneTree
func _initialize() -> void: call_deferred("review")
func review() -> void:
	for id in ["a","b","c","d"]:
		var cloud:Texture2D=load("res://assets/runtime/environments/clouds/cloud_bank_low_wisp_%s.png" % id)
		assert(cloud.get_size()==Vector2(192,64),"Refined low cloud must be imported")
	var scene:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene=scene
	await create_timer(.5).timeout
	var frames:Array[Image]=[]
	var evidence:Array=[]
	Input.action_press("fire_primary")
	for i in 72:
		if i==0:Input.action_press("throttle_down")
		if i==18:
			Input.action_release("throttle_down")
			Input.action_press("throttle_up")
		if i==48:
			Input.action_release("throttle_up")
			Input.action_press("afterburner")
		await create_timer(1.0/12.0).timeout
		await RenderingServer.frame_post_draw
		var im:=root.get_texture().get_image()
		if im.get_size()!=Vector2i(640,360):im.resize(640,360,Image.INTERPOLATE_NEAREST)
		frames.append(im)
		evidence.append({"frame":i,"mission_time":scene.get("mission_time"),"world_distance":scene.get("environment_world_distance"),"speed_multiplier":scene.call("_environment_speed_multiplier")})
	for action in ["fire_primary","throttle_down","throttle_up","afterburner"]:Input.action_release(action)
	var out:="res://work/low_cloud_companions_v3/native_review/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in frames.size():frames[i].save_png(out+"frame_%03d.png"%i)
	var f:=FileAccess.open(out+"manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"Actual production cloud renderer with refined low-altitude family, firing, throttle and afterburner input","frames":evidence},"\t"))
	f.close()
	print("CLOUD_FAMILY_NATIVE: 72 frames captured")
	quit()
