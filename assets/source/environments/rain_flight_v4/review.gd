extends SceneTree

class RainSurface extends Control:
	var scene:Node
	var frames:Array
	var plan:Dictionary
	var start_time:float
	var start_distance:float
	func drop_state(p:Dictionary,elapsed:float,travel:float)->Dictionary:
		var phase:=fposmod(elapsed/8.0,1.0)
		var perspective:=.38+(1.0-float(p.depth))*1.42
		var margin:=maxf(8.0,float(p.lengthPixels)*1.4)
		var period:=304.0+margin*2.0
		var age:=fposmod(phase*float(p.fallCycles)+float(p.phaseOffset)+travel*42.0*(1.0-float(p.depth))/period,1.0)
		var gust:=sin(TAU*(phase*float(p.gustCycles)+float(p.gustPhase)))+.38*sin(TAU*(phase*(float(p.gustCycles)+1.0)+float(p.secondaryGustPhase)))
		var drift:=.14*age*(.035+perspective*.035)
		var x:=fposmod(float(p.baseX)+drift+gust*float(p.lateralVariation),1.0)*640.0
		var y:=-margin+age*period
		var length:=float(p.lengthPixels)*(.92+.08*sin(TAU*(phase*2.0+float(p.gustPhase))))
		var slant:=.14*length*(.34+perspective*.16)+gust*length*.035
		var vertical:=length*1.028
		var direction:=Vector2(slant,vertical).normalized()
		var cap:float={"background":2.0,"midground":4.0,"foreground":8.0}[p.depthBand]
		var drawn_length:=minf(Vector2(slant,vertical).length(),cap)
		var fade:=minf(clampf((y+margin)/margin,0,1),clampf((304.0+margin-(y-direction.y*drawn_length))/margin,0,1))
		return {"head":Vector2(x,y),"tail":Vector2(x,y)-direction*drawn_length,"opacity":float(p.opacity)*fade*.78}
	func _process(_delta:float)->void: queue_redraw()
	func _draw()->void:
		var elapsed:=float(scene.get("mission_time"))-start_time
		var travel:=float(scene.get("environment_world_distance"))-start_distance
		for p in plan.particles:
			var state:=drop_state(p,elapsed,travel)
			var a:Vector2=state.tail
			var b:Vector2=state.head
			var middle:=a.lerp(b,.5)
			var opacity:float=state.opacity
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
	var weather:="storm" if "--rain-style=storm" in OS.get_cmdline_user_args() else "rain"
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://work/rain_flight_v4/%s_states.json"%weather));rain.frames=data.frames
	rain.plan=JSON.parse_string(FileAccess.get_file_as_string("res://work/rain_flight_v4/%s_plan.json"%weather))
	var maximum_head_error:=0.0
	for sample_index in rain.frames.size():
		for particle_index in rain.plan.particles.size():
			var p:Dictionary=rain.plan.particles[particle_index]
			var reference:Dictionary=rain.frames[sample_index][particle_index]
			var actual:Dictionary=rain.drop_state(p,float(sample_index)/24.0,0.0)
			maximum_head_error=maxf(maximum_head_error,actual.head.distance_to(Vector2(reference.x1,reference.y1)))
	print("RAIN_ADAPTER_PARITY: ",rain.frames.size()*rain.plan.particles.size()," head samples; max error ",maximum_head_error)
	if maximum_head_error>=.0001:
		push_error("Godot art adapter does not match verified Atmosphere drop heads")
		quit(1)
		return
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
	var out:="res://work/rain_flight_v4/native_storm/" if weather=="storm" else "res://work/rain_flight_v4/native_phase/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for i in images.size():images[i].save_png(out+"frame_%03d.png"%i)
	var f:=FileAccess.open(out+"manifest.json",FileAccess.WRITE);f.store_string(JSON.stringify({"scope":"Rain art fixture over running refinery combat; verified Atmosphere time cycle plus depth-dependent actual travel. No production weather/flight change.","frames":evidence},"\t"));f.close()
	print("RAIN_FLIGHT_V4: 120 native frames captured")
	quit()
