extends SceneTree

class RainSurface extends Control:
	var scene:Node
	var frames:Array
	var start_time:float
	var start_distance:float
	func _process(_delta:float)->void: queue_redraw()
	func _draw()->void:
		var elapsed:=float(scene.get("mission_time"))-start_time
		var travel:=float(scene.get("environment_world_distance"))-start_distance
		var sample:Array=frames[posmod(int(floor(elapsed*24)),frames.size())]
		for p in sample:
			var delta:=Vector2(float(p.x1)-float(p.x0),float(p.y1)-float(p.y0))
			var cap:float={"background":2.0,"midground":4.0,"foreground":8.0}[p.depthBand]
			var direction:=delta.normalized()
			var length:=minf(delta.length(),cap)
			var y:=fposmod(float(p.y0)+travel*42.0*(1.0-float(p.depth))+10.0,324.0)-10.0
			var a:=Vector2(float(p.x0),y).round()
			var b:=a+direction*length
			var middle:=a.lerp(b,.5)
			var opacity:=float(p.opacity)*.78
			draw_line(a,middle,Color(.56,.65,.70,opacity*.4),1.0,false)
			draw_line(middle,b,Color(.56,.65,.70,opacity),1.0,false)

func _initialize()->void:call_deferred("review")
func review()->void:
	var scene:Node=load("res://scenes/main.tscn").instantiate()
	root.add_child(scene);current_scene=scene
	await create_timer(.5).timeout
	var layer:=CanvasLayer.new();layer.layer=18;root.add_child(layer)
	var rain:=RainSurface.new();rain.scene=scene;rain.position=Vector2(0,34);rain.size=Vector2(640,304);rain.clip_contents=true;rain.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rain.start_time=float(scene.get("mission_time"));rain.start_distance=float(scene.get("environment_world_distance"))
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://work/rain_flight_v4/rain_states.json"));rain.frames=data.frames
	layer.add_child(rain)
	var images:Array[Image]=[];var evidence:Array=[]
	Input.action_press("fire_primary")
	for i in 120:
		if i==0:Input.action_press("throttle_down")
		if i==30:
			Input.action_release("throttle_down");Input.action_press("throttle_up")
		if i==75:
			Input.action_release("throttle_up");Input.action_press("afterburner")
		await create_timer(1.0/12.0).timeout
		await RenderingServer.frame_post_draw
		var im:=root.get_texture().get_image()
		if im.get_size()!=Vector2i(640,360):im.resize(640,360,Image.INTERPOLATE_NEAREST)
		images.append(im)
		evidence.append({"frame":i,"mission_time":scene.get("mission_time"),"world_distance":scene.get("environment_world_distance"),"speed_multiplier":scene.call("_environment_speed_multiplier")})
	for action in ["fire_primary","throttle_up","throttle_down","afterburner"]:Input.action_release(action)
	var out:="res://work/rain_flight_v4/native/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in images.size():images[i].save_png(out+"frame_%03d.png"%i)
	var f:=FileAccess.open(out+"manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Rain art fixture over running refinery combat; verified Atmosphere time cycle plus depth-dependent actual travel. No production weather/flight change.","frames":evidence},"\t"));f.close()
	print("RAIN_FLIGHT_V4: 120 native frames captured")
	quit()
