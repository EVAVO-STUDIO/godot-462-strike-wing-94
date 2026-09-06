extends SceneTree

class SnowSurface extends Control:
	var scene:Node
	var frames:Array
	var start_time:float
	var start_distance:float
	var bands:Array
	func _process(_delta:float)->void:queue_redraw()
	func _draw()->void:
		var elapsed:=float(scene.get("mission_time"))-start_time
		var travel:=float(scene.get("environment_world_distance"))-start_distance
		var sample:Array=frames[posmod(int(floor(elapsed*24.0)),frames.size())]
		for band in bands:
			for p in sample:
				if p.layer!=band:continue
				var scale:float={"distant":6.0,"middle":20.0,"near":52.0}[band]
				var x:=fposmod(float(p.x)+8.0,656.0)-8.0
				var y:=fposmod(float(p.y)+travel*scale+8.0,320.0)-8.0
				var c:Dictionary=p.color
				draw_circle(Vector2(x,y).round(),maxf(.5,float(p.size)*.5),Color(float(c.r)/255.0,float(c.g)/255.0,float(c.b)/255.0,float(p.alpha)),true,-1,false)

func _initialize()->void:call_deferred("review")
func review()->void:
	var scene:Node=load("res://scenes/main.tscn").instantiate();root.add_child(scene);current_scene=scene
	await create_timer(.5).timeout
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://work/snow_flight_v4/states.json"))
	var start_time:=float(scene.get("mission_time"));var start_distance:=float(scene.get("environment_world_distance"))
	for entry in [{"layer":8,"bands":["distant","middle"]},{"layer":18,"bands":["near"]}]:
		var canvas:=CanvasLayer.new();canvas.layer=int(entry.layer);root.add_child(canvas)
		var snow:=SnowSurface.new();snow.scene=scene;snow.frames=data.frames;snow.start_time=start_time;snow.start_distance=start_distance;snow.bands=entry.bands
		snow.position=Vector2(0,34);snow.size=Vector2(640,304);snow.clip_contents=true;snow.mouse_filter=Control.MOUSE_FILTER_IGNORE;canvas.add_child(snow)
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
	var out:="res://work/snow_flight_v4/native/";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in images.size():images[i].save_png(out+"frame_%03d.png"%i)
	var f:=FileAccess.open(out+"manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Individual Particle Studio snow states over actual mountain combat with depth-dependent integrated travel. Art fixture, not production weather or flight changes.","frames":evidence},"\t"));f.close()
	print("SNOW_FLIGHT_V4: 120 native frames captured")
	quit()
