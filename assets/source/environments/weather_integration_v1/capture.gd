extends SceneTree
var stage := -1
func _initialize() -> void: call_deferred("run")
func _process(_delta: float) -> bool:
	if stage >= 0:
		Input.action_press("fire_primary")
		Input.action_press("move_down" if stage < 24 else "move_up")
		if stage >= 36 and stage < 54: Input.action_press("afterburner")
	return false
func run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	await create_timer(0.4).timeout
	root.get_node("StartupSequenceDirector").call("_complete")
	var craft := root.get_node("CraftFormDirector")
	var weather := root.get_node("EnvironmentDirector/WeatherRenderer")
	var settings := root.get_node("SettingsDirector")
	for entry in [{"index":1,"id":"drizzle"},{"index":2,"id":"rain"},{"index":5,"id":"storm"},{"index":8,"id":"snow"}]:
		stage = -1
		for action in ["fire_primary","move_up","move_down","afterburner"]: Input.action_release(action)
		scene.set("phase",0); scene.set("mission_index",int(entry.index)); scene.call("_prepare_mission",int(entry.index)); scene.call("_start_mission")
		craft.set("_last_phase",0)
		await process_frame
		await process_frame
		craft.set("altitude","low"); craft.set("_altitude_transition_timer",0.0)
		craft.set("_throttle_ratio",0.0); craft.set("_world_speed_multiplier_value",0.62)
		settings.set("_reduced_flashes",false)
		var output := "res://work/weather_integration_v1/native_v2_%s/" % entry.id
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
		var rows: Array = []
		for i in 84:
			stage = i
			if i == 24: Input.action_release("move_down")
			if i == 54:
				Input.action_release("afterburner")
				settings.set("_reduced_flashes",true)
			if i == 66: craft.call("_begin_altitude_transition",scene,"high","WEATHER REVIEW CLIMB")
			await create_timer(1.0/12.0).timeout
			await RenderingServer.frame_post_draw
			if int(scene.get("phase")) != 1:
				push_error("Capture left gameplay"); quit(1); return
			if str(weather.get("_profile")) != str(entry.id):
				push_error("Weather mapping mismatch: " + str(weather.get("_profile"))); quit(1); return
			var image := root.get_texture().get_image()
			if image.get_size() != Vector2i(640,360): image.resize(640,360,Image.INTERPOLATE_NEAREST)
			image.save_png(output + "frame_%03d.png" % i)
			rows.append({"time":scene.get("mission_time"),"travel":scene.call("camera_route_distance"),"speed":scene.call("_environment_speed_multiplier"),"profile":weather.get("_profile"),"weight":weather.get("_weight"),"reduced":weather.get("_reduced")})
		var file := FileAccess.open(output + "manifest.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"scope":"Native integrated weather: staged speed, reduced flashes, low-to-high altitude fade. Invulnerable; not survival evidence.","frames":rows},"\t")); file.close()
		print("NATIVE_WEATHER_PASS ",entry.id," 84 frames")
	stage = -1
	for action in ["fire_primary","move_up","move_down","afterburner"]: Input.action_release(action)
	settings.set("_reduced_flashes",false)
	quit()
