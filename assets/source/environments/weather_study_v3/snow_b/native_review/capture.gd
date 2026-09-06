extends SceneTree

class SnowSurface extends Control:
	var textures: Array[Texture2D] = []
	var scene: Node
	var start_time: float
	func _process(_delta: float) -> void: queue_redraw()
	func _draw() -> void:
		var elapsed := float(scene.get("mission_time")) - start_time
		var frame := int(floor(elapsed * 12.0)) % textures.size()
		draw_texture(textures[frame], Vector2.ZERO)

func _initialize() -> void: call_deferred("run_review")
func run_review() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(.5).timeout
	var layer := CanvasLayer.new()
	layer.layer = 18
	root.add_child(layer)
	var snow := SnowSurface.new()
	snow.position = Vector2(0,34)
	snow.size = Vector2(640,304)
	snow.clip_contents = true
	snow.scene = scene
	snow.start_time = float(scene.get("mission_time"))
	for i in 48:
		var file := "res://work/weather_art_v3/snow_b/render/frame-%04d.png" % i
		snow.textures.append(ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(file))))
	layer.add_child(snow)
	var frames: Array[Image] = []
	var evidence: Array = []
	for i in 120:
		if i == 0:
			Input.action_press("throttle_down")
			Input.action_press("fire_primary")
		if i == 24:
			Input.action_release("throttle_down")
			Input.action_press("throttle_up")
		if i == 72: Input.action_release("throttle_up")
		if i == 90: Input.action_press("throttle_down")
		await create_timer(1.0/12.0).timeout
		await RenderingServer.frame_post_draw
		var im := root.get_texture().get_image()
		if im.get_size() != Vector2i(640,360): im.resize(640,360,Image.INTERPOLATE_NEAREST)
		frames.append(im)
		evidence.append({"frame":i,"mission_time":scene.get("mission_time"),"world_distance":scene.get("environment_world_distance"),"speed_multiplier":scene.call("_environment_speed_multiplier")})
	for action in ["throttle_up","throttle_down","fire_primary"]: Input.action_release(action)
	var out := "res://work/snow_native_review/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in frames.size(): frames[i].save_png(out + "frame_%03d.png" % i)
	var f := FileAccess.open(out + "manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"scope":"Snow B art over running mountain gameplay. Snow playback is time based; terrain uses actual travel. No production weather or flight change.","frames":evidence},"\t"))
	f.close()
	print("SNOW_NATIVE_REVIEW: 120 frames captured")
	quit()
