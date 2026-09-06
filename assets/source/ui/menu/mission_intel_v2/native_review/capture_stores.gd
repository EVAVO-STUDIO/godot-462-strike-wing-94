extends SceneTree
func _initialize()->void:call_deferred("review")
func review()->void:
	var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
	await process_frame;await process_frame
	var intel=root.get_node("LoadoutSchematicDirector");intel.set("_open",true)
	await create_timer(.25).timeout;await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image();if image.get_size()!=Vector2i(640,360):image.resize(640,360,Image.INTERPOLATE_NEAREST)
	var out:=""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--intel-output="):out=a.trim_prefix("--intel-output=")
	assert(not out.is_empty());image.save_png(out);print("MISSION_INTEL_NATIVE "+out);quit()
